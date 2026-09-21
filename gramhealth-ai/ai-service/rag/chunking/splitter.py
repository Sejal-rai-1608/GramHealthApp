import uuid
from typing import List
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_core.documents import Document

def chunk_documents(documents: List[Document], chunk_size: int = 1000, chunk_overlap: int = 200) -> List[Document]:
    """
    Splits documents into semantic chunks.
    Ensures every chunk preserves document_id and receives a unique chunk_id.
    """
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=chunk_size,
        chunk_overlap=chunk_overlap,
        separators=["\n\n", "\n", ".", " ", ""]
    )
    
    chunks = text_splitter.split_documents(documents)
    
    # Inject unique chunk_id to every chunk
    for chunk in chunks:
        chunk.metadata["chunk_id"] = str(uuid.uuid4())
        
    return chunks
