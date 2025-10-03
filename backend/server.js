const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());

// Database connection
let db;
let dbConnected = false;

async function connectDB() {
  try {
    db = await mysql.createConnection({
      host: process.env.DB_HOST,
      user: process.env.DB_USER,
      password: process.env.DB_PASS,
      database: process.env.DB_NAME
    });
    dbConnected = true;
    console.log('Connected to MySQL database');
    return true;
  } catch (error) {
    console.error('Database connection failed:', error.message);
    dbConnected = false;
    console.log('Running in demo mode without database');
    return false;
  }
}

// Initialize database connection and wait for it
async function initializeDatabase() {
  const maxRetries = 5;
  const retryDelay = 2000; // 2 seconds

  for (let i = 0; i < maxRetries; i++) {
    console.log(`Attempting database connection (attempt ${i + 1}/${maxRetries})...`);
    const connected = await connectDB();
    if (connected) {
      return true;
    }

    if (i < maxRetries - 1) {
      console.log(`Retrying in ${retryDelay/1000} seconds...`);
      await new Promise(resolve => setTimeout(resolve, retryDelay));
    }
  }

  console.log('Failed to connect to database after all retries');
  return false;
}

// Import routes
const jobsRouter = require('./routes/jobs');

// Initialize database connection and wait for it
initializeDatabase().then((connected) => {
  // Pass database connection to routes after DB initialization
  jobsRouter.connectDB(db);

  // Routes
  app.use('/api/jobs', jobsRouter.router);

  // Health check endpoint
  app.get('/health', (req, res) => {
    res.json({
      status: 'OK',
      timestamp: new Date().toISOString(),
      database: connected ? 'connected' : 'demo mode'
    });
  });

  // Error handling middleware
  app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Something went wrong!' });
  });

  // 404 handler
  app.use('*', (req, res) => {
    res.status(404).json({ error: 'Route not found' });
  });

  // Start server after database initialization
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
    console.log(`Database status: ${connected ? 'Connected' : 'Demo mode'}`);
  });
});

module.exports = app;