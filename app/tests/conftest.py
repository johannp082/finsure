"""Shared pytest fixtures.

`build_client` lets each test spin up the app with specific environment settings
(e.g. mock mode on/off, custom retry counts) and returns a FastAPI TestClient.
"""

import importlib

import pytest
from fastapi.testclient import TestClient


@pytest.fixture
def build_client(monkeypatch):
    created = []

    def _build(**env) -> TestClient:
        # Apply env overrides for this test.
        for key, value in env.items():
            monkeypatch.setenv(key, str(value))

        # Re-import config + main so the lru_cached settings pick up new env vars.
        from app import config

        config.get_settings.cache_clear()
        import app.main as main

        importlib.reload(main)

        client = TestClient(main.app)
        client.__enter__()  # triggers FastAPI lifespan (startup)
        created.append(client)
        return client

    yield _build

    for client in created:
        client.__exit__(None, None, None)
