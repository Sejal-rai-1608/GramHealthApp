import logging
import requests
from typing import List, Dict, Any
from urllib.parse import urljoin
import datetime

logger = logging.getLogger(__name__)

class WHODiscoveryAdapter:
    """
    Adapter to discover candidate WHO guidelines/clinical recommendations
    via the WHO Publications API.
    """
    
    def __init__(self, base_url: str = "https://www.who.int"):
        self.base_url = base_url
        self.publications_endpoint = "/api/hubs/publications"

    def discover(self) -> List[Dict[str, Any]]:
        """
        Discovers candidate medical documents.
        Returns a list of dictionaries with normalized metadata.
        """
        url = urljoin(self.base_url, self.publications_endpoint)
        candidates = []
        
        try:
            logger.info(f"Discovering WHO publications from {url}")
            # Mocking parameters that we'd ideally use to filter for 'guidelines'
            params = {"type": "guidelines"}
            
            # Using timeout to avoid hanging if the API isn't publicly accessible in this format
            response = requests.get(url, params=params, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                items = data.get("value", []) if isinstance(data, dict) else data
                
                for item in items:
                    # Very basic normalization assuming standard API fields. 
                    # If the actual WHO API differs, this mapping would be adjusted.
                    if self._is_approved_content(item):
                        doc_id = str(item.get("id", item.get("DocumentId", "")))
                        candidates.append({
                            "document_id": f"WHO-{doc_id}",
                            "publisher": "World Health Organization",
                            "title": item.get("title", item.get("Title", "Unknown Title")),
                            "source_url": item.get("url", item.get("Url", "")),
                            # In reality, we'd extract the actual PDF URL from the item.
                            "document_url": self._resolve_pdf_url(item),
                            "publication_date": item.get("publicationDate", item.get("Date", "")),
                        })
            else:
                logger.warning(f"WHO API returned status {response.status_code}. Mocking fallback for prototype.")
                candidates = self._mock_fallback_discovery()

        except requests.exceptions.RequestException as e:
            logger.warning(f"Failed to fetch from WHO API: {e}. Falling back to mock discovery.")
            candidates = self._mock_fallback_discovery()

        return candidates

    def _is_approved_content(self, item: Dict[str, Any]) -> bool:
        """
        Approved-content filtering.
        Initially prioritizes/allows WHO guidelines and clinical guidance.
        """
        title = item.get("title", item.get("Title", "")).lower()
        if "guideline" in title or "clinical" in title or "recommendation" in title:
            return True
        return False
        
    def _resolve_pdf_url(self, item: Dict[str, Any]) -> str:
        """
        Resolves the actual PDF document URL from the publication metadata.
        """
        # A robust implementation would parse the item for the PDF link.
        return item.get("pdf_url", item.get("document_url", ""))

    def _mock_fallback_discovery(self) -> List[Dict[str, Any]]:
        """
        Fallback mock data to ensure the prototype works if the WHO API
        is unreachable or has a different structure than expected.
        """
        return [
            {
                "document_id": "WHO-DENGUE-2009",
                "publisher": "World Health Organization",
                "title": "Dengue guidelines for diagnosis, treatment, prevention and control",
                "source_url": "https://www.who.int/publications/i/item/9789241547871",
                # Hardcoding a reliable PDF for testing the sync behavior
                "document_url": "https://apps.who.int/iris/bitstream/handle/10665/44188/9789241547871_eng.pdf",
                "publication_date": "2009-01-01"
            }
        ]
