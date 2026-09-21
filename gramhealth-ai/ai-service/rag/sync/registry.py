import sqlite3
import os
import logging
from typing import Dict, Any, List, Optional
from datetime import datetime

logger = logging.getLogger(__name__)

class DocumentRegistry:
    def __init__(self, db_path: str = "medical_registry.db"):
        self.db_path = db_path
        self._init_db()

    def _init_db(self):
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS documents (
                    document_id TEXT PRIMARY KEY,
                    publisher TEXT,
                    title TEXT,
                    source_url TEXT,
                    document_url TEXT,
                    publication_date TEXT,
                    last_seen TEXT,
                    last_synced TEXT,
                    content_hash TEXT,
                    ingestion_status TEXT,
                    chunk_count INTEGER,
                    enabled BOOLEAN
                )
            """)
            conn.commit()

    def get_document(self, document_id: str) -> Optional[Dict[str, Any]]:
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM documents WHERE document_id = ?", (document_id,))
            row = cursor.fetchone()
            if row:
                return dict(row)
            return None

    def upsert_document(self, doc_data: Dict[str, Any]):
        now = datetime.utcnow().isoformat()
        last_seen = doc_data.get("last_seen", now)
        
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO documents (
                    document_id, publisher, title, source_url, document_url,
                    publication_date, last_seen, last_synced, content_hash,
                    ingestion_status, chunk_count, enabled
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(document_id) DO UPDATE SET
                    publisher=excluded.publisher,
                    title=excluded.title,
                    source_url=excluded.source_url,
                    document_url=excluded.document_url,
                    publication_date=excluded.publication_date,
                    last_seen=excluded.last_seen,
                    last_synced=excluded.last_synced,
                    content_hash=excluded.content_hash,
                    ingestion_status=excluded.ingestion_status,
                    chunk_count=excluded.chunk_count,
                    enabled=excluded.enabled
            """, (
                doc_data["document_id"],
                doc_data.get("publisher"),
                doc_data.get("title"),
                doc_data.get("source_url"),
                doc_data.get("document_url"),
                doc_data.get("publication_date"),
                last_seen,
                doc_data.get("last_synced"),
                doc_data.get("content_hash"),
                doc_data.get("ingestion_status", "pending"),
                doc_data.get("chunk_count", 0),
                doc_data.get("enabled", True)
            ))
            conn.commit()

    def update_sync_status(self, document_id: str, status: str, content_hash: str, chunk_count: int = 0):
        now = datetime.utcnow().isoformat()
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("""
                UPDATE documents
                SET ingestion_status = ?, last_synced = ?, content_hash = ?, chunk_count = ?
                WHERE document_id = ?
            """, (status, now, content_hash, chunk_count, document_id))
            conn.commit()
