import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

function App() {
  const [jobs, setJobs] = useState([]);
  const [showForm, setShowForm] = useState(false);
  const [formData, setFormData] = useState({
    title: '',
    employer: '',
    location: '',
    salary: '',
    description: ''
  });

  useEffect(() => {
    fetchJobs();
  }, []);

  const fetchJobs = async () => {
    try {
      const response = await axios.get('/api/jobs');
      setJobs(response.data);
    } catch (error) {
      console.error('Error fetching jobs:', error);
      // For demo purposes, use mock data if API is not available
      setJobs([
        {
          id: 1,
          title: 'Cashier',
          employer: 'Local Grocery Store',
          location: 'Downtown',
          salary: 15.00,
          posted_date: '2024-01-15'
        },
        {
          id: 2,
          title: 'Cook',
          employer: 'Fast Food Restaurant',
          location: 'Mall Area',
          salary: 16.50,
          posted_date: '2024-01-14'
        }
      ]);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const newJob = {
        ...formData,
        salary: parseFloat(formData.salary),
        posted_date: new Date().toISOString().split('T')[0]
      };
      await axios.post('/api/jobs', newJob);
      setFormData({ title: '', employer: '', location: '', salary: '', description: '' });
      setShowForm(false);
      fetchJobs();
    } catch (error) {
      console.error('Error creating job:', error);
      alert('Error creating job posting');
    }
  };

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>Job Board</h1>
        <p>Find minimum wage jobs in your city</p>
        <button 
          className="post-job-btn"
          onClick={() => setShowForm(!showForm)}
        >
          {showForm ? 'Cancel' : 'Post a Job'}
        </button>
      </header>

      {showForm && (
        <div className="job-form-container">
          <h2>Post a New Job</h2>
          <form onSubmit={handleSubmit} className="job-form">
            <div className="form-group">
              <label>Job Title:</label>
              <input
                type="text"
                name="title"
                value={formData.title}
                onChange={handleChange}
                required
              />
            </div>
            <div className="form-group">
              <label>Employer:</label>
              <input
                type="text"
                name="employer"
                value={formData.employer}
                onChange={handleChange}
                required
              />
            </div>
            <div className="form-group">
              <label>Location:</label>
              <input
                type="text"
                name="location"
                value={formData.location}
                onChange={handleChange}
                required
              />
            </div>
            <div className="form-group">
              <label>Salary ($/hour):</label>
              <input
                type="number"
                step="0.01"
                name="salary"
                value={formData.salary}
                onChange={handleChange}
                required
              />
            </div>
            <div className="form-group">
              <label>Description:</label>
              <textarea
                name="description"
                value={formData.description}
                onChange={handleChange}
                rows="4"
              />
            </div>
            <button type="submit" className="submit-btn">Post Job</button>
          </form>
        </div>
      )}

      <div className="jobs-container">
        <h2>Available Jobs</h2>
        <div className="jobs-list">
          {jobs.map(job => (
            <div key={job.id} className="job-card">
              <h3>{job.title}</h3>
              <p className="employer">{job.employer}</p>
              <p className="location">📍 {job.location}</p>
              <p className="salary">${job.salary}/hour</p>
              <p className="date">Posted: {job.posted_date}</p>
              {job.description && <p className="description">{job.description}</p>}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

export default App;