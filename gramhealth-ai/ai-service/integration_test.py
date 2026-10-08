import requests
import json
import time

cases = [
    "I have fever and headache. What could this mean?",
    "I am having severe chest pain and difficulty breathing.",
    "According to the medical document, what temperature qualifies as fever in the Revised Jones criteria?",
    "How do I repair a car engine?"
]

URL = "http://127.0.0.1:8000/agent/query"

def run_tests():
    for i, case in enumerate(cases):
        print(f"\n--- Test Case {i+1} ---")
        print(f"QUERY: {case}")
        
        try:
            response = requests.post(URL, json={"query": case}, timeout=30)
            
            if response.status_code == 200:
                data = response.json()
                print(f"INTENT: {data.get('intent')}")
                print(f"AGENT: {data.get('agent')}")
                print(f"ROUTING METHOD: {data.get('routing_method')}")
                print(f"GROUNDING: {data.get('grounded')}")
                print(f"CONFIDENCE: {data.get('confidence')}")
                print(f"URGENCY: {data.get('urgency')}")
                print(f"GRAPH PATH: {data.get('graph_path')}")
                print(f"ANSWER: {data.get('answer')}")
                print(f"SOURCES: {json.dumps(data.get('sources', []), indent=2)}")
            else:
                print(f"FAILED (Status {response.status_code}): {response.text}")
                
        except Exception as e:
            print(f"REQUEST FAILED: {str(e)}")
            
        print("Sleeping 12 seconds to avoid rate limits...")
        time.sleep(12)

if __name__ == "__main__":
    run_tests()
