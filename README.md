# Vendor Payment Risk Scoring Integration

A secure, production-ready integration platform that validates loan applicants
against the **RiskShield** vendor API and returns a risk score. Built for the
Pollinate Platform Engineering Technical Assessment.

> **New to all this?** Start with the step-by-step guides in [`docs/`](docs/).
> They explain every concept and command from first principles.

---

## What it does

`POST /validate` accepts applicant details, calls the RiskShield risk-scoring API
(securely, with retries and timeouts), and returns the risk score.

```http
POST /validate
{ "firstName": "Jane", "lastName": "Doe", "idNumber": "9001011234088" }

200 OK
{ "riskScore": 72, "riskLevel": "MEDIUM" }
```

---

## Architecture

```mermaid
flowchart TB
    subgraph Client
      C[Loan system / caller]
    end

    subgraph Azure["Azure (provisioned by Terraform)"]
      subgraph RG["Resource Group: rg-finsure-riskscore-ENV"]
        CA["Container App<br/>(FastAPI, HTTPS-only)"]
        ACR["Azure Container Registry<br/>(private image store)"]
        KV["Key Vault<br/>(RiskShield API key)"]
        MI["Managed Identity"]
        LAW["Log Analytics + App Insights"]
      end
    end

    V["RiskShield Vendor API"]

    C -- "HTTPS POST /validate" --> CA
    CA -- "pull image (AcrPull)" --> ACR
    CA -- "read secret (Secrets User)" --> KV
    CA -- "uses" --> MI
    MI -. "AcrPull" .-> ACR
    MI -. "Key Vault Secrets User" .-> KV
    CA -- "logs / metrics / traces" --> LAW
    KV -- "audit logs" --> LAW
    CA -- "HTTPS + API key, retries+timeout" --> V
```

**Flow:** the caller hits the Container App over HTTPS → the app authenticates to
Azure using its **Managed Identity** → reads the RiskShield API key from **Key
Vault** → calls the vendor with resilience (timeout, retry, correlation ID) →
returns the score. Everything is observed via **Log Analytics / App Insights**.

---

## Repository layout

```
.
├── app/                # FastAPI service + tests + Dockerfile
│   ├── app/            #   application code (config, models, client, secrets, logging)
│   ├── tests/          #   pytest suite (8 tests)
│   └── Dockerfile      #   multi-stage, non-root, healthcheck
├── terraform/          # Infrastructure as Code (modular, dev/prod)
│   ├── bootstrap/      #   one-time remote-state storage
│   ├── modules/        #   resource_group, observability, acr, identity, key_vault, container_app
│   └── environments/   #   dev/prod tfvars + backend configs
├── pipelines/          # Azure DevOps CI/CD (build → infra → deploy)
│   └── templates/      #   reusable build/infra/deploy stage templates
└──
```

---

## Tech choices

| Area | Choice | Why |
|------|--------|-----|
| Language | **Python + FastAPI** | Fast to write, auto-validation, built-in API docs |
| Compute | **Azure Container Apps** | Serverless containers, scale-to-zero, managed HTTPS |
| IaC | **Terraform** (modular) | Reusable, reviewable, multi-env |
| Secrets | **Key Vault + Managed Identity** | No passwords anywhere |
| CI/CD | **Azure DevOps** | Required; templated, gated prod |
| Observability | **Log Analytics + App Insights** | Logs, metrics, tracing |

---

## Run locally (quick start)

```powershell
cd app
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt -r requirements-dev.txt

# Run in mock mode (no vendor or secrets needed)
$env:USE_MOCK="true"
uvicorn app.main:app --port 8000
```

Then in another terminal:

```powershell
curl http://127.0.0.1:8000/health
curl -X POST http://127.0.0.1:8000/validate -H "Content-Type: application/json" `
  -d '{"firstName":"Jane","lastName":"Doe","idNumber":"9001011234088"}'
```

Run the tests: `pytest` (from `app/`). Run in Docker: see
[`docs/02-docker.md`](docs/02-docker.md).

---

## Deploy to Azure (quick start)

```powershell
# 1. One-time: create remote-state storage
cd terraform/bootstrap
terraform init
terraform apply -var="subscription_id=<YOUR_SUB_ID>"

# 2. Configure dev env files (fill in subscription + storage account)
cd ..
copy environments\dev.tfvars.example environments\dev.tfvars
copy environments\dev.backend.hcl.example environments\dev.backend.hcl

# 3. Provision dev
terraform init -backend-config=environments/dev.backend.hcl
terraform apply -var-file=environments/dev.tfvars

# 4. See the app URL
terraform output app_url
```

For automated deployment, set up the Azure DevOps pipeline


---

## Security considerations

- **Secrets in Key Vault**, retrieved via **Managed Identity** — none in code,
  image, or Terraform state.
- **HTTPS only**; insecure HTTP rejected at ingress.
- **Least privilege** RBAC (`AcrPull`, `Key Vault Secrets User` only).
- **Non-root, scanned, minimal** container image.
- **Diagnostic logging** to Log Analytics (incl. Key Vault audit).
- **No static credentials** in the pipeline (federated service connection).

---