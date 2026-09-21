import requests
import hashlib
import tempfile
import os
import logging
from typing import Tuple, Optional

logger = logging.getLogger(__name__)

class DocumentDownloader:
    def __init__(self, max_size_bytes: int = 50 * 1024 * 1024):
        self.max_size_bytes = max_size_bytes

    def download_and_hash(self, url: str) -> Tuple[Optional[str], Optional[str]]:
        """
        Downloads a document to a temp file and computes its SHA-256 hash.
        Returns (temp_file_path, content_hash) or (None, None) if failed.
        """
        if not url.startswith("https://"):
            logger.error(f"URL must be HTTPS: {url}")
            return None, None
            
        try:
            logger.info(f"Downloading: {url}")
            # Add timeout and stream the content
            response = requests.get(url, stream=True, timeout=30)
            response.raise_for_status()

            # Ensure it's likely a PDF (for prototype)
            content_type = response.headers.get('Content-Type', '').lower()
            if 'pdf' not in content_type and 'application/octet-stream' not in content_type:
                logger.warning(f"Unexpected content type {content_type} for URL {url}. Proceeding anyway for prototype, but consider stricter validation.")

            temp_fd, temp_path = tempfile.mkstemp(suffix=".pdf")
            
            sha256 = hashlib.sha256()
            downloaded_size = 0
            
            with os.fdopen(temp_fd, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    if chunk:
                        downloaded_size += len(chunk)
                        if downloaded_size > self.max_size_bytes:
                            logger.error(f"File exceeded max size of {self.max_size_bytes} bytes: {url}")
                            os.remove(temp_path)
                            return None, None
                            
                        f.write(chunk)
                        sha256.update(chunk)
                        
            content_hash = sha256.hexdigest()
            return temp_path, content_hash
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to download {url}: {e}")
            return None, None
        except Exception as e:
            logger.error(f"Unexpected error downloading {url}: {e}")
            return None, None
