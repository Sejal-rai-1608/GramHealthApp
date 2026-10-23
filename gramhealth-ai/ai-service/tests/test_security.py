import pytest
from fastapi import HTTPException

from api.security import require_internal_ai_token


def test_internal_token_is_optional_for_local_development(monkeypatch):
    monkeypatch.delenv("GRAM_AI_INTERNAL_TOKEN", raising=False)
    monkeypatch.delenv("NODE_ENV", raising=False)

    assert require_internal_ai_token(None) is None


def test_internal_token_fails_closed_in_production(monkeypatch):
    monkeypatch.delenv("GRAM_AI_INTERNAL_TOKEN", raising=False)
    monkeypatch.setenv("NODE_ENV", "production")

    with pytest.raises(HTTPException) as exc_info:
        require_internal_ai_token(None)

    assert exc_info.value.status_code == 503


def test_internal_token_rejects_wrong_value(monkeypatch):
    monkeypatch.setenv("GRAM_AI_INTERNAL_TOKEN", "expected-token")
    monkeypatch.delenv("NODE_ENV", raising=False)

    with pytest.raises(HTTPException) as exc_info:
        require_internal_ai_token("wrong-token")

    assert exc_info.value.status_code == 401
