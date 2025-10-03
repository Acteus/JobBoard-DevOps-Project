import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

// Configure axios to use backend server
axios.defaults.baseURL = 'http://localhost:3001';

// Import new components
import SystemStatus from './components/SystemStatus';
import SearchFilter from './components/SearchFilter';
import AnalyticsDashboard from './components/AnalyticsDashboard';
import EnhancedJobCard from './components/EnhancedJobCard';
import LoadingSpinner from './components/LoadingSpinner';
import Notification from './components/Notification';

function App() {
  const [jobs, setJobs] = useState([]);
  const [filteredJobs, setFilteredJobs] = useState([]);
  const [showForm, setShowForm] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [notification, setNotification] = useState(null);
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

  useEffect(() => {
    setFilteredJobs(jobs);
  }, [jobs]);

  const fetchJobs = async () => {
    setIsLoading(true);
    try {
      const response = await axios.get('/api/jobs');
      setJobs(response.data);
      showNotification('success', `Loaded ${response.data.length} jobs successfully`);
    } catch (error) {
      console.error('Error fetching jobs:', error);
      // For demo purposes, use mock data if API is not available
      const mockJobs = [
        {
          id: 1,
          title: 'Cashier',
          employer: 'Local Grocery Store',
          location: 'Downtown',
          salary: 15.00,
          description: 'Part-time cashier position with customer service focus',
          posted_date: '2024-01-15'
        },
        {
          id: 2,
          title: 'Cook',
          employer: 'Fast Food Restaurant',
          location: 'Mall Area',
          salary: 16.50,
          description: 'Line cook position with flexible hours and team environment',
          posted_date: '2024-01-14'
        },
        {
          id: 3,
          title: 'Barista',
          employer: 'Coffee Shop Chain',
          location: 'Business District',
          salary: 17.25,
          description: 'Experienced barista needed for busy coffee shop location',
          posted_date: '2024-01-13'
        },
        {
          id: 4,
          title: 'Sales Associate',
          employer: 'Retail Store',
          location: 'Shopping Center',
          salary: 14.75,
          description: 'Retail sales position with commission opportunities',
          posted_date: '2024-01-12'
        }
      ];
      setJobs(mockJobs);
      showNotification('info', 'Using demo data - API not available');
    } finally {
      setIsLoading(false);
    }
  };

  const showNotification = (type, message) => {
    setNotification({ type, message });
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
      showNotification('success', 'Job posted successfully!');
    } catch (error) {
      console.error('Error creating job:', error);
      showNotification('error', 'Error creating job posting');
    }
  };

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  const handleFilterChange = (filters) => {
    let filtered = [...jobs];

    // Apply search filter
    if (filters.search) {
      filtered = filtered.filter(job =>
        job.title.toLowerCase().includes(filters.search.toLowerCase()) ||
        job.employer.toLowerCase().includes(filters.search.toLowerCase()) ||
        job.description.toLowerCase().includes(filters.search.toLowerCase())
      );
    }

    // Apply location filter
    if (filters.location) {
      filtered = filtered.filter(job => job.location === filters.location);
    }

    // Apply salary range filter
    if (filters.salaryMin) {
      filtered = filtered.filter(job => job.salary >= parseFloat(filters.salaryMin));
    }
    if (filters.salaryMax) {
      filtered = filtered.filter(job => job.salary <= parseFloat(filters.salaryMax));
    }

    // Apply sorting
    switch (filters.sortBy) {
      case 'salary-high':
        filtered.sort((a, b) => b.salary - a.salary);
        break;
      case 'salary-low':
        filtered.sort((a, b) => a.salary - b.salary);
        break;
      case 'title':
        filtered.sort((a, b) => a.title.localeCompare(b.title));
        break;
      case 'date':
      default:
        filtered.sort((a, b) => new Date(b.posted_date) - new Date(a.posted_date));
        break;
    }

    setFilteredJobs(filtered);
  };

  const handleBookmark = (jobId, bookmarked) => {
    showNotification('info', bookmarked ? 'Job bookmarked!' : 'Bookmark removed');
  };

  const handleShare = (job) => {
    if (navigator.share) {
      navigator.share({
        title: job.title,
        text: `Check out this ${job.title} position at ${job.employer}`,
        url: window.location.href,
      });
    } else {
      // Fallback for browsers that don't support Web Share API
      navigator.clipboard.writeText(`${job.title} at ${job.employer} - ${window.location.href}`);
      showNotification('success', 'Job link copied to clipboard!');
    }
  };

  return (
    <div className="App">
      {/* Notification */}
      {notification && (
        <Notification
          type={notification.type}
          message={notification.message}
          onClose={() => setNotification(null)}
        />
      )}

      {/* Header */}
      <header className="App-header">
        <div className="header-content">
          <div className="header-text">
            <h1>Job Board</h1>
            <p>Find minimum wage jobs in your city</p>
          </div>
          <button
            className="post-job-btn"
            onClick={() => setShowForm(!showForm)}
          >
            {showForm ? 'Cancel' : 'Post a Job'}
          </button>
        </div>
      </header>

      {/* System Status */}
      <SystemStatus jobs={jobs} />

      {/* Job Posting Form */}
      {showForm && (
        <div className="job-form-container">
          <h2>Post a New Job</h2>
          <form onSubmit={handleSubmit} className="job-form">
            <div className="form-row">
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
            </div>
            <div className="form-row">
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
            </div>
            <div className="form-group">
              <label>Description:</label>
              <textarea
                name="description"
                value={formData.description}
                onChange={handleChange}
                rows="4"
                placeholder="Describe the job responsibilities, requirements, and benefits..."
              />
            </div>
            <button type="submit" className="submit-btn">Post Job</button>
          </form>
        </div>
      )}

      {/* Search and Filter */}
      <SearchFilter jobs={jobs} onFilterChange={handleFilterChange} />

      {/* Analytics Dashboard */}
      <AnalyticsDashboard jobs={jobs} />

      {/* Jobs Section */}
      <div className="jobs-container">
        <div className="jobs-header">
          <h2>Available Jobs</h2>
          <p className="jobs-count">
            {isLoading ? (
              <LoadingSpinner size="small" message="" />
            ) : (
              `${filteredJobs.length} job${filteredJobs.length !== 1 ? 's' : ''} found`
            )}
          </p>
        </div>

        {isLoading ? (
          <LoadingSpinner size="large" message="Loading jobs..." />
        ) : (
          <div className="jobs-list">
            {filteredJobs.length > 0 ? (
              filteredJobs.map(job => (
                <EnhancedJobCard
                  key={job.id}
                  job={job}
                  onBookmark={handleBookmark}
                  onShare={handleShare}
                />
              ))
            ) : (
              <div className="no-jobs">
                <p>No jobs found matching your criteria.</p>
                <button
                  className="clear-filters-btn"
                  onClick={() => setFilteredJobs(jobs)}
                >
                  Show All Jobs
                </button>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

export default App;