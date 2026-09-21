import logging
import os
from typing import Dict, Any

from .discovery.who import WHODiscoveryAdapter
from .registry import DocumentRegistry
from .downloader import DocumentDownloader
from rag.pipeline import RAGPipeline
from rag.config.sources import MEDICAL_SOURCES

logger = logging.getLogger(__name__)

class MedicalKnowledgeSyncService:
    def __init__(self, registry_path: str = "medical_registry.db"):
        self.registry = DocumentRegistry(registry_path)
        self.downloader = DocumentDownloader()
        
        # We might have multiple adapters in the future. For now, WHO.
        self.adapters = {
            "WHO": WHODiscoveryAdapter()
        }
        
        # We need the RAG Pipeline for ingestion
        self.pipeline = RAGPipeline()

    def sync(self) -> Dict[str, Any]:
        """
        Orchestrates the discovery and synchronization of medical documents.
        """
        logger.info("Starting Medical Knowledge Base Synchronization")
        
        results = {
            "source": "Multiple",
            "discovered": 0,
            "new": 0,
            "updated": 0,
            "unchanged": 0,
            "failed": 0,
            "chunks_added": 0
        }

        for source in MEDICAL_SOURCES:
            if not source.get("enabled", False):
                continue
                
            source_name = source["name"]
            adapter = self.adapters.get(source_name)
            
            if not adapter:
                logger.warning(f"No adapter found for source {source_name}. Skipping.")
                continue
                
            candidates = adapter.discover()
            results["discovered"] += len(candidates)
            
            for doc_data in candidates:
                try:
                    # 1. Check registry
                    doc_id = doc_data["document_id"]
                    existing_doc = self.registry.get_document(doc_id)
                    
                    # Store initial metadata to registry (upsert so it tracks discovery)
                    self.registry.upsert_document(doc_data)
                    
                    doc_url = doc_data.get("document_url")
                    if not doc_url:
                        logger.warning(f"No document_url for {doc_id}. Skipping download.")
                        results["failed"] += 1
                        continue

                    # 2. Download and Hash
                    temp_path, content_hash = self.downloader.download_and_hash(doc_url)
                    
                    if not temp_path or not content_hash:
                        logger.error(f"Failed to download/hash {doc_id}")
                        self.registry.update_sync_status(doc_id, "failed", "")
                        results["failed"] += 1
                        continue

                    # 3. Change Detection
                    if existing_doc and existing_doc.get("content_hash") == content_hash and existing_doc.get("ingestion_status") == "success":
                        logger.info(f"Document {doc_id} unchanged. Skipping ingestion.")
                        self.registry.update_sync_status(doc_id, "success", content_hash, existing_doc.get("chunk_count", 0))
                        results["unchanged"] += 1
                        if os.path.exists(temp_path):
                            os.remove(temp_path)
                        continue

                    # 4. Ingestion
                    logger.info(f"Ingesting {doc_id} ({'New' if not existing_doc else 'Updated'})")
                    chunk_ids = self.pipeline.ingest(
                        file_path=temp_path,
                        source_url=doc_data.get("source_url"),
                        publisher=doc_data.get("publisher"),
                        document_id=doc_id,
                        publication_date=doc_data.get("publication_date"),
                        content_hash=content_hash,
                        source_type="medical_knowledge"
                    )
                    
                    # 5. Update Registry
                    added_chunks = len(chunk_ids)
                    self.registry.update_sync_status(doc_id, "success", content_hash, added_chunks)
                    
                    if existing_doc:
                        results["updated"] += 1
                    else:
                        results["new"] += 1
                        
                    results["chunks_added"] += added_chunks
                    
                    if os.path.exists(temp_path):
                        os.remove(temp_path)

                except Exception as e:
                    logger.error(f"Error processing candidate {doc_data.get('document_id', 'unknown')}: {e}")
                    results["failed"] += 1

        logger.info(f"Sync complete. Results: {results}")
        return results

    def get_status(self) -> Dict[str, Any]:
        """
        Retrieves current sync status.
        """
        # A basic implementation. We could query SQLite for stats.
        import sqlite3
        stats = {"total_documents": 0, "successful": 0, "failed": 0, "total_chunks": 0}
        
        try:
            with sqlite3.connect(self.registry.db_path) as conn:
                cursor = conn.cursor()
                cursor.execute("SELECT COUNT(*), SUM(chunk_count) FROM documents WHERE ingestion_status='success'")
                row = cursor.fetchone()
                if row:
                    stats["successful"] = row[0] or 0
                    stats["total_chunks"] = row[1] or 0
                    
                cursor.execute("SELECT COUNT(*) FROM documents")
                row = cursor.fetchone()
                if row:
                    stats["total_documents"] = row[0] or 0
                    
                cursor.execute("SELECT COUNT(*) FROM documents WHERE ingestion_status='failed'")
                row = cursor.fetchone()
                if row:
                    stats["failed"] = row[0] or 0
        except Exception as e:
            logger.error(f"Failed to get status: {e}")
            
        return stats
