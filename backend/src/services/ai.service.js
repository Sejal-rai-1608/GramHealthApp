const axios = require('axios');
// const logger = require('../utils/logger'); // assuming they have a logger, else console

const GRAM_AI_URL = process.env.GRAM_AI_URL || 'http://localhost:8000';

class AiService {
  async queryAgent(query, patientId) {
    try {
      const response = await axios.post(`${GRAM_AI_URL}/agent/query`, {
        query,
        patient_id: patientId
      }, {
        timeout: 15000 // 15 seconds timeout
      });

      return response.data;
    } catch (error) {
      console.error(`Error communicating with AI service (queryAgent):`, error.message);
      if (error.response) {
        throw new Error(`AI Service Error: ${error.response.data.detail || error.message}`);
      }
      throw new Error(`AI Service Unavailable: ${error.message}`);
    }
  }

  async syncPatientRecord(patientId, recordId, recordType, recordDate, text, source) {
    if (!patientId || !text) {
      console.warn('syncPatientRecord: missing patientId or text, skipping.');
      return;
    }

    try {
      const record = {
        patient_id: patientId,
        record_id: recordId,
        record_type: recordType,
        record_date: recordDate instanceof Date ? recordDate.toISOString().split('T')[0] : recordDate,
        text,
        source
      };

      const response = await axios.post(`${GRAM_AI_URL}/patient/ingest`, [record], {
        timeout: 10000
      });

      return response.data;
    } catch (error) {
      console.error(`Error communicating with AI service (syncPatientRecord):`, error.message);
      // We don't throw here to avoid failing the primary business logic (e.g. creating consultation)
    }
  }
}

module.exports = new AiService();
