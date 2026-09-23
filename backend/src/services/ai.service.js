const axios = require('axios');

/**
 * Resolve GRAM_AI_URL based on environment.
 * In production, GRAM_AI_URL must be explicitly provided (e.g. Render Python AI service URL).
 * In development, defaults to local port 8001.
 */
function getGramAiUrl() {
  const isProduction = process.env.NODE_ENV === 'production';
  let url = process.env.GRAM_AI_URL;

  if (!url || !url.trim()) {
    if (isProduction) {
      throw new Error(
        '[AiService] Production configuration error: GRAM_AI_URL environment variable is missing. ' +
        'Set GRAM_AI_URL to the deployed Python AI Render service URL (e.g. https://<python-ai-render>.onrender.com).'
      );
    }
    url = 'http://127.0.0.1:8000';
  }

  // Remove trailing slashes
  return url.trim().replace(/\/+$/, '');
}

/**
 * Returns a sanitized host/path string for logging without query strings or secrets.
 */
function getSafeEndpointLog(baseUrl, path) {
  try {
    const parsed = new URL(baseUrl);
    return `${parsed.protocol}//${parsed.host}${path}`;
  } catch (_) {
    return `${baseUrl}${path}`;
  }
}

class AiService {
  async queryAgent(query, patientId, requestId = 'NO_REQ_ID') {
    const aiBaseUrl = getGramAiUrl();
    const endpointLog = getSafeEndpointLog(aiBaseUrl, '/agent/query');
    const startTime = Date.now();
    const queryLength = query ? query.length : 0;
    const hasPatient = Boolean(patientId);

    console.log(`[Node AI Service] Request ID: ${requestId}`);
    console.log(`[Node AI Service] POST /agent/query`);
    console.log(`[Node AI Service] query length: ${queryLength}`);
    console.log(`[Node AI Service] patient ID presence: ${hasPatient}`);

    console.log(`[AI Service] Calling FastAPI`);
    console.log(`[AI Service] Request ID: ${requestId}`);
    console.log(`[AI Service] Endpoint: ${endpointLog}`);
    console.log(`[AI Service] Query length: ${queryLength}`);

    try {
      const response = await axios.post(
        `${aiBaseUrl}/agent/query`,
        {
          query,
          patient_id: patientId
        },
        {
          headers: {
            'X-Request-ID': requestId,
            'Content-Type': 'application/json'
          },
          timeout: 120000 // 60s to allow for RAG processing & generation
        }
      );

      const durationMs = Date.now() - startTime;
      const data = response.data || {};
      const intent = data.intent || 'unknown';
      const agent = data.agent || 'unknown';
      const answerPresent = Boolean(data.answer && data.answer.trim().length > 0);
      const routingMethod = data.routing_method || 'unknown';

      console.log(`[AI Service] FastAPI status: ${response.status}`);
      console.log(`[AI Service] FastAPI response fields:`);
      console.log(`[AI Service] intent: ${intent}`);
      console.log(`[AI Service] agent: ${agent}`);
      console.log(`[AI Service] answer present: ${answerPresent}`);
      console.log(`[AI Service] routing_method: ${routingMethod}`);
      console.log(`[AiService] POST ${endpointLog} - Status: ${response.status} - Duration: ${durationMs}ms`);

      return response.data;
    } catch (error) {
      const durationMs = Date.now() - startTime;
      const statusCode = error.response ? error.response.status : 503;
      const failureType = error.code || (error.response ? `HTTP_${error.response.status}` : error.name || 'UNKNOWN_ERROR');

      console.error(
        `[AiService] POST ${endpointLog} FAILED - Status: ${statusCode} - FailureType: ${failureType} - Duration: ${durationMs}ms`
      );

      let message = `AI Service Unavailable (${failureType}): ${error.message}`;
      if (error.response && error.response.data) {
        const detail = error.response.data.detail || error.response.data.message;
        if (detail) {
          message = `AI Service Error: ${detail}`;
        }
      }

      const wrappedError = new Error(message);
      wrappedError.statusCode = typeof statusCode === 'number' ? statusCode : 503;
      throw wrappedError;
    }
  }

  async syncPatientRecord(patientId, recordId, recordType, recordDate, text, source) {
    if (!patientId || !text) {
      console.warn('[AiService] syncPatientRecord: missing patientId or text, skipping.');
      return;
    }

    const aiBaseUrl = getGramAiUrl();
    const endpointLog = getSafeEndpointLog(aiBaseUrl, '/patient/ingest');
    const startTime = Date.now();

    try {
      const record = {
        patient_id: patientId,
        record_id: recordId,
        record_type: recordType,
        record_date: recordDate instanceof Date ? recordDate.toISOString().split('T')[0] : recordDate,
        text,
        source
      };

      const response = await axios.post(
        `${aiBaseUrl}/patient/ingest`,
        [record],
        {
          timeout: 20000
        }
      );

      const durationMs = Date.now() - startTime;
      console.log(`[AiService] POST ${endpointLog} - Status: ${response.status} - Duration: ${durationMs}ms`);

      return response.data;
    } catch (error) {
      const durationMs = Date.now() - startTime;
      const statusCode = error.response ? error.response.status : 'NO_RESPONSE';
      const failureType = error.code || (error.response ? `HTTP_${error.response.status}` : error.name || 'UNKNOWN_ERROR');

      console.error(
        `[AiService] POST ${endpointLog} FAILED - Status: ${statusCode} - FailureType: ${failureType} - Duration: ${durationMs}ms`
      );
      // Non-fatal for patient record sync to avoid blocking consultation flow
    }
  }
}

module.exports = new AiService();
