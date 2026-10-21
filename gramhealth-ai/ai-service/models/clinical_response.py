from enum import Enum
from typing import List, Optional
from pydantic import BaseModel, Field

class RiskLevelEnum(str, Enum):
    emergency = "emergency"
    high = "high"
    moderate = "moderate"
    low = "low"
    insufficientInformation = "insufficientInformation"

class AssessmentSchema(BaseModel):
    summary: str = Field(
        description="What the system can reasonably say from the provided information."
    )
    evidence_basis: str = Field(
        description="What evidence was actually retrieved or used."
    )
    uncertainty: str = Field(
        description="What cannot be determined from available information (e.g. without physical exam or lab evidence)."
    )

class PossibleConditionSchema(BaseModel):
    name: str = Field(
        description="Non-diagnostic name of the possible condition being considered."
    )
    reason: str = Field(
        description="Why this condition is considered based on the reported symptoms and timing."
    )
    evidence_status: str = Field(
        description="Evidence status (e.g., 'Possible consideration; current information is insufficient to confirm.')."
    )

class EvidenceItemSchema(BaseModel):
    title: str = Field(
        description="Title or descriptive name of the retrieved evidence."
    )
    source_type: str = Field(
        description="Source category: 'Medical RAG', 'Patient RAG', 'Hybrid', 'Offline Medical Lexicon', 'Deterministic Safety Rule', or 'None'."
    )
    source: str = Field(
        description="Authoritative source or publisher e.g. 'WHO', 'Ministry of Health', 'Patient Health Record'."
    )
    citation: str = Field(
        default="",
        description="Citation identifier, chunk ID, or guideline URL. Never fabricate citations."
    )
    relevance: str = Field(
        description="How this evidence item directly supports the assessment, symptoms, or warning signs."
    )

class ClinicalResponseSchema(BaseModel):
    symptom_summary: str = Field(
        description="Clear reflection of user-reported symptoms."
    )
    assessment: AssessmentSchema = Field(
        description="Clinical assessment distinguishing facts, evidence, and uncertainty."
    )
    possible_conditions: List[PossibleConditionSchema] = Field(
        default_factory=list,
        description="0 to 3 possible non-diagnostic considerations. Maximum 3."
    )
    risk_level: RiskLevelEnum = Field(
        default=RiskLevelEnum.insufficientInformation,
        description="Assessed risk level: emergency, high, moderate, low, or insufficientInformation."
    )
    what_you_can_do_now: List[str] = Field(
        default_factory=list,
        description="2 to 5 practical, safe actions the user can take now."
    )
    warning_signs: List[str] = Field(
        default_factory=list,
        description="Concrete red flags relevant to the symptoms."
    )
    when_to_see_doctor: str = Field(
        description="Tiered recommendation reflecting the assessed risk level."
    )
    evidence: List[EvidenceItemSchema] = Field(
        default_factory=list,
        description="List of verified evidence items used."
    )
    medical_disclaimer: str = Field(
        default="This information is for general health guidance and is not a medical diagnosis. Please consult a qualified healthcare professional for personal medical advice.",
        description="Standard medical disclaimer."
    )
    source_mode: str = Field(
        default="Medical RAG",
        description="Source mode e.g. 'Medical RAG', 'Patient RAG', 'Hybrid', 'Offline Medical Lexicon', 'Deterministic Safety Rule', 'None'."
    )
    requires_professional_review: bool = Field(
        default=True,
        description="Whether professional medical review is recommended."
    )
    emergency: bool = Field(
        default=False,
        description="Whether deterministic emergency criteria was triggered."
    )

def format_clinical_answer(resp: ClinicalResponseSchema) -> str:
    """Format structured clinical response into readable text for backwards compatibility."""
    lines = []
    if resp.emergency:
        lines.append("🚨 EMERGENCY\nThese symptoms may require urgent medical attention.\n")
    
    lines.append(f"SYMPTOM SUMMARY:\n{resp.symptom_summary}\n")
    lines.append(
        f"ASSESSMENT:\n{resp.assessment.summary}\n"
        f"Evidence basis: {resp.assessment.evidence_basis}\n"
        f"Uncertainty: {resp.assessment.uncertainty}\n"
    )
    
    if resp.possible_conditions:
        lines.append("POSSIBLE CONDITIONS:")
        for idx, cond in enumerate(resp.possible_conditions, 1):
            lines.append(f"• {cond.name}\n  Why considered: {cond.reason}\n  Evidence status: {cond.evidence_status}")
        lines.append("")
        
    lines.append(f"RISK LEVEL: {resp.risk_level.value.upper()}\n")
    
    if resp.what_you_can_do_now:
        lines.append("WHAT YOU CAN DO NOW:")
        for act in resp.what_you_can_do_now:
            lines.append(f"• {act}")
        lines.append("")
        
    if resp.warning_signs:
        lines.append("WARNING SIGNS:")
        for ws in resp.warning_signs:
            lines.append(f"⚠ {ws}")
        lines.append("")
        
    lines.append(f"WHEN TO SEE A DOCTOR:\n{resp.when_to_see_doctor}\n")
    
    if resp.evidence:
        lines.append("EVIDENCE / SOURCE:")
        for ev in resp.evidence:
            citation_str = f" [{ev.citation}]" if ev.citation else ""
            lines.append(f"• {ev.title} ({ev.source_type} - {ev.source}){citation_str}")
        lines.append("")
        
    lines.append(f"MEDICAL DISCLAIMER:\n{resp.medical_disclaimer}")
    return "\n".join(lines).strip()
