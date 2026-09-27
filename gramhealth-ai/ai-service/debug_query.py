import urllib.request
import json
import urllib.error
req = urllib.request.Request(
    'http://localhost:8000/rag/query',
    data=json.dumps({'query': 'What are the common symptoms and clinical signs of fever described in the document?', 'top_k': 5}).encode('utf-8'),
    headers={'Content-Type': 'application/json'}
)
try:
    resp = urllib.request.urlopen(req)
    print(resp.read().decode('utf-8'))
except urllib.error.HTTPError as e:
    print("HTTP Error:", e.code)
    print(e.read().decode('utf-8'))
