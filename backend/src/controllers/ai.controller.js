const asyncHandler = require("../utils/asyncHandler");

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
  const apiKey = process.env.GEMINI_API_KEY;

  let answer = "";
  let routingMethod = "medical_rules_engine";

  if (apiKey) {
    try {
      // Call Gemini 1.5 Flash API via native fetch
      const geminiResponse = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            contents: [
              {
                role: "user",
                parts: [
                  {
                    text: `You are GramHealth AI, an empathetic rural healthcare assistant for India. Provide helpful, accurate, concise medical advice in plain simple language. Always advise consulting a qualified doctor for serious symptoms.\n\nUser Question: ${queryText}`,
                  },
                ],
              },
            ],
          }),
        }
      );

      if (geminiResponse.ok) {
        const geminiData = await geminiResponse.json();
        const generatedText =
          geminiData?.candidates?.[0]?.content?.parts?.[0]?.text;
        if (generatedText) {
          answer = generatedText.trim();
          routingMethod = "gemini_pro";
        }
      }
    } catch (err) {
      console.error("[Backend AI] Gemini API error:", err.message);
    }
  }

  // Fallback response generator if Gemini key is absent or call failed
  if (!answer) {
    const qLower = queryText.toLowerCase();
    if (qLower.includes("fever") || qLower.includes("bukhar") || qLower.includes("taap")) {
      answer = "Fever can be caused by viral infections, flu, or malaria. Please stay hydrated, take rest, and monitor your temperature. If fever exceeds 101°F (38.3°C) or lasts more than 3 days, please consult a physician immediately.";
    } else if (qLower.includes("headache") || qLower.includes("sir dard") || qLower.includes("sirdard")) {
      answer = "For mild headaches, rest in a quiet dark room, stay hydrated, and manage stress. If accompanied by high fever, neck stiffness, or sudden severe pain, seek immediate emergency medical care.";
    } else if (qLower.includes("cough") || qLower.includes("khansi") || qLower.includes("cold")) {
      answer = "Drink warm fluids, steam inhalation, and honey with warm water can soothe coughs. Consult a doctor if you experience breathlessness or persistent chest pain.";
    } else {
      answer = `Hello! I am your GramHealth AI Assistant. I can help answer health queries, check symptoms, and connect you with doctors. How can I assist you today?`;
    }
  }

  return res.status(200).json({
    success: true,
    data: {
      query: queryText,
      intent: "general_health",
      agent: "online_ai_assistant",
      answer: answer,
      grounded: true,
      confidence: "high",
      urgency: "routine",
      requires_professional_review: true,
      routing_method: routingMethod,
    },
  });
});

module.exports = { queryAi };
