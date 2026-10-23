from typing import List, Dict, Any
from urllib.parse import urlparse

MEDICAL_SOURCES: List[Dict[str, Any]] = [
    {
        "name": "WHO",
        "publisher": "World Health Organization",
        "type": "guidelines",
        "enabled": True
    }
]

# Only public-health or government domains in this allowlist may be surfaced
# as verified medical evidence. Retrieval can still return internal metadata,
# but unapproved URLs are withheld from the clinical response.
APPROVED_MEDICAL_SOURCE_DOMAINS = {
    "who.int",
    "cdc.gov",
    "nhs.uk",
    "nhm.gov.in",
    "mohfw.gov.in",
    "nih.gov",
    "medlineplus.gov",
}


def is_approved_medical_source_url(url: str) -> bool:
    if not url or not url.strip():
        return False

    try:
        parsed = urlparse(url.strip())
    except ValueError:
        return False

    if parsed.scheme.lower() != "https" or not parsed.hostname:
        return False

    hostname = parsed.hostname.lower().rstrip(".")
    return any(
        hostname == domain or hostname.endswith(f".{domain}")
        for domain in APPROVED_MEDICAL_SOURCE_DOMAINS
    )
