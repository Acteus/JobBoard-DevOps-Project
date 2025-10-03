import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import axios from 'axios';
import { Activity, Wifi, WifiOff, TrendingUp, Users, DollarSign, MapPin } from 'lucide-react';

const SystemStatus = ({ jobs }) => {
  const [apiStatus, setApiStatus] = useState('checking');
  const [dbStatus, setDbStatus] = useState('checking');
  const [lastUpdated, setLastUpdated] = useState(new Date());

  useEffect(() => {
    checkSystemStatus();
    const interval = setInterval(checkSystemStatus, 30000); // Check every 30 seconds
    return () => clearInterval(interval);
  }, []);

  const checkSystemStatus = async () => {
    try {
      // Check API health
      const response = await axios.get('/health', { timeout: 5000 });
      setApiStatus(response.status === 200 ? 'online' : 'offline');
    } catch (error) {
      setApiStatus('offline');
    }

    // Check database connectivity (try to fetch jobs)
    try {
      await axios.get('/api/jobs', { timeout: 5000 });
      setDbStatus('connected');
    } catch (error) {
      setDbStatus('disconnected');
    }

    setLastUpdated(new Date());
  };

  const getStatusColor = (status) => {
    switch (status) {
    case 'online':
    case 'connected':
      return '#27ae60';
    case 'offline':
    case 'disconnected':
      return '#e74c3c';
    default:
      return '#f39c12';
    }
  };

  const getStatusIcon = (status) => {
    switch (status) {
    case 'online':
    case 'connected':
      return <Wifi size={16} />;
    case 'offline':
    case 'disconnected':
      return <WifiOff size={16} />;
    default:
      return <Activity size={16} className="animate-pulse" />;
    }
  };

  // Calculate job statistics
  const totalJobs = jobs.length;
  const validJobs = jobs.filter(job => job.salary && !isNaN(parseFloat(job.salary)));
  const avgSalary = totalJobs > 0 && validJobs.length > 0
    ? (validJobs.reduce((sum, job) => sum + parseFloat(job.salary), 0) / validJobs.length).toFixed(2)
    : '0.00';
  const locations = [...new Set(jobs.map(job => job.location))].length;
  const recentJobs = jobs.filter(job => {
    const jobDate = new Date(job.posted_date);
    const weekAgo = new Date();
    weekAgo.setDate(weekAgo.getDate() - 7);
    return jobDate >= weekAgo;
  }).length;

  return (
    <div className="system-status">
      <div className="status-header">
        <h3>System Status</h3>
        <span className="last-updated">
          Last updated: {lastUpdated.toLocaleTimeString()}
        </span>
      </div>

      <div className="status-grid">
        <div className="status-item">
          <div className="status-icon" style={{ color: getStatusColor(apiStatus) }}>
            {getStatusIcon(apiStatus)}
          </div>
          <div className="status-info">
            <span className="status-label">API Status</span>
            <span className={`status-value ${apiStatus}`}>
              {apiStatus.charAt(0).toUpperCase() + apiStatus.slice(1)}
            </span>
          </div>
        </div>

        <div className="status-item">
          <div className="status-icon" style={{ color: getStatusColor(dbStatus) }}>
            {getStatusIcon(dbStatus)}
          </div>
          <div className="status-info">
            <span className="status-label">Database</span>
            <span className={`status-value ${dbStatus}`}>
              {dbStatus.charAt(0).toUpperCase() + dbStatus.slice(1)}
            </span>
          </div>
        </div>

        <div className="status-item">
          <div className="status-icon" style={{ color: '#3498db' }}>
            <Users size={16} />
          </div>
          <div className="status-info">
            <span className="status-label">Total Jobs</span>
            <span className="status-value">{totalJobs}</span>
          </div>
        </div>

        <div className="status-item">
          <div className="status-icon" style={{ color: '#2ecc71' }}>
            <TrendingUp size={16} />
          </div>
          <div className="status-info">
            <span className="status-label">This Week</span>
            <span className="status-value">{recentJobs}</span>
          </div>
        </div>

        <div className="status-item">
          <div className="status-icon" style={{ color: '#f39c12' }}>
            <DollarSign size={16} />
          </div>
          <div className="status-info">
            <span className="status-label">Avg Salary</span>
            <span className="status-value">${avgSalary}/hr</span>
          </div>
        </div>

        <div className="status-item">
          <div className="status-icon" style={{ color: '#9b59b6' }}>
            <MapPin size={16} />
          </div>
          <div className="status-info">
            <span className="status-label">Locations</span>
            <span className="status-value">{locations}</span>
          </div>
        </div>
      </div>
    </div>
  );
};

SystemStatus.propTypes = {
  jobs: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
      title: PropTypes.string.isRequired,
      employer: PropTypes.string.isRequired,
      location: PropTypes.string.isRequired,
      salary: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
      description: PropTypes.string.isRequired,
      posted_date: PropTypes.string.isRequired,
    })
  ).isRequired,
};

export default SystemStatus;