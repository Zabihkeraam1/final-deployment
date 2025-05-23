require('dotenv').config();
const express = require('express');
const cors = require('cors');
const pool = require('./dbconnection');
const app = express();
const port = process.env.PORT || 8080;

// Middleware
app.use(cors({
    origin: "*",
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true
  }));

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
    timestamp: new Date().toISOString(),
    origin: process.env.FRONTEND_DOMAIN
  });
});


app.get('/data', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW() as current_time');
    res.json({Date: result.rows[0], message: "I come from datagase!"});
  } catch (err) {
    console.error(err);
    res.status(500).send('Server error');
  }
});
// Start server
app.listen(port, '0.0.0.0', () => {
  console.log(`Server running at http://0.0.0.0:${port}`);
  console.log(`Allowed frontend domain: ${process.env.FRONTEND_DOMAIN}`);
});
