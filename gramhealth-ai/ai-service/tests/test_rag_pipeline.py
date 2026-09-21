import pytest
from httpx import AsyncClient, ASGITransport
<<<<<<< HEAD
from ..api.main import app
=======
from api.main import app
>>>>>>> f9f5067 (Initial commit)

@pytest.mark.asyncio
async def test_health_check():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.get("/health")
    assert response.status_code == 200
<<<<<<< HEAD
    assert response.json() == {"status": "ok", "service": "gramhealth-rag"}
=======
    assert response.json() == {"status": "healthy", "service": "gramhealth-ai"}
>>>>>>> f9f5067 (Initial commit)

@pytest.mark.asyncio
async def test_empty_query():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.post("/rag/query", json={"query": ""})
<<<<<<< HEAD
    assert response.status_code == 400
    assert "Query cannot be empty" in response.json()["detail"]
=======
    assert response.status_code == 422
    assert "Invalid query" in response.json()["message"]
>>>>>>> f9f5067 (Initial commit)

@pytest.mark.asyncio
async def test_unsupported_file_ingest():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        # Pass a .png file which is not supported
        files = {"file": ("test.png", b"fake image content", "image/png")}
        response = await ac.post("/rag/ingest", files=files)
    assert response.status_code == 400
    assert "Unsupported file format" in response.json()["detail"]
