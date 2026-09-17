"""Contract-tests voor Art. 13/50 — transparantie richting eindgebruiker.

Draai tegen een staging-gateway:
    AI_GATEWAY_URL=https://staging-gw.itlusions.nl pytest tests/
"""

import os

import pytest
import requests

GATEWAY = os.environ.get("AI_GATEWAY_URL")
PAYLOAD = {"prompt": "compliance smoke test", "max_tokens": 8}

pytestmark = pytest.mark.skipif(
    not GATEWAY, reason="AI_GATEWAY_URL niet gezet — contract-test vereist een draaiende gateway"
)


@pytest.fixture(scope="module")
def response():
    return requests.post(f"{GATEWAY}/api/inference", json=PAYLOAD, timeout=30)


def test_ai_disclosure_header(response):
    assert response.headers.get("X-AI-Generated") == "true"


def test_ai_info_url_header(response):
    url = response.headers.get("X-AI-Info-URL", "")
    assert url.startswith("https://"), "Transparantie-URL moet publiek bereikbaar zijn (Art. 50)"


def test_system_id_header(response):
    assert response.headers.get("X-AI-System-Id"), "Respons moet herleidbaar zijn tot een registerentry"


def test_correlation_id_for_audit_trail(response):
    assert response.headers.get("X-AI-Correlation-Id"), "Correlatie-id nodig voor audit trail (Art. 12)"
