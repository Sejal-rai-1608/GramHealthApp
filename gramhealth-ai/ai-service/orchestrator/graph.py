from typing import Literal
from langgraph.graph import StateGraph, START, END
from .state import AgentState
from .nodes import (
    classify_request,
<<<<<<< HEAD
    execute_clinical_agent,
    execute_emergency_agent,
    execute_rag_agent,
=======
    execute_patient_rag,
    execute_medical_rag,
    execute_hybrid_rag,
    execute_structured_lookup,
    execute_clinical_agent,
    execute_emergency_agent,
>>>>>>> f9f5067 (Initial commit)
    execute_unsupported,
    finalize_response
)

<<<<<<< HEAD
def route_request(state: AgentState) -> Literal["clinical_agent", "emergency_agent", "rag_agent", "unsupported"]:
=======
def route_request(state: AgentState) -> str:
>>>>>>> f9f5067 (Initial commit)
    return state["selected_agent"]

builder = StateGraph(AgentState)

# Add nodes
builder.add_node("classify", classify_request)
<<<<<<< HEAD
builder.add_node("clinical_agent", execute_clinical_agent)
builder.add_node("emergency_agent", execute_emergency_agent)
builder.add_node("rag_agent", execute_rag_agent)
=======
builder.add_node("patient_rag", execute_patient_rag)
builder.add_node("medical_rag", execute_medical_rag)
builder.add_node("hybrid_rag", execute_hybrid_rag)
builder.add_node("structured_lookup", execute_structured_lookup)
builder.add_node("clinical_agent", execute_clinical_agent)
builder.add_node("emergency_agent", execute_emergency_agent)
>>>>>>> f9f5067 (Initial commit)
builder.add_node("unsupported", execute_unsupported)
builder.add_node("finalize", finalize_response)

# Add edges
builder.add_edge(START, "classify")

# Conditional routing from classify
builder.add_conditional_edges(
    "classify",
    route_request,
    {
<<<<<<< HEAD
        "clinical_agent": "clinical_agent",
        "emergency_agent": "emergency_agent",
        "rag_agent": "rag_agent",
=======
        "patient_rag": "patient_rag",
        "medical_rag": "medical_rag",
        "hybrid_rag": "hybrid_rag",
        "structured_lookup": "structured_lookup",
        "clinical_agent": "clinical_agent",
        "emergency_agent": "emergency_agent",
>>>>>>> f9f5067 (Initial commit)
        "unsupported": "unsupported"
    }
)

<<<<<<< HEAD
# Connect all agents to finalize
for agent in ["clinical_agent", "emergency_agent", "rag_agent", "unsupported"]:
    builder.add_edge(agent, "finalize")
=======
# Connect evidence gatherers to clinical reasoning
builder.add_edge("patient_rag", "clinical_agent")
builder.add_edge("medical_rag", "clinical_agent")
builder.add_edge("hybrid_rag", "clinical_agent")

# Connect final answer nodes to finalize
builder.add_edge("structured_lookup", "finalize")
builder.add_edge("clinical_agent", "finalize")
builder.add_edge("emergency_agent", "finalize")
builder.add_edge("unsupported", "finalize")
>>>>>>> f9f5067 (Initial commit)

builder.add_edge("finalize", END)

# Compile graph
multi_agent_graph = builder.compile()
