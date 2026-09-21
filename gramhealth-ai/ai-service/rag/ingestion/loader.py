import fitz  # PyMuPDF
import uuid
from typing import List
from pathlib import Path
from langchain_core.documents import Document

def ingest_pdf(
    file_path: str, 
    source_url: str = None, 
    publisher: str = None,
    document_id: str = None,
    publication_date: str = None,
    content_hash: str = None,
    source_type: str = "medical_knowledge"
) -> List[Document]:
    """
    Extracts text from a PDF without unnecessarily rewriting the source.
    Preserves document structure reasonably well.
    """
    path = Path(file_path)
    if not path.exists():
        raise FileNotFoundError(f"File not found: {file_path}")

    doc = fitz.open(file_path)
    text_content = []
    
    for page in doc:
        text_content.append(page.get_text())
        
    full_text = "\n\n".join(text_content)
    
    # Do not fabricate metadata. Unknowns remain None.
    doc_id = document_id or str(uuid.uuid4())
    doc_title = doc.metadata.get("title") if doc.metadata.get("title") else path.stem

    metadata = {
        "document_id": doc_id,
        "title": doc_title,
        "source": path.name,
        "source_url": source_url,
        "publisher": publisher,
        "publication_date": publication_date or doc.metadata.get("creationDate"), # raw for prototype
        "document_type": "pdf",
        "language": None, # unknown
        "content_hash": content_hash,
        "source_type": source_type
    }

    # We return a single Document here; the chunker will split it up.
    return [Document(page_content=full_text, metadata=metadata)]
