const asyncHandler = require("../utils/asyncHandler");
const prisma = require("../config/prisma");

/**
 * App Services Context Document
 */
const APP_SERVICES_CONTEXT = `
GramHealth Application Services Overview:
1. **Teleconsultation & Video Calls**: Instant & scheduled audio/video consultations with verified doctors, specialty search, and digital prescription generation.
2. **AI Symptom Checker & Chatbot (दीहाती डॉक्टर)**: 24/7 online & offline AI triage, disease prediction, precautions, and home care advice.
3. **ABHA Health Vault**: Government ABHA ID integration for uploading, storing, and viewing digital medical records & lab test reports.
4. **Pharmacy & Medicine Finder**: Search local pharmacies, view live stock availability, and place medicine orders.
5. **ASHA Worker Care System**: Offline-first field data entry and patient monitoring for rural healthcare workers.
6. **Emergency 24/7 Triage**: Direct red-flag emergency detection linking patients to 108/112 services.
`;

/**
 * Handle AI query from GramHealth Flutter App
 * POST /api/ai/query
 */
const queryAi = asyncHandler(async (req, res) => {
  const { query, patientId } = req.body;

  if (!query || typeof query !== "string" || !query.trim()) {
    return res.status(400).json({
      success: false,
      message: "Query text is required",
    });
  }

  const queryText = query.trim();
  const qLower = queryText.toLowerCase();
  const apiKey = process.env.GEMINI_API_KEY;

  // Extract medical specialty keywords from query
  const specialties = [
    "neurology", "neurologist",
    "pediatric", "pediatrician", "child",
    "cardio", "cardiologist", "heart",
    "gynecology", "gynecologist", "women",
    "dermatology", "dermatologist", "skin",
    "orthopedic", "bone",
    "general", "physician"
  ];

  const matchedSpecialty = specialties.find(s => qLower.includes(s));

  // ── 1. Dynamic Database Context Retrieval ─────────────────────────────────
  let dynamicDbContext = "";
  let doctorSearchResultText = "";

  try {
    const isDoctorQuery =
      qLower.includes("doctor") ||
      qLower.includes("dr") ||
      qLower.includes("specialist") ||
      qLower.includes("list") ||
      matchedSpecialty;

    if (isDoctorQuery) {
      let doctors = [];

      // Extract specific doctor name token (e.g., "doctor roshan" -> "roshan")
      const nameMatch = qLower.match(/(?:doctor|dr\.?)\s+([a-z0-9]+)/i);
      const nameToken = nameMatch ? nameMatch[1] : null;

      if (nameToken && nameToken.length > 2 && nameToken !== "list" && nameToken !== "details" && nameToken !== "name") {
        doctors = await prisma.doctor.findMany({
          where: {
            OR: [
              { user: { name: { contains: nameToken, mode: "insensitive" } } },
              { specialization: { contains: nameToken, mode: "insensitive" } },
              { hospitalName: { contains: nameToken, mode: "insensitive" } }
            ]
          },
          take: 10,
          include: { user: { select: { name: true, phone: true, email: true } } }
        });
      }

      // If no name match, try specialty match
      if (doctors.length === 0 && matchedSpecialty) {
        doctors = await prisma.doctor.findMany({
          where: {
            OR: [
              { specialization: { contains: matchedSpecialty, mode: "insensitive" } },
              { user: { name: { contains: matchedSpecialty, mode: "insensitive" } } }
            ]
          },
          take: 10,
          include: { user: { select: { name: true, phone: true, email: true } } }
        });
      }

      // If still no doctors found, get all active doctors
      if (doctors.length === 0) {
        doctors = await prisma.doctor.findMany({
          take: 10,
          include: { user: { select: { name: true, phone: true, email: true } } }
        });
      }

      if (doctors.length > 0) {
        const docLines = doctors.map((d, idx) => {
          const docName = d.user?.name ? (d.user.name.startsWith("Dr.") ? d.user.name : `Dr. ${d.user.name}`) : "Doctor";
          const spec = d.specialization || "General Physician";
          const hosp = d.hospitalName || "GramHealth Clinic";
          const phone = d.user?.phone ? ` | Phone: ${d.user.phone}` : "";
          const email = d.user?.email ? ` | Email: ${d.user.email}` : "";
          return `👨‍⚕️ **${docName}** - ${spec} (${hosp})${phone}${email}`;
        });

        if (nameToken && doctors.some(d => d.user?.name?.toLowerCase().includes(nameToken))) {
          doctorSearchResultText = `Here are the matching doctor details found for **"${nameToken.toUpperCase()}"**:\n\n` + docLines.join("\n\n");
        } else if (matchedSpecialty && doctors.some(d => d.specialization?.toLowerCase().includes(matchedSpecialty))) {
          doctorSearchResultText = `Here are the matching **${matchedSpecialty.toUpperCase()}** doctors registered on GramHealth:\n\n` + docLines.join("\n\n");
        } else if (nameToken || matchedSpecialty) {
          doctorSearchResultText = `No exact match found for "${nameToken || matchedSpecialty}". Here are the active GramHealth verified doctors available for teleconsultation:\n\n` + docLines.join("\n\n");
        } else {
          doctorSearchResultText = `Here are the active registered doctors on GramHealth available for teleconsultation:\n\n` + docLines.join("\n\n");
        }

        dynamicDbContext += `\n[LIVE REGISTERED DOCTORS IN DATABASE]:\n` + docLines.join("\n");
      } else {
        doctorSearchResultText = "There are currently no doctors registered in the database. Please check back soon or contact support.";
      }
    }

    // B. Medical Records Context Search
    const targetUserId = req.user?.userId || patientId;
    if (
      targetUserId &&
      (qLower.includes("record") || qLower.includes("history") || qLower.includes("report") || qLower.includes("prescription"))
    ) {
      const patient = await prisma.patient.findFirst({
        where: { OR: [{ userId: targetUserId }, { id: targetUserId }] },
        include: {
          medicalRecords: { take: 5, orderBy: { createdAt: "desc" } },
          prescriptions: { take: 5, orderBy: { createdAt: "desc" } }
        }
      });

      if (patient) {
        dynamicDbContext += "\n[PATIENT HEALTH RECORDS SUMMARY]:\n";
        if (patient.medicalRecords?.length > 0) {
          dynamicDbContext += `- Medical Records Count: ${patient.medicalRecords.length}\n`;
          patient.medicalRecords.forEach(r => {
            dynamicDbContext += `  • ${r.title || "Record"} (${r.category || "General"}): ${r.description || "No summary"}\n`;
          });
        }
      }
    }
  } catch (dbErr) {
    console.warn("[Backend AI] Context retrieval warning:", dbErr.message);
  }

  let answer = "";
  let routingMethod = "medical_rules_engine";

  if (apiKey) {
    const modelEndpoints = [
      "gemini-1.5-flash",
      "gemini-2.0-flash",
      "gemini-1.5-pro"
    ];

    const systemPrompt = `You are GramHealth AI (दीहाती डॉक्टर), an expert rural healthcare assistant and platform guide for India.
Your goal is to provide accurate, empathetic healthcare triage, disease prediction, application guidance, doctor recommendations, and health record summaries.

${APP_SERVICES_CONTEXT}
${dynamicDbContext}

Instructions for your response:
1. **If asking about Doctors or Specialties (e.g. Neurology, Pediatrics, Cardiology)**: Provide a clear list of matching doctors from the database context provided above.
2. **If asking about App Services**: Explain GramHealth features (Teleconsultations, ABHA Vault, Pharmacy Finder, AI Triage).
3. **If asking about Symptoms/Health**: Provide potential causes, warning signs, home remedies, and PHC visit recommendations.

User Question: ${queryText}`;

    for (const modelName of modelEndpoints) {
      try {
        const geminiResponse = await fetch(
          `https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent?key=${apiKey}`,
          {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              contents: [
                {
                  role: "user",
                  parts: [{ text: systemPrompt }],
                },
              ],
            }),
          }
        );

        if (geminiResponse.ok) {
          const geminiData = await geminiResponse.json();
          const generatedText = geminiData?.candidates?.[0]?.content?.parts?.[0]?.text;
          if (generatedText) {
            answer = generatedText.trim();
            routingMethod = `gemini_${modelName}`;
            break;
          }
        } else {
          const errText = await geminiResponse.text();
          console.warn(`[Backend AI] Model ${modelName} returned status ${geminiResponse.status}: ${errText}`);
        }
      } catch (err) {
        console.error(`[Backend AI] Error calling Gemini endpoint ${modelName}:`, err.message);
      }
    }
  }

  // Guaranteed Smart Fallback: Executes if Gemini call fails or API key is absent
  if (!answer) {
    if (doctorSearchResultText) {
      answer = doctorSearchResultText;
    } else if (qLower.includes("service") || qLower.includes("app") || qLower.includes("feature")) {
      answer = "GramHealth provides 6 core services:\n1. 🩺 Doctor Teleconsultations\n2. 🤖 AI Symptom Checker & Chatbot\n3. 📂 ABHA Health Record Vault\n4. 💊 Local Pharmacy Finder & Medicine Availability\n5. 👩‍⚕️ ASHA Worker Field System\n6. 🚨 24/7 Emergency Triage (108/112).";
    } else if (qLower.includes("fever") || qLower.includes("bukhar") || qLower.includes("taap")) {
      answer = "Fever can be caused by viral infections, flu, or malaria. Please stay hydrated, take rest, and monitor your temperature. If fever exceeds 101°F (38.3°C) or lasts more than 3 days, please consult a physician immediately.";
    } else {
      answer = `Hello! I am your GramHealth AI Assistant (दीहाती डॉक्टर). I can help answer health queries, check symptoms, show available doctors, explain app services, and access your health records. How can I assist you today?`;
    }
  }

  const isMedicalSymptomQuery =
    qLower.includes("fever") ||
    qLower.includes("pain") ||
    qLower.includes("cough") ||
    qLower.includes("headache") ||
    qLower.includes("symptom") ||
    qLower.includes("disease") ||
    qLower.includes("cure");

  return res.status(200).json({
    success: true,
    data: {
      query: queryText,
      intent: doctorSearchResultText ? "doctor_lookup" : (isMedicalSymptomQuery ? "symptom_analysis" : "general_health"),
      agent: "online_ai_assistant",
      answer: answer,
      grounded: true,
      confidence: "high",
      urgency: "routine",
      requires_professional_review: isMedicalSymptomQuery,
      routing_method: routingMethod,
    },
  });
});

module.exports = { queryAi };
