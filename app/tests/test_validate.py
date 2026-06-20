"""Tests for the /validate endpoint and the resilience behaviour."""

import httpx
import respx

VENDOR_URL = "https://api.riskshield.test/v1/score"

VALID_BODY = {"firstName": "Jane", "lastName": "Doe", "idNumber": "9001011234088"}


def test_health(build_client):
    client = build_client(USE_MOCK="true")
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ok"


def test_validate_mock_mode_is_deterministic(build_client):
    client = build_client(USE_MOCK="true")
    resp = client.post("/validate", json=VALID_BODY)
    assert resp.status_code == 200
    body = resp.json()
    # idNumber ends in "88" -> score 88 -> HIGH
    assert body["riskScore"] == 88
    assert body["riskLevel"] == "HIGH"
    # Correlation ID is echoed back on every response.
    assert "X-Correlation-ID" in resp.headers


def test_validate_rejects_bad_input(build_client):
    client = build_client(USE_MOCK="true")
    resp = client.post("/validate", json={"firstName": "Jane"})  # missing fields
    assert resp.status_code == 422


def test_validate_rejects_non_numeric_id(build_client):
    client = build_client(USE_MOCK="true")
    bad = {**VALID_BODY, "idNumber": "ABC123"}
    resp = client.post("/validate", json=bad)
    assert resp.status_code == 422


@respx.mock
def test_validate_calls_real_vendor(build_client):
    route = respx.post(VENDOR_URL).mock(
        return_value=httpx.Response(200, json={"riskScore": 72, "riskLevel": "MEDIUM"})
    )
    client = build_client(USE_MOCK="false", RISKSHIELD_API_KEY="test-key",
                          RISKSHIELD_API_URL=VENDOR_URL)
    resp = client.post("/validate", json=VALID_BODY)
    assert resp.status_code == 200
    assert resp.json() == {"riskScore": 72, "riskLevel": "MEDIUM"}
    # The vendor must have been called with our auth + correlation headers.
    assert route.called
    sent = route.calls.last.request
    assert sent.headers["x-api-key"] == "test-key"
    assert "X-Correlation-ID" in sent.headers


@respx.mock
def test_validate_retries_on_5xx_then_succeeds(build_client):
    # First call fails with 503, second succeeds -> client should retry.
    route = respx.post(VENDOR_URL).mock(
        side_effect=[
            httpx.Response(503),
            httpx.Response(200, json={"riskScore": 30, "riskLevel": "LOW"}),
        ]
    )
    client = build_client(USE_MOCK="false", RISKSHIELD_API_KEY="k",
                          RISKSHIELD_API_URL=VENDOR_URL, HTTP_MAX_RETRIES="3",
                          HTTP_BACKOFF_SECONDS="0.01")
    resp = client.post("/validate", json=VALID_BODY)
    assert resp.status_code == 200
    assert resp.json()["riskScore"] == 30
    assert route.call_count == 2


@respx.mock
def test_validate_gives_up_after_retries(build_client):
    respx.post(VENDOR_URL).mock(return_value=httpx.Response(503))
    client = build_client(USE_MOCK="false", RISKSHIELD_API_KEY="k",
                          RISKSHIELD_API_URL=VENDOR_URL, HTTP_MAX_RETRIES="3",
                          HTTP_BACKOFF_SECONDS="0.01")
    resp = client.post("/validate", json=VALID_BODY)
    assert resp.status_code == 504
    assert resp.json()["error"] == "risk_provider_error"


@respx.mock
def test_validate_does_not_retry_on_4xx(build_client):
    route = respx.post(VENDOR_URL).mock(return_value=httpx.Response(400))
    client = build_client(USE_MOCK="false", RISKSHIELD_API_KEY="k",
                          RISKSHIELD_API_URL=VENDOR_URL, HTTP_MAX_RETRIES="3",
                          HTTP_BACKOFF_SECONDS="0.01")
    resp = client.post("/validate", json=VALID_BODY)
    assert resp.status_code == 502
    assert route.call_count == 1  # NOT retried
