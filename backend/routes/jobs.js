const express = require('express');
const router = express.Router();

// Database connection (will be passed from server.js)
let db;

// Initialize database connection
const connectDB = async (database) => {
  db = database;
};

// GET /api/jobs - Get all jobs
router.get('/', async (req, res) => {
  try {
    if (db) {
      const [rows] = await db.execute('SELECT * FROM jobs ORDER BY posted_date DESC');
      res.json(rows);
    } else {
      // Mock data for demo
      res.json([
        {
          id: 1,
          title: 'Cashier',
          employer: 'Local Grocery Store',
          location: 'Downtown',
          salary: 15.00,
          description: 'Part-time cashier position',
          posted_date: '2024-01-15'
        },
        {
          id: 2,
          title: 'Cook',
          employer: 'Fast Food Restaurant',
          location: 'Mall Area',
          salary: 16.50,
          description: 'Line cook position with flexible hours',
          posted_date: '2024-01-14'
        }
      ]);
    }
  } catch (error) {
    console.error('Error fetching jobs:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/jobs - Create a new job
router.post('/', async (req, res) => {
  try {
    const { title, employer, location, salary, description } = req.body;
    
    if (!title || !employer || !location || !salary) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    if (db) {
      const [result] = await db.execute(
        'INSERT INTO jobs (title, employer, location, salary, description, posted_date) VALUES (?, ?, ?, ?, ?, CURDATE())',
        [title, employer, location, salary, description]
      );
      res.status(201).json({ id: result.insertId, message: 'Job created successfully' });
    } else {
      // Mock response for demo
      res.status(201).json({ 
        id: Date.now(),
        message: 'Job created successfully (demo mode)' 
      });
    }
  } catch (error) {
    console.error('Error creating job:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /api/jobs/:id - Get a specific job
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    if (db) {
      const [rows] = await db.execute('SELECT * FROM jobs WHERE id = ?', [id]);
      if (rows.length === 0) {
        return res.status(404).json({ error: 'Job not found' });
      }
      res.json(rows[0]);
    } else {
      // Mock response for demo
      if (id == 1 || id == 2) {
        res.json({
          id: parseInt(id),
          title: 'Sample Job',
          employer: 'Sample Employer',
          location: 'Sample Location',
          salary: 15.00,
          description: 'Sample job description',
          posted_date: '2024-01-15'
        });
      } else {
        res.status(404).json({ error: 'Job not found' });
      }
    }
  } catch (error) {
    console.error('Error fetching job:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// PUT /api/jobs/:id - Update a job
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { title, employer, location, salary, description } = req.body;
    
    if (!title || !employer || !location || !salary) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    if (db) {
      const [result] = await db.execute(
        'UPDATE jobs SET title = ?, employer = ?, location = ?, salary = ?, description = ? WHERE id = ?',
        [title, employer, location, salary, description, id]
      );
      
      if (result.affectedRows === 0) {
        return res.status(404).json({ error: 'Job not found' });
      }
      
      res.json({ message: 'Job updated successfully' });
    } else {
      // Mock response for demo
      res.json({ message: 'Job updated successfully (demo mode)' });
    }
  } catch (error) {
    console.error('Error updating job:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// DELETE /api/jobs/:id - Delete a job
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    if (db) {
      const [result] = await db.execute('DELETE FROM jobs WHERE id = ?', [id]);
      
      if (result.affectedRows === 0) {
        return res.status(404).json({ error: 'Job not found' });
      }
      
      res.json({ message: 'Job deleted successfully' });
    } else {
      // Mock response for demo
      res.json({ message: 'Job deleted successfully (demo mode)' });
    }
  } catch (error) {
    console.error('Error deleting job:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = { router, connectDB };