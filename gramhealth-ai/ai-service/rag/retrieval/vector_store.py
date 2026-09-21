from typing import List, Tuple
from langchain_core.documents import Document
from langchain_chroma import Chroma
from langchain_core.embeddings import Embeddings

class ChromaVectorStore:
    """
    Vector store manager using Langchain-Chroma integration.
    """
    def __init__(self, db_path: str, embeddings: Embeddings, collection_name: str = "medical_docs"):
        self.db_path = db_path
        self.embeddings = embeddings
        self.vector_store = Chroma(
            collection_name=collection_name,
            embedding_function=self.embeddings,
            persist_directory=self.db_path
        )

    def insert_documents(self, documents: List[Document]) -> List[str]:
        """
        Inserts chunked documents. Returns their chunk_ids.
        We extract the pre-assigned chunk_id from metadata to use as the database ID.
        """
        ids = [doc.metadata["chunk_id"] for doc in documents]
        self.vector_store.add_documents(documents=documents, ids=ids)
        return ids

<<<<<<< HEAD
    def search_similarity(self, query: str, top_k: int = 5) -> List[Tuple[Document, float]]:
=======
    def search_similarity(self, query: str, top_k: int = 5, filters: dict = None) -> List[Tuple[Document, float]]:
>>>>>>> f9f5067 (Initial commit)
        """
        Retrieves relevant documents with their similarity scores.
        Note: lower score in Chroma usually means higher similarity (distance).
        """
<<<<<<< HEAD
        return self.vector_store.similarity_search_with_score(query, k=top_k)
=======
        return self.vector_store.similarity_search_with_score(query, k=top_k, filter=filters)

>>>>>>> f9f5067 (Initial commit)
