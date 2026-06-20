# Module: container_app
# The Container App Environment + the Container App that runs our image.

# The "environment" is the secure boundary/runtime that hosts one or more
# container apps and wires them to Log Analytics for logging.
resource "azurerm_container_app_environment" "this" {
  name                       = var.environment_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = var.log_analytics_workspace_id
  tags                       = var.tags
}

resource "azurerm_container_app" "this" {
  name                         = var.name
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  tags                         = var.tags

  # Run as the user-assigned Managed Identity (used for ACR pull + Key Vault).
  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  # Pull images from our private ACR using the Managed Identity (no passwords).
  registry {
    server   = var.acr_login_server
    identity = var.identity_id
  }

  # ── Ingress: HTTPS only ─────────────────────────────────────────
  ingress {
    external_enabled           = var.external_ingress
    target_port                = var.target_port
    transport                  = "auto"
    allow_insecure_connections = false # HTTP is rejected; HTTPS enforced

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = "riskscore"
      image  = var.container_image
      cpu    = var.cpu
      memory = var.memory

      # Inject configuration as environment variables (12-factor).
      dynamic "env" {
        for_each = var.env_vars
        content {
          name  = env.key
          value = env.value
        }
      }

      # Liveness/readiness probes hit our /health endpoint.
      liveness_probe {
        transport               = "HTTP"
        port                    = var.target_port
        path                    = "/health"
        initial_delay           = 5
        interval_seconds        = 30
        failure_count_threshold = 3
      }

      readiness_probe {
        transport               = "HTTP"
        port                    = var.target_port
        path                    = "/health"
        interval_seconds        = 10
        failure_count_threshold = 3
      }
    }
  }

  # The pipeline deploys new image tags out-of-band (az containerapp update).
  # Ignore image changes here so Terraform and the pipeline don't fight.
  lifecycle {
    ignore_changes = [template[0].container[0].image]
  }
}
