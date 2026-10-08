import logging
import asyncio
from rag.pipeline import RAGPipeline

pipeline = RAGPipeline()
query = "According to the document, what temperature qualifies as fever in the Revised Jones criteria?"

# 1. Find the chunk containing 38.5
all_docs = pipeline.vector_store.vector_store.get()
chunk_with_385 = None
for i, doc in enumerate(all_docs['documents']):
    if '38.5' in doc:
        chunk_with_385 = doc
        chunk_id = all_docs['metadatas'][i]['chunk_id']
        break

if not chunk_with_385:
    print("Could not find 38.5 in DB")
else:
    print(f"Found 38.5 in chunk: {chunk_id}")
    # Let's see its distance to the query
    raw_results = pipeline.vector_store.search_similarity(query, top_k=200)
    for i, (doc, score) in enumerate(raw_results):
        if doc.metadata['chunk_id'] == chunk_id:
            print(f"Rank in retrieval: {i+1} with distance {score:.4f}")
            print(f"Text preview: {doc.page_content[:200]}")
            break
