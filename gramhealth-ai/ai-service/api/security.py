import hmac
import os
from typing import Optional

from fastapi import Header, HTTPException, status


def _configured_internal_token() -> Optional[str]:
    token = os.environ.get("GRAM_AI_INTERNAL_TOKEN", "").strip()
    return token or None


def require_internal_ai_token(
    x_gramhealth_ai_token: Optional[str] = Header(default=None),
) -> None:
    """Allow only the Node gateway to call internal AI data/query endpoints.

    Local development and unit tests remain usable without a token. Production
    fails closed so a publicly reachable FastAPI service cannot accept patient
    records or AI queries without the shared secret configured on both services.
    """
    expected = _configured_internal_token()
    is_production = os.environ.get("NODE_ENV", "").strip().lower() == "production"

    if expected is None:
        if is_production:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="AI service internal authentication is not configured.",
            )
        return

    if not x_gramhealth_ai_token or not hmac.compare_digest(
        x_gramhealth_ai_token,
        expected,
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="AI service internal authentication failed.",
        )
