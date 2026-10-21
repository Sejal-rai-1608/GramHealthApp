import logging
import asyncio
from rag.pipeline import RAGPipeline
from rag.config.settings import settings

logging.basicConfig(level=logging.INFO)

pipeline = RAGPipeline()
query = "According to the document, what temperature qualifies as fever in the Revised Jones criteria?"

print(f"--- DIAGNOSING QUERY: {query} ---")
raw_results = pipeline.vector_store.search_similarity(query, top_k=10)

print("\n--- RAW RESULTS (top 10) ---")
for doc, score in raw_results:
    text_snippet = doc.page_content[:300].replace('\n', ' ')
    print(f"CHUNK: {doc.metadata.get('chunk_id')} | DISTANCE: {score:.4f}")
    print(f"TEXT: {text_snippet}...\n")

filtered_results = pipeline.relevance_filter.filter_and_format(raw_results)
print(f"\n--- FILTERED RESULTS ({len(filtered_results)} retained) ---")
for res in filtered_results:
    print(f"KEPT CHUNK: {res.chunk_id}")

context = pipeline.generator.__module__ # We don't have direct access to ContextBuilder easily unless we import it
from rag.generation.context_builder import ContextBuilder
context = ContextBuilder.build_context(filtered_results)

print("\n--- CONTEXT SENT TO GEMINI ---")
print(context)

print("\n--- GEMINI GENERATION ---")
raw_response = pipeline.generator.generate(query, context)
print("Answer:", raw_response.answer)
print("Grounded:", raw_response.grounded)
print("Sources:", raw_response.referenced_chunk_ids)
