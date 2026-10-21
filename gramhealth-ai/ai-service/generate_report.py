import logging
from rag.pipeline import RAGPipeline
import json
from rag.generation.context_builder import ContextBuilder

pipeline = RAGPipeline()

queries = [
    "According to the document, what temperature qualifies as fever in the Revised Jones criteria?",
    "What does the document say about fever in the Revised Jones criteria?",
    "How do I repair a car engine?"
]

report = []

for q in queries:
    raw_results = pipeline.vector_store.search_similarity(q, top_k=30)
    filtered_results = pipeline.relevance_filter.filter_and_format(raw_results)
    
    context = ContextBuilder.build_context(filtered_results)
    raw_response = pipeline.generator.generate(q, context)
    
    report.append({
        "query": q,
        "raw_chunks": [{"id": doc.metadata.get("chunk_id"), "dist": round(score, 4)} for doc, score in raw_results],
        "retained_chunks": [r.chunk_id for r in filtered_results],
        "grounded": raw_response.grounded,
        "answer": raw_response.answer,
        "sources": raw_response.referenced_chunk_ids
    })

with open("final_diagnostic_report.json", "w") as f:
    json.dump(report, f, indent=2)
