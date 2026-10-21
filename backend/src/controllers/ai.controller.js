const asyncHandler = require("../utils/asyncHandler");
const prisma = require("../config/prisma");

/**
 * GramHealth Master RAG Knowledge Base
 * Detailed operational guide for the AI Assistant (दीहाती डॉक्टर)
 */
const GRAMHEALTH_MASTER_KNOWLEDGE_BASE = `
=== GRAMHEALTH APPLICATION COMPLETE MASTER KNOWLEDGE BASE ===

1. **Teleconsultation & Booking Consultations (डॉक्टर परामर्श / वीडियो कॉल)**:
   - **How to get a consultation**: Open the GramHealth App -> Tap on 'Find Doctors' or 'Doctor List' -> Select a doctor by specialty (General Physician, Pediatrician, Gynecologist, Neurologist, Cardiologist, etc.) -> Tap 'Request Consultation' or 'Book Appointment' -> Select Video/Audio mode -> Submit request.
   - **Doctor Accept & Call**: The doctor receives your request in real-time, accepts it, and initiates the secure audio/video call.
   - **Digital Prescription**: After consultation, the doctor sends a digital prescription directly to your GramHealth Health Vault.

2. **AI Symptom Checker & Chatbot (दीहाती डॉक्टर)**:
   - 24/7 online & offline AI triage. Analyzes patient symptoms, predicts probable conditions, gives emergency red-flag warnings, and suggests home care remedies or immediate PHC visits.

3. **ABHA Health Vault & Medical Records (डिजिटल स्वास्थ्य कार्ड / ABHA ID)**:
   - Link government ABHA ID to sync digital health records.
   - Upload blood reports, X-rays, prescriptions, and lab results under the 'Health Records' screen.

4. **Pharmacy & Medicine Finder (दवा दुकान / दवा खोजें)**:
   - Go to 'Pharmacy' or 'Medicine Finder' tab -> Search medicine name -> View nearby partner pharmacies with live stock availability and pricing.

5. **ASHA Worker Field System (आशा कार्यकर्ता सेवा)**:
   - Offline-first field tool allowing ASHA workers to record patient vitals, screen pregnant women/children, and sync data when connected to internet.

6. **24/7 Emergency Triage (आपातकालीन 108/112)**:
   - Tap 'Emergency' button on the home screen to directly connect with 108/112 ambulance services or nearest PHC/CHC hospital.
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

  // Medical specialty keywords
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

      if (nameToken && nameToken.length > 2 && !["list", "details", "name", "available", "show"].includes(nameToken)) {
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

      if (doctors.length === 0) {
        doctors = await prisma.doctor.findMany({
          take: 10,
          include: { user: { select: { name: true, phone: true, email: true } } }
        });
      }

      if (doctors.length > 0) {
        const docLines = doctors.map((d) => {
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
      }
    }

    // Patient Records Search
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
  let routingMethod = "knowledge_engine";

  // ── 2. Primary Execution: Gemini LLM with Full RAG Knowledge Base ──────────
  if (apiKey) {
    const modelEndpoints = [
      "gemini-1.5-flash",
      "gemini-2.0-flash",
      "gemini-1.5-pro"
    ];

    const systemPrompt = `You are GramHealth AI (दीहाती डॉक्टर), an intelligent healthcare assistant and platform guide for GramHealth India.
Answer the user's question directly, naturally, and helpfully using the application knowledge base and database context below.

${GRAMHEALTH_MASTER_KNOWLEDGE_BASE}
${dynamicDbContext}

Guidelines:
- If the user asks how to do something (e.g. consultation, booking, ABHA, pharmacy, records), explain the exact steps clearly.
- If the user asks for a doctor or specialty, refer to the live doctors list from the database.
- Be empathetic, clear, and easy to understand.

User Question: ${queryText}`;

    for (const modelName of modelEndpoints) {
      try {
        const geminiResponse = await fetch(
          `https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent?key=${apiKey}`,
          {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              contents: [{ role: "user", parts: [{ text: systemPrompt }] }],
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
        }
      } catch (err) {
        console.error(`[Backend AI] Error calling Gemini endpoint ${modelName}:`, err.message);
      }
    }
  }

  // ── 3. Universal Natural Language Fallback Engine (Handles Typos & Offline Mode)
  if (!answer) {
    // A. Consultation & Booking Queries (handles typos like 'consutation', 'consulation', 'consult', 'booking', 'appointment')
    if (
      qLower.includes("consult") ||
      qLower.includes("consut") ||
      qLower.includes("consul") ||
      qLower.includes("appointment") ||
      qLower.includes("book") ||
      qLower.includes("video call")
    ) {
      answer = `To get a doctor consultation on GramHealth:

1. 📱 Tap on **'Find Doctors'** or **'Doctor List'** from the main dashboard.
2. 👨‍⚕️ Select a doctor matching your required specialty (e.g., General Physician, Neurologist, Pediatrician).
3. 📩 Tap **'Request Consultation'** or **'Book Appointment'**.
4. 📞 Select Video or Audio call mode and submit your request.
5. 📄 Once the doctor accepts and completes the call, your digital prescription will automatically save to your Health Vault!`;
    }
    // B. Doctor Queries
    else if (doctorSearchResultText) {
      answer = doctorSearchResultText;
    }
    // C. Stomach & Gastrointestinal Symptom Queries (handles Hindi/Hinglish terms like 'pet main infection', 'pet dard', 'dast', 'loose motion', 'vomit', 'stomach ache')
    else if (
      qLower.includes("pet") ||
      qLower.includes("stomach") ||
      qLower.includes("infection") ||
      qLower.includes("dast") ||
      qLower.includes("loose motion") ||
      qLower.includes("gastric") ||
      qLower.includes("acidity") ||
      qLower.includes("vomit") ||
      qLower.includes("ulti")
    ) {
      answer = `Condition: Stomach Infection / Gastroenteritis (पेट का संक्रमण)

Health Advice & Remedies:
1. 💧 **Dehydration Prevention**: Drink plenty of clean boiled water, coconut water, or ORS (Oral Rehydration Solution) to maintain electrolyte balance.
2. 🍚 **Light Diet**: Eat soft, easy-to-digest food such as curd rice (दही-चावल), khichdi (खिचड़ी), bananas, and toast. Avoid oily, spicy, raw, or street food.
3. 🛌 **Rest**: Rest well to allow your digestive tract to recover.

⚠️ **When to Consult a Doctor Immediately**:
If you experience high fever (>101°F), severe abdominal cramps, persistent vomiting for >24 hours, or blood in stool, please consult a verified physician or visit your nearest PHC immediately.`;
    }
    // D. ABHA & Health Records Queries
    else if (qLower.includes("abha") || qLower.includes("record") || qLower.includes("report") || qLower.includes("vault")) {
      answer = `To manage your medical records & ABHA ID:

1. 📂 Open the **'Health Records'** screen from your bottom navigation menu.
2. 🪪 Tap **'Link ABHA ID'** to sync your official Government ABHA health profile.
3. 📄 Tap **'Upload Record'** to take a picture of lab tests, prescriptions, or X-rays to store them securely.`;
    }
    // E. Pharmacy & Medicine Queries
    else if (qLower.includes("pharmacy") || qLower.includes("medicine") || qLower.includes("dawa") || qLower.includes("store")) {
      answer = `To find local pharmacies and medicines:

1. 💊 Tap on the **'Pharmacy'** tab on the home screen.
2. 🔍 Search for any medicine or brand name.
3. 📍 View nearby partner pharmacies, live stock availability, and prices.`;
    }
    // F. General App Overview Queries
    else if (qLower.includes("service") || qLower.includes("app") || qLower.includes("feature") || qLower.includes("how to")) {
      answer = `GramHealth offers 6 core services to help you:

1. 🩺 **Teleconsultations**: Book audio/video calls with verified doctors.
2. 🤖 **AI Symptom Checker**: 24/7 symptom analysis & health guidance.
3. 📂 **ABHA Health Vault**: Store and manage digital health records.
4. 💊 **Pharmacy Finder**: Check local medicine stock & prices.
5. 👩‍⚕️ **ASHA Worker System**: Rural field care monitoring.
6. 🚨 **Emergency Triage**: 108/112 ambulance integration.`;
    }
    // G. General Greeting Fallback
    else {
      answer = `Hello! I am your GramHealth AI Assistant (दीहाती डॉक्टर). You can ask me how to book doctor consultations, check health symptoms, search local pharmacies, or view your medical records!`;
    }
  }

  const isMedicalSymptomQuery =
    qLower.includes("fever") ||
    qLower.includes("pain") ||
    qLower.includes("cough") ||
    qLower.includes("headache") ||
    qLower.includes("symptom") ||
    qLower.includes("disease") ||
    qLower.includes("cure") ||
    qLower.includes("pet") ||
    qLower.includes("stomach") ||
    qLower.includes("infection") ||
    qLower.includes("dast") ||
    qLower.includes("loose motion") ||
    qLower.includes("vomit") ||
    qLower.includes("thikh");

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
