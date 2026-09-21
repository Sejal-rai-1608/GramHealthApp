import logging
from rag.pipeline import RAGPipeline

logging.basicConfig(level=logging.INFO)
pipeline = RAGPipeline()

queries = [
    "According to the document, what temperature qualifies as fever in the Revised Jones criteria?",
    "What does the document say about fever in the Revised Jones criteria?",
    "How do I repair a car engine?"
]

for query in queries:
    print(f"\n======================\nQUERY: {query}")
    raw_results = pipeline.vector_store.search_similarity(query, top_k=5)
    for i, (doc, score) in enumerate(raw_results):
        print(f"Rank {i+1}: {doc.metadata.get('chunk_id')} | dist={score:.4f} | {doc.page_content[:50].replace(chr(10), ' ')}")
    
    # Also find chunk 88ce051a explicitly
    all_res = pipeline.vector_store.search_similarity(query, top_k=100)
    for i, (doc, score) in enumerate(all_res):
        if doc.metadata.get('chunk_id') == '88ce051a-c5f8-4af3-9ff1-0955aafc9894':
            print(f">>> Target chunk 88ce051a is at rank {i+1} with dist {score:.4f}")
            break
