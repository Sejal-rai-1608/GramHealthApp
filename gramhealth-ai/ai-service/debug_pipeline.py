import logging
import asyncio
from rag.pipeline import RAGPipeline

logging.basicConfig(level=logging.INFO)

pipeline = RAGPipeline()
response = pipeline.query("What are the common symptoms and clinical signs of fever described in the document?", top_k=5)
print("Query done.")
