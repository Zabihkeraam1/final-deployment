require('dotenv').config();
const express = require('express');
const cors = require('cors');

const app = express();
const port = process.env.PORT || 8080;

// Configure CORS options
const corsOptions = {
  origin: process.env.FRONTEND_DOMAIN, // Fixed typo (was FRONTEND_DOMAIN)
  optionsSuccessStatus: 200 // some legacy browsers (IE11, various SmartTVs) choke on 204
};

// Middleware
app.use(cors(corsOptions));

// Routes
app.get('/api', (req, res) => {
  res.json({ message: 'Hello from the backend!' });
});

app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

app.get('/', (req, res) => {
  res.json({ 
    message: '🚀 Deployment Successful again and again!',
    status: 'running',
    timestamp: new Date().toISOString()
  });
});

// Start server
app.listen(port, '0.0.0.0', () => {
  console.log(`Server running at http://0.0.0.0:${port}`);
  console.log(`Allowed frontend domain: ${process.env.FRONTEND_DOMAIN}`);
});
