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
  console.log('[Backend AI] GEMINI_API_KEY loaded:', apiKey ? `YES (${apiKey.length} chars)` : 'NO - MISSING');

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

    // Pharmacy Search
    let pharmacySearchResultText = "";
    const isPharmacyQuery =
      qLower.includes("pharmacy") ||
      qLower.includes("medical store") ||
      qLower.includes("medicine store") ||
      qLower.includes("dawa") ||
      qLower.includes("chemist") ||
      qLower.includes("drug store");

    if (isPharmacyQuery) {
      let pharmacies = [];

      const nameMatch = qLower.match(/(?:pharmacy|medical store|chemist|drug store)\s+([a-z0-9\s]+)/i);
      const nameToken = nameMatch ? nameMatch[1].trim() : null;

      if (nameToken && nameToken.length > 2 && !["list", "details", "name", "available", "show", "near", "nearby"].includes(nameToken)) {
        pharmacies = await prisma.pharmacy.findMany({
          where: {
            OR: [
              { name: { contains: nameToken, mode: "insensitive" } },
              { address: { contains: nameToken, mode: "insensitive" } }
            ]
          },
          take: 10,
        });
      }

      if (pharmacies.length === 0) {
        pharmacies = await prisma.pharmacy.findMany({
          take: 10,
        });
      }

      if (pharmacies.length > 0) {
        const pharmLines = pharmacies.map((p) => {
          const name = p.name || "Pharmacy";
          const addr = p.address ? ` | ${p.address}` : "";
          const contact = p.contact ? ` | Contact: ${p.contact}` : "";
          const loc = ` | Location: ${p.latitude.toFixed(4)}, ${p.longitude.toFixed(4)}`;
          return `💊 **${name}**${addr}${contact}${loc}`;
        });

        if (nameToken && pharmacies.some(p => p.name?.toLowerCase().includes(nameToken))) {
          pharmacySearchResultText = `Here are the matching pharmacy details found for **"${nameToken.toUpperCase()}"**:\n\n` + pharmLines.join("\n\n");
        } else {
          pharmacySearchResultText = `Here are the registered pharmacies on GramHealth:\n\n` + pharmLines.join("\n\n");
        }

        dynamicDbContext += `\n[LIVE REGISTERED PHARMACIES IN DATABASE]:\n` + pharmLines.join("\n");
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

  // Determine if this is a medical symptom query BEFORE fallback engine
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
    qLower.includes("thikh") ||
    qLower.includes("breath") ||
    qLower.includes("chest") ||
    qLower.includes("fatigue") ||
    qLower.includes("tired") ||
    qLower.includes("weakness") ||
    qLower.includes("nausea") ||
    qLower.includes("vomiting") ||
    qLower.includes("ult") ||
    qLower.includes("matli") ||
    qLower.includes("rash") ||
    qLower.includes("skin") ||
    qLower.includes("itch") ||
    qLower.includes("allergy") ||
    qLower.includes("joint") ||
    qLower.includes("muscle") ||
    qLower.includes("body ache") ||
    qLower.includes("urine") ||
    qLower.includes("urination") ||
    qLower.includes("uti") ||
    qLower.includes("burning") ||
    qLower.includes("dizzy") ||
    qLower.includes("faint");

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
        console.log(`[Backend AI] Trying Gemini model: ${modelName}`);
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

        console.log(`[Backend AI] Gemini ${modelName} response status: ${geminiResponse.status}`);

        if (geminiResponse.ok) {
          const geminiData = await geminiResponse.json();
          const generatedText = geminiData?.candidates?.[0]?.content?.parts?.[0]?.text;
          if (generatedText) {
            answer = generatedText.trim();
            routingMethod = `gemini_${modelName}`;
            console.log(`[Backend AI] SUCCESS with ${modelName}`);
            break;
          } else {
            console.warn(`[Backend AI] ${modelName} returned empty response`);
          }
        } else {
          const errorBody = await geminiResponse.text();
          console.error(`[Backend AI] ${modelName} failed: ${geminiResponse.status} - ${errorBody}`);
        }
      } catch (err) {
        console.error(`[Backend AI] Error calling Gemini endpoint ${modelName}:`, err.message);
      }
    }
  }

  // ── 3. Universal Natural Language Fallback Engine (Handles Typos & Offline Mode)
  if (!answer) {
    console.warn('[Backend AI] All Gemini models failed or no API key - using fallback engine');
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
    // C. Symptom Analysis - Comprehensive Medical Fallback
    else if (isMedicalSymptomQuery) {
      answer = generateSymptomAnalysisFallback(qLower);
    }
    // D. ABHA & Health Records Queries
    else if (qLower.includes("abha") || qLower.includes("record") || qLower.includes("report") || qLower.includes("vault")) {
      answer = `To manage your medical records & ABHA ID:

1. 📂 Open the **'Health Records'** screen from your bottom navigation menu.
2. 🪪 Tap **'Link ABHA ID'** to sync your official Government ABHA health profile.
3. 📄 Tap **'Upload Record'** to take a picture of lab tests, prescriptions, or X-rays to store them securely.`;
    }
    // E. Pharmacy & Medicine Queries
    else if (pharmacySearchResultText) {
      answer = pharmacySearchResultText;
    }
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

  return res.status(200).json({
    success: true,
    data: {
      query: queryText,
      intent: doctorSearchResultText ? "doctor_lookup" : (pharmacySearchResultText ? "pharmacy_lookup" : (isMedicalSymptomQuery ? "symptom_analysis" : "general_health")),
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

/**
 * Generate comprehensive symptom analysis fallback for common medical symptoms
 * Provides structured medical guidance when Gemini API is unavailable
 */
function generateSymptomAnalysisFallback(qLower) {
  // Check for specific symptom patterns and return appropriate medical guidance
  const symptoms = {
    // Fever and temperature related
    fever: {
      condition: "Fever (बुखार)",
      keywords: ["fever", "temperature", "bukhar", "tap", "pyrexia"],
      advice: `**Immediate Care:**
1. 🌡️ **Monitor Temperature**: Check temperature every 4-6 hours. Normal: 97-99°F (36-37.2°C)
2. 💧 **Hydration**: Drink plenty of fluids - water, ORS, coconut water, clear soups
3. 🛌 **Rest**: Complete rest in a cool, well-ventilated room
4. 🧊 **Cooling**: Lukewarm sponge baths (not cold water), light clothing
5. 💊 **Medication**: Paracetamol 500mg every 6 hours (max 4g/day) if temp >100°F

**⚠️ Red Flags - Seek Immediate Care:**
- Temperature >103°F (39.4°C) or >101°F in infants <3 months
- Fever lasting >3 days without improvement
- Severe headache, neck stiffness, confusion, difficulty breathing
- Rash with fever, seizures, persistent vomiting`,
      urgency: "routine"
    },
    
    // Headache and migraine
    headache: {
      condition: "Headache / Migraine (सिरदर्द / आधा सीसी)",
      keywords: ["headache", "migraine", "head pain", "sir dard", "half head pain"],
      advice: `**Immediate Relief:**
1. 🌑 **Dark Quiet Room**: Rest in a dark, quiet environment
2. 💧 **Hydration**: Drink 2-3 glasses of water - dehydration is a common trigger
3. 🧊 **Cold/Heat**: Cold compress on forehead for migraine; warm compress for tension headache
4. 💊 **OTC Relief**: Paracetamol 500mg or Ibuprofen 400mg (with food)
5. ☕ **Caffeine**: Small amount may help (but don't overuse)

**⚠️ Red Flags - Seek Immediate Care:**
- Sudden "thunderclap" worst headache of life
- Headache with fever, stiff neck, confusion, vision changes
- Headache after head injury
- New onset headaches >50 years old`,
      urgency: "routine"
    },
    
    // Cough and respiratory
    cough: {
      condition: "Cough / Respiratory Infection (खांसी / श्वसन संक्रमण)",
      keywords: ["cough", "khansi", "khasi", "cold", "flu", "respiratory"],
      advice: `**Home Care:**
1. 🍯 **Honey & Warm Water**: 1 tsp honey in warm water 3x/day (not for children <1 year)
2. 💨 **Steam Inhalation**: 10-15 min, 2-3x/day with eucalyptus/mint if available
3. 💧 **Hydration**: Warm fluids - herbal tea, soup, water
4. 🛌 **Elevated Head**: Sleep with extra pillow
5. 💊 **OTC**: Dextromethorphan for dry cough; Guaifenesin for productive cough

**⚠️ Red Flags - Seek Immediate Care:**
- Cough >3 weeks, coughing blood
- High fever >101°F with cough
- Shortness of breath, wheezing, chest pain
- Night sweats, unexplained weight loss`,
      urgency: "routine"
    },
    
    // Chest pain - HIGH PRIORITY
    chest_pain: {
      condition: "Chest Pain (सीने में दर्द) - POTENTIAL EMERGENCY",
      keywords: ["chest pain", "chest tightness", "chest discomfort", "angina", "heart pain", "sine mein dard"],
      advice: `**⚠️ THIS MAY BE A MEDICAL EMERGENCY - ACT FAST:**

**If ANY of these: CALL 108/112 OR GO TO NEAREST EMERGENCY DEPT IMMEDIATELY:**
- Crushing/squeezing chest pain radiating to arm, jaw, back, neck
- Shortness of breath, sweating, nausea, dizziness
- Pain lasting >10 minutes or worsening with exertion
- History of heart disease, diabetes, high BP

**If clearly musculoskeletal (tender to touch, changes with movement):**
1. 🛌 Rest and avoid strenuous activity
2. 💊 Ibuprofen 400mg with food for inflammation
3. 🧊 Warm compress to affected area

**When in doubt - ALWAYS seek emergency care. Heart attacks can present atypically.**`,
      urgency: "emergency"
    },
    
    // Fatigue and weakness
    fatigue: {
      condition: "Fatigue / Weakness (थकान / कमजोरी)",
      keywords: ["fatigue", "tired", "weakness", "exhaustion", "lethargy", "thakan", "kamzori"],
      advice: `**Assessment & Care:**
1. 😴 **Sleep**: 7-9 hours quality sleep, consistent schedule
2. 🥗 **Nutrition**: Balanced meals - protein, complex carbs, iron-rich foods (spinach, lentils, jaggery)
3. 💧 **Hydration**: 2.5-3L water daily
4. 🚶 **Light Activity**: Gentle walking 15-20 min daily (not intense exercise)
5. 🧘 **Stress Management**: Deep breathing, meditation

**⚠️ Red Flags - Consult Doctor:**
- Fatigue >2 weeks despite rest
- Unexplained weight loss, night sweats
- Shortness of breath on mild exertion
- Palpitations, dizziness, fainting
- Depression symptoms (low mood >2 weeks)`,
      urgency: "routine"
    },
    
    // Nausea and vomiting
    nausea: {
      condition: "Nausea / Vomiting (मतली / उल्टी)",
      keywords: ["nausea", "vomit", "vomiting", "ulti", "matli", "sick"],
      advice: `**Immediate Care:**
1. 🚫 **NPO (Nothing by mouth)** for 1-2 hours after vomiting, then...
2. 💧 **Sips**: Ice chips → clear fluids (water, ORS, coconut water) - 1 tsp every 5 min
3. 🍚 **BRAT Diet**: Banana, Rice, Applesauce, Toast - once tolerating fluids
4. 💊 **Anti-emetic**: Ondansetron 4mg or Domperidone 10mg (if available/prescribed)
5. 🛌 **Position**: Sit upright or left lateral; avoid lying flat

**⚠️ Red Flags - Seek Immediate Care:**
- Vomiting >24 hours, unable to keep fluids down
- Signs of dehydration (dry mouth, no urine >8h, dizziness)
- Severe abdominal pain, blood in vomit (coffee ground appearance)
- High fever, stiff neck, severe headache`,
      urgency: "routine"
    },
    
    // Stomach/Abdominal pain
    abdominal_pain: {
      condition: "Abdominal Pain (पेट दर्द)",
      keywords: ["stomach pain", "abdominal pain", "belly pain", "pet dard", "pet me dard", "tummy ache"],
      advice: `**Assessment & Care:**
1. 📍 **Location Matters**: 
   - Upper central: Gastritis/acidity
   - Right upper: Gallbladder/liver
   - Right lower: Appendicitis (EMERGENCY if severe)
   - Left lower: Diverticulitis/colon
   - Generalized: Gastroenteritis
2. 💧 **Hydration**: Small sips of clear fluids
3. 🍚 **Light Diet**: Khichdi, curd rice, toast - avoid spicy/oily
4. 💊 **Antacid**: Gelusil/Mucaine gel 10ml for acidity
5. 🛌 **Rest**: Comfortable position (often knees bent)

**⚠️ Red Flags - Seek Immediate Care:**
- Severe pain, especially right lower quadrant (appendicitis)
- Pain with fever, vomiting, inability to pass gas/stool
- Blood in stool or black tarry stools
- Pregnancy with abdominal pain`,
      urgency: "routine"
    },
    
    // Breathing difficulty - HIGH PRIORITY
    breathing: {
      condition: "Shortness of Breath / Breathing Difficulty (सांस लेने में तकलीफ) - POTENTIAL EMERGENCY",
      keywords: ["breath", "breathing", "shortness", "dyspnea", "saans", "sas", "difficulty breathing"],
      advice: `**⚠️ THIS IS A MEDICAL EMERGENCY - SEEK CARE IMMEDIATELY:**

**CALL 108/112 OR GO TO NEAREST EMERGENCY DEPT IF:**
- Cannot speak in full sentences
- Blue lips/fingernails, confusion, drowsiness
- Wheezing, stridor (high-pitched sound)
- Chest pain with breathing difficulty
- Rapid breathing >24 breaths/min

**While seeking care:**
1. 🪑 **Sit upright** - do not lie flat
2. 💨 **Use inhaler** if prescribed (salbutamol/asthma inhaler)
3. 🧘 **Stay calm** - anxiety worsens breathing
4. 🪟 **Fresh air** - open windows, loosen tight clothing

**Common causes needing urgent evaluation:** Asthma attack, allergic reaction, heart failure, pneumonia, pulmonary embolism, COVID-19.`,
      urgency: "emergency"
    },
    
    // Joint/muscle pain
    joint_pain: {
      condition: "Joint / Muscle Pain (जोड़ों का दर्द / मांसपेशियों में दर्द)",
      keywords: ["joint pain", "muscle pain", "body ache", "joint", "arthritis", "jod dard", "body pain"],
      advice: `**General Care:**
1. 🧊 **RICE**: Rest, Ice (15-20 min), Compression, Elevation
2. 💊 **NSAIDs**: Ibuprofen 400mg or Diclofenac 50mg with food (max 3 days)
3. 🛌 **Activity Modification**: Avoid aggravating movements, gentle range of motion
4. 🌡️ **Warmth**: After 48h, warm compresses for stiffness
5. 🏃 **Physio**: Gentle stretching once acute pain subsides

**⚠️ Red Flags - Consult Doctor:**
- Joint swelling, redness, heat (possible infection/gout)
- Pain after injury with deformity/inability to bear weight
- Morning stiffness >1 hour (inflammatory arthritis)
- Fever with joint pain
- Multiple joints affected symmetrically`,
      urgency: "routine"
    },
    
    // Skin issues
    skin: {
      condition: "Skin Rash / Skin Problem (त्वचा की समस्या / चकत्ते)",
      keywords: ["rash", "skin", "itch", "allergy", "hives", "eczema", "acne", "pimple", "khujli", "daad"],
      advice: `**General Care:**
1. 🧼 **Gentle Cleansing**: Mild soap, lukewarm water, pat dry
2. 🧴 **Moisturize**: Fragrance-free moisturizer 2-3x/day
3. 🚫 **Avoid Irritants**: Harsh soaps, detergents, tight synthetic clothing
4. 🧊 **Cool Compresses**: For itching - calamine lotion or aloe vera gel
5. 💊 **Antihistamine**: Cetirizine 10mg or Loratadine 10mg for allergic itching

**⚠️ Red Flags - Seek Care:**
- Rapidly spreading rash, especially with fever
- Blisters, pus, increasing pain/redness (infection)
- Difficulty breathing, facial swelling (allergic reaction)
- Purple spots that don't blanch (petechiae)
- Rash with joint pain, eye involvement`,
      urgency: "routine"
    },
    
    // Urinary issues
    urinary: {
      condition: "Urinary Problem (मूत्र संबंधी समस्या)",
      keywords: ["urine", "urination", "pee", "burning urine", "frequency", "uti", "mutra", "peshab"],
      advice: `**Care:**
1. 💧 **Hydration**: 3-4L water daily - flush bacteria
2. 🧃 **Cranberry/Barley Water**: May help prevent UTI recurrence
3. 🚽 **Don't Hold**: Urinate when urge arises
4. 🧼 **Hygiene**: Front-to-back wiping, cotton underwear
5. 💊 **Symptomatic**: Flavoxate 200mg for urgency/frequency

**⚠️ Red Flags - Consult Doctor:**
- Burning urination >2 days
- Blood in urine, flank/back pain, fever
- Inability to urinate (retention - EMERGENCY)
- Pregnancy with urinary symptoms`,
      urgency: "routine"
    }
  };

  // Match symptoms in order of priority (emergency first)
  const priorityOrder = [
    "chest_pain", "breathing", // Emergency first
    "fever", "headache", "cough", "abdominal_pain", "nausea", 
    "fatigue", "joint_pain", "skin", "urinary"
  ];

  for (const key of priorityOrder) {
    const symptom = symptoms[key];
    if (symptom.keywords.some(kw => qLower.includes(kw))) {
      return `Condition: ${symptom.condition}

Health Advice & Remedies:
${symptom.advice}

**Next Steps:** ${symptom.urgency === "emergency" ? "🚨 SEEK EMERGENCY CARE IMMEDIATELY" : "Monitor symptoms. Consult a doctor if symptoms persist >2-3 days or worsen."}

---
*Disclaimer: This is AI-generated general health information, not a medical diagnosis. Always consult a qualified healthcare professional for proper evaluation and treatment.*`;
    }
  }

  // Generic medical symptom fallback
  return `These symptoms can occur with several conditions. For an accurate assessment, please consult a qualified healthcare professional.

**General Guidance:**
1. 📝 **Track Symptoms**: Note when they started, triggers, severity (1-10), what helps/worsens
2. 💧 **Stay Hydrated**: Water, electrolytes
3. 🛌 **Rest Adequately**: Sleep 7-9 hours
4. 🏥 **Consult Doctor**: If symptoms persist >2-3 days, worsen, or new symptoms appear

**⚠️ Seek Immediate Care for:** Chest pain, difficulty breathing, severe abdominal pain, high fever (>103°F), confusion, fainting, uncontrolled bleeding.

---
*Disclaimer: This is AI-generated general health information, not a medical diagnosis. Always consult a qualified healthcare professional for proper evaluation and treatment.*`;
}

module.exports = { queryAi, generateSymptomAnalysisFallback };
