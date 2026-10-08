import json
from orchestrator.graph import multi_agent_graph

cases = [
    "I have fever and headache. What could this mean?",
    "I am having severe chest pain and difficulty breathing.",
    "According to the medical document, what does the Revised Jones criteria say about fever?",
    "How do I repair a car engine?",
    "What are the common signs of dengue?"
]

def run():
    import time
    results = []
    for case in cases:
        print(f"\n--- Running Case: '{case}' ---")
        try:
            initial_state = {"user_query": case}
            final_state = multi_agent_graph.invoke(initial_state)
            
            res = {
                "query": case,
                "intent": final_state.get("intent"),
                "selected_agent": final_state.get("selected_agent"),
                "response": final_state.get("final_response"),
                "grounded": final_state.get("grounded"),
                "confidence": final_state.get("confidence"),
                "sources": final_state.get("sources"),
                "urgency": final_state.get("urgency"),
                "requires_professional_review": final_state.get("requires_professional_review")
            }
            print(json.dumps(res, indent=2))
            results.append(res)
        except Exception as e:
            print(f"ERROR: {e}")
            results.append({"query": case, "error": str(e)})
        
        # Avoid free tier 429 quota limit
        print("Sleeping 12 seconds to avoid rate limits...")
        time.sleep(12)

    with open("demo_results.json", "w") as f:
        json.dump(results, f, indent=2)

if __name__ == "__main__":
    run()
