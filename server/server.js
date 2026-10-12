require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { GoogleGenAI } = require('@google/genai');

const app = express();
app.use(cors());
app.use(express.json());

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY.trim() });

app.post('/api/chat', async (req, res) => {
  try {
    const { message } = req.body;

    if (!message) {
      return res.status(400).json({ error: 'Message is required' });
    }

    console.log(`[Processing Request]: "${message}"`);

    const response = await ai.models.generateContent({
      model: 'gemini-3.6-flash',
      contents: message,
      config: {
        systemInstruction:
          "You are Rx PharmAssist, a helpful, friendly, and knowledgeable AI pharmacy assistant. Provide informative answers about medications while maintaining professional accuracy.",
      },
    });

    return res.status(200).json({ reply: response.text });
  } catch (error) {
    console.error('================ SERVER ERROR ================');
    console.error(error);
    console.error('==============================================');

    return res.status(500).json({
      error: 'Internal Server Error',
      details: error.message || error.toString(),
    });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on http://0.0.0.0:${PORT}`);
});