import json
import logging
from typing import List, Dict, Any, Optional
from langchain_google_genai import ChatGoogleGenerativeAI
from rag.config.settings import settings, get_gemini_api_key
from models.clinical_response import (
    ClinicalResponseSchema,
    AssessmentSchema,
    PossibleConditionSchema,
    EvidenceItemSchema,
    RiskLevelEnum,
    format_clinical_answer
)

logger = logging.getLogger(__name__)

# Backwards compatibility alias
ClinicalReasonResponse = ClinicalResponseSchema
ClinicalReasoningResponse = ClinicalResponseSchema

class ClinicalAgent:
    def __init__(self):
        self._llm = None
        self._cached_api_key = None

    @property
    def llm(self):
        api_key = get_gemini_api_key()
        if not api_key:
            return None
        if self._llm is None or self._cached_api_key != api_key:
            self._cached_api_key = api_key
            self._llm = ChatGoogleGenerativeAI(
                model=settings.gemini_model,
                google_api_key=api_key,
                temperature=0.0,
                max_retries=1
            ).with_structured_output(ClinicalResponseSchema)
        return self._llm

    @llm.setter
    def llm(self, value):
        self._llm = value
        self._cached_api_key = "EXPLICIT_OVERRIDE"

    def _build_provenance_evidence(
        self,
        patient_evidence: List[Dict[str, Any]],
        medical_evidence: List[Dict[str, Any]]
    ) -> List[EvidenceItemSchema]:
        """Convert retrieved RAG evidence into EvidenceItemSchema without losing metadata."""
        items: List[EvidenceItemSchema] = []
        
        if patient_evidence:
            for pe in patient_evidence:
                rec_id = pe.get("record_id") or pe.get("chunk_id") or "Patient Record"
                text_snippet = pe.get("text", "")
                preview = f"{text_snippet[:100]}..." if len(text_snippet) > 100 else text_snippet
                items.append(
                    EvidenceItemSchema(
                        title=f"Patient Record ({pe.get('record_type', 'Consultation')})",
                        source_type="Patient RAG",
                        source="Patient Consultation Record",
                        citation=str(rec_id),
                        relevance=f"Patient history: {preview}" if preview else "Patient historical medical record."
                    )
                )

        if medical_evidence:
            for me in medical_evidence:
                title = me.get("title") or "Medical Guidance"
                publisher = me.get("publisher") or "WHO / Clinical Guidelines"
                citation = me.get("url") or me.get("chunk_id") or ""
                text_snippet = me.get("text", "")
                preview = f"{text_snippet[:100]}..." if len(text_snippet) > 100 else text_snippet
                items.append(
                    EvidenceItemSchema(
                        title=title,
                        source_type="Medical RAG",
                        source=publisher,
                        citation=str(citation),
                        relevance=f"Clinical reference: {preview}" if preview else "Verified clinical reference."
                    )
                )

        if not items:
            items.append(
                EvidenceItemSchema(
                    title="No retrieved evidence",
                    source_type="None",
                    source="No retrieved medical evidence",
                    citation="",
                    relevance="Response is limited by insufficient retrieved evidence."
                )
            )

        return items

    def _determine_source_mode(
        self,
        has_patient: bool,
        has_medical: bool
    ) -> str:
        if has_patient and has_medical:
            return "Hybrid"
        if has_patient:
            return "Patient RAG"
        if has_medical:
            return "Medical RAG"
        return "None"

    def reason(
        self,
        query: str,
        patient_evidence: List[Dict[str, Any]],
        medical_evidence: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        # Collect chunk IDs from evidence if available
        available_sources = []
        if medical_evidence:
            available_sources.extend([e.get("chunk_id") for e in medical_evidence if e.get("chunk_id")])
        if patient_evidence:
            available_sources.extend([e.get("chunk_id") for e in patient_evidence if e.get("chunk_id")])

        default_evidence = self._build_provenance_evidence(patient_evidence, medical_evidence)
        source_mode = self._determine_source_mode(bool(patient_evidence), bool(medical_evidence))

        # If Gemini is not configured, return controlled unavailable state
        if self.llm is None:
            logger.info("Gemini not configured; returning controlled LLM unavailable state for clinical reasoning")
            fallback_response = ClinicalResponseSchema(
                symptom_summary=query,
                assessment=AssessmentSchema(
                    summary="AI reasoning service is currently unavailable as the Gemini API is not configured.",
                    evidence_basis="No active LLM reasoning engine.",
                    uncertainty="The available information is insufficient to determine causes or evaluate symptoms safely."
                ),
                possible_conditions=[],
                risk_level=RiskLevelEnum.insufficientInformation,
                what_you_can_do_now=[
                    "Rest and monitor your symptoms closely.",
                    "Record when symptoms started and how they change.",
                    "Consult a qualified healthcare professional for personalized medical evaluation."
                ],
                warning_signs=["No specific warning signs were identified from the available information."],
                when_to_see_doctor="Please arrange a medical consultation with a qualified doctor for clinical advice.",
                evidence=default_evidence,
                medical_disclaimer="This information is for general health guidance and is not a medical diagnosis. Please consult a qualified healthcare professional for personal medical advice.",
                source_mode=source_mode,
                requires_professional_review=True,
                emergency=False
            )
            return {
                "answer": format_clinical_answer(fallback_response),
                "structured_response": fallback_response.model_dump(),
                "confidence": "low",
                "requires_professional_review": True,
                "grounded": False,
                "sources": available_sources,
                "risk_level": "insufficientInformation",
                "recommended_next_step": "Please consult a qualified healthcare professional.",
                "error": "LLM_UNAVAILABLE"
            }

        patient_context_str = json.dumps(patient_evidence, indent=2, ensure_ascii=False) if patient_evidence else "No patient context retrieved."
        medical_context_str = json.dumps(medical_evidence, indent=2, ensure_ascii=False) if medical_evidence else "No medical knowledge retrieved."

        prompt = f"""You are the Clinical Reasoning Layer of the GramHealth Healthcare AI System.
Analyze the user's query and provide a structured clinical response adhering strictly to the schema.

USER QUERY:
{query}

PATIENT EVIDENCE:
{patient_context_str}

MEDICAL KNOWLEDGE EVIDENCE:
{medical_context_str}

CRITICAL SAFETY & STRUCTURAL RULES:
1. NOT A DIAGNOSIS ENGINE:
   - Never claim "You have [disease]".
   - State instead: "[Condition] is one possible consideration, but the available information is insufficient to determine the cause."
   - Explicitly distinguish between USER-PROVIDED symptoms, EVIDENCE-SUPPORTED facts, and UNCERTAINTY.
   - If evidence is insufficient, explicitly state in the assessment uncertainty: "Available information is insufficient to determine the cause."

2. POSSIBLE CONDITIONS:
   - Maximum 0 to 3 conditions only.
   - Each condition MUST have:
     * name: non-diagnostic condition name
     * reason: specific reason based on user symptoms/timing
     * evidence_status: e.g. "Possible consideration; not confirmed."
   - If insufficient evidence, return an empty list or 0-1 safe possibilities. Do NOT turn every keyword into a disease.

3. RISK LEVEL:
   - Controlled enum: 'emergency', 'high', 'moderate', 'low', 'insufficientInformation'.
   - If information is insufficient: risk_level = 'insufficientInformation'.
   - emergency: immediate emergency attention indicated by red flags.
   - high: urgent professional evaluation appropriate.
   - moderate: prompt medical evaluation recommended.
   - low: monitor appropriately, no immediate red flags identified.

4. WHAT YOU CAN DO NOW:
   - Provide 2 to 5 practical, safe actions (e.g. rest, monitor symptoms, drink fluids if tolerated, avoid aggravating foods, record symptom timeline).
   - DO NOT prescribe medications or dosages.

5. WARNING SIGNS:
   - Concrete red flags relevant to user symptoms (e.g., for abdominal pain: severe worsening pain, persistent vomiting, fainting, blood in stool).
   - If none identified: "No specific warning signs were identified from the available information."

6. WHEN TO SEE A DOCTOR:
   - Tiered guidance matching the risk level (e.g. "Seek urgent medical attention now if...", "Arrange a medical evaluation today if...", "Monitor and seek medical care if symptoms worsen or persist...").

7. LANGUAGE ADAPTATION:
   - Follow the user's conversational language (English, Hindi, Hinglish, Marathi, or mixed).
   - If user asks in Hindi/Hinglish (e.g. 'sir dard', 'pet dard'), respond in natural, accessible Hindi/Hinglish.
   - If user asks in Marathi (e.g. 'majha pot khupp dukht aahe'), respond in clear Marathi or Marathi-English mix.
   - Keep medical concepts simple and user-friendly.

8. NEVER INVENT EVIDENCE OR CITATIONS:
   - Cite only evidence provided above.
"""
        try:
            result = self.llm.invoke(prompt)

            # Convert result if needed
            if isinstance(result, ClinicalResponseSchema):
                structured = result
            elif isinstance(result, dict):
                structured = ClinicalResponseSchema(**result)
            else:
                # Handle test mock returning dict or custom object
                if hasattr(result, "model_dump"):
                    structured = ClinicalResponseSchema.model_validate(result.model_dump())
                elif hasattr(result, "answer"):
                    # Legacy mock support
                    answer_text = getattr(result, "answer", str(result))
                    risk = getattr(result, "risk_level", "low")
                    risk_mapped = RiskLevelEnum.low
                    if risk in ["emergency", "high", "moderate", "low", "insufficientInformation"]:
                        risk_mapped = RiskLevelEnum(risk)
                    structured = ClinicalResponseSchema(
                        symptom_summary=query,
                        assessment=AssessmentSchema(
                            summary=answer_text,
                            evidence_basis="Clinical reasoning engine",
                            uncertainty="Physical medical examination is required for definitive assessment."
                        ),
                        possible_conditions=[],
                        risk_level=risk_mapped,
                        what_you_can_do_now=[
                            "Rest and monitor symptoms.",
                            "Consult a healthcare professional if symptoms persist."
                        ],
                        warning_signs=["No specific warning signs were identified from the available information."],
                        when_to_see_doctor="Seek medical care if symptoms worsen.",
                        evidence=default_evidence,
                        source_mode=source_mode,
                        requires_professional_review=getattr(result, "requires_professional_review", True),
                        emergency=False
                    )
                else:
                    structured = ClinicalResponseSchema.model_validate(result)

            # Ensure evidence items are populated from actual retrieved provenance
            if not structured.evidence or any(e.source_type == "None" for e in structured.evidence):
                structured.evidence = default_evidence

            # Ensure source_mode is accurate
            structured.source_mode = source_mode

            # Ensure max 3 conditions
            if len(structured.possible_conditions) > 3:
                structured.possible_conditions = structured.possible_conditions[:3]

            answer_text = format_clinical_answer(structured)

            return {
                "answer": answer_text,
                "structured_response": structured.model_dump(),
                "confidence": "high" if structured.risk_level != RiskLevelEnum.insufficientInformation else "medium",
                "requires_professional_review": structured.requires_professional_review,
                "grounded": bool(medical_evidence or patient_evidence),
                "sources": available_sources,
                "risk_level": structured.risk_level.value,
                "recommended_next_step": structured.when_to_see_doctor
            }
        except Exception as e:
            logger.warning(f"Clinical reasoning LLM invocation failed: {type(e).__name__}; returning controlled fallback")
            fallback_response = ClinicalResponseSchema(
                symptom_summary=query,
                assessment=AssessmentSchema(
                    summary="AI reasoning service is currently experiencing technical difficulties.",
                    evidence_basis="Service error fallback",
                    uncertainty="The available system information is insufficient to evaluate symptoms safely."
                ),
                possible_conditions=[],
                risk_level=RiskLevelEnum.insufficientInformation,
                what_you_can_do_now=[
                    "Rest and monitor your symptoms.",
                    "Record symptom details for a doctor.",
                    "Consult a qualified healthcare provider for clinical evaluation."
                ],
                warning_signs=["No specific warning signs were identified from the available information."],
                when_to_see_doctor="Please consult a healthcare professional for advice.",
                evidence=default_evidence,
                medical_disclaimer="This information is for general health guidance and is not a medical diagnosis. Please consult a qualified healthcare professional for personal medical advice.",
                source_mode=source_mode,
                requires_professional_review=True,
                emergency=False
            )
            return {
                "answer": format_clinical_answer(fallback_response),
                "structured_response": fallback_response.model_dump(),
                "confidence": "low",
                "requires_professional_review": True,
                "grounded": False,
                "sources": available_sources,
                "risk_level": "insufficientInformation",
                "recommended_next_step": "Please consult a healthcare professional.",
                "error": f"LLM_ERROR: {type(e).__name__}"
            }
