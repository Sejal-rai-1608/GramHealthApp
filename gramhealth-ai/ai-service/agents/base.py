from pydantic import BaseModel, Field
from typing import Literal

class AgentResponse(BaseModel):
    response: str = Field(description="The textual response provided by the agent.")
    confidence: Literal["low", "medium", "high"] = Field(description="Confidence level of the response.")
    requires_professional_review: bool = Field(description="Whether a doctor needs to review this situation.")
