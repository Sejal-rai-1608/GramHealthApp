import pytest
from langchain_core.documents import Document
from rag.embeddings.provider import LocalEmbeddingProvider
from rag.retrieval.vector_store import ChromaVectorStore
import tempfile
import shutil

@pytest.fixture
def local_provider():
    # Use the local model, NO Gemini API access required
    return LocalEmbeddingProvider("sentence-transformers/all-MiniLM-L6-v2")

@pytest.fixture
def temp_chroma(local_provider):
    temp_dir = tempfile.mkdtemp()
    store = ChromaVectorStore(temp_dir, local_provider, collection_name="test_local_collection")
    yield store
    shutil.rmtree(temp_dir, ignore_errors=True)

def test_local_embed_query(local_provider):
    query = "What are the symptoms of dengue?"
    embedding = local_provider.embed_query(query)
    assert embedding is not None
    assert isinstance(embedding, list)
    assert len(embedding) == 384  # MiniLM-L6-v2 dim
    assert isinstance(embedding[0], float)

def test_local_embed_documents_empty(local_provider):
    embeddings = local_provider.embed_documents([])
    assert embeddings == []

def test_local_embed_query_empty(local_provider):
    embedding = local_provider.embed_query("")
    assert embedding == []

def test_local_embed_documents_dengue(local_provider):
    sample_texts = [
        "Dengue fever commonly presents with high fever and headache.",
        "Signs of severe dengue require urgent medical evaluation."
    ]
    embeddings = local_provider.embed_documents(sample_texts)
    
    # Verify embeddings are returned
    assert len(embeddings) == 2
    assert isinstance(embeddings, list)
    
    # Verify dimensions are consistent
    assert len(embeddings[0]) == 384
    assert len(embeddings[1]) == 384
    
    # The fact this test passes without an API key verifies no network request is required to Gemini

def test_vector_insertion_and_retrieval(temp_chroma):
    doc1 = Document(page_content="Dengue fever commonly presents with high fever and headache.", metadata={"chunk_id": "chunk_1"})
    doc2 = Document(page_content="Signs of severe dengue require urgent medical evaluation.", metadata={"chunk_id": "chunk_2"})
    doc3 = Document(page_content="A completely unrelated document about space exploration.", metadata={"chunk_id": "chunk_3"})
    
    # Insert
    temp_chroma.insert_documents([doc1, doc2, doc3])
    
    # Retrieve
    query = "What are the signs of severe dengue?"
    results = temp_chroma.search_similarity(query, top_k=2)
    
    assert len(results) == 2
    
    # Should retrieve the dengue docs, not the space doc
    retrieved_chunk_ids = [doc.metadata["chunk_id"] for doc, score in results]
    assert "chunk_2" in retrieved_chunk_ids
    assert "chunk_1" in retrieved_chunk_ids
    assert "chunk_3" not in retrieved_chunk_ids
