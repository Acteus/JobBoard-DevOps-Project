import React, { useMemo } from 'react';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend,
  ArcElement,
  PointElement,
  LineElement,
} from 'chart.js';
import { Bar, Doughnut, Line } from 'react-chartjs-2';
import { TrendingUp, MapPin, DollarSign } from 'lucide-react';

ChartJS.register(
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend,
  ArcElement,
  PointElement,
  LineElement
);

const AnalyticsDashboard = ({ jobs }) => {
  // Calculate analytics data
  const analytics = useMemo(() => {
    if (!jobs.length) return null;

    // Filter jobs with valid salary data
    const validJobs = jobs.filter(job => {
      const salary = job.salary;
      const parsedSalary = parseFloat(salary);
      const isValid = salary && !isNaN(parsedSalary) && isFinite(parsedSalary);
      console.log(`Job ${job.id}: salary="${salary}", parsed=${parsedSalary}, valid=${isValid}`);
      return isValid;
    });

    console.log(`Total jobs: ${jobs.length}, Valid jobs: ${validJobs.length}`);

    // Salary distribution
    const salaryRanges = {
      'Under $15': validJobs.filter(job => parseFloat(job.salary) < 15).length,
      '$15-$18': validJobs.filter(job => parseFloat(job.salary) >= 15 && parseFloat(job.salary) < 18).length,
      '$18-$20': validJobs.filter(job => parseFloat(job.salary) >= 18 && parseFloat(job.salary) < 20).length,
      '$20+': validJobs.filter(job => parseFloat(job.salary) >= 20).length,
    };

    // Location distribution
    const locationCounts = jobs.reduce((acc, job) => {
      acc[job.location] = (acc[job.location] || 0) + 1;
      return acc;
    }, {});

    // Jobs posted over time (last 30 days)
    const last30Days = Array.from({ length: 30 }, (_, i) => {
      const date = new Date();
      date.setDate(date.getDate() - (29 - i));
      return date.toISOString().split('T')[0];
    });

    const jobsByDate = last30Days.map(date => {
      return jobs.filter(job => job.posted_date === date).length;
    });

    // Average salary by location
    const avgSalaryByLocation = Object.keys(locationCounts).map(location => {
      const locationJobs = validJobs.filter(job => job.location === location);
      const avgSalary = locationJobs.length > 0
        ? locationJobs.reduce((sum, job) => sum + parseFloat(job.salary), 0) / locationJobs.length
        : 0;
      return { location, average: Math.round(avgSalary * 100) / 100 };
    }).filter(item => item.average > 0).sort((a, b) => b.average - a.average);

    return {
      salaryRanges,
      locationCounts,
      jobsByDate,
      last30Days,
      avgSalaryByLocation,
      totalJobs: jobs.length,
      avgSalary: validJobs.length > 0
        ? (() => {
            const total = validJobs.reduce((sum, job) => {
              const salary = parseFloat(job.salary);
              console.log(`Adding salary ${salary} to sum`);
              return sum + salary;
            }, 0);
            const average = total / validJobs.length;
            console.log(`Total: ${total}, Count: ${validJobs.length}, Average: ${average}`);
            return Math.round(average * 100) / 100;
          })()
        : 0,
    };
  }, [jobs]);

  if (!analytics) {
    return (
      <div className="analytics-dashboard">
        <h3>Job Market Analytics</h3>
        <p className="no-data">No data available for analytics</p>
      </div>
    );
  }

  // Chart configurations
  const salaryChartData = {
    labels: Object.keys(analytics.salaryRanges),
    datasets: [
      {
        label: 'Number of Jobs',
        data: Object.values(analytics.salaryRanges),
        backgroundColor: [
          '#e74c3c',
          '#f39c12',
          '#f1c40f',
          '#27ae60',
        ],
        borderWidth: 0,
      },
    ],
  };

  const locationChartData = {
    labels: Object.keys(analytics.locationCounts),
    datasets: [
      {
        label: 'Jobs by Location',
        data: Object.values(analytics.locationCounts),
        backgroundColor: '#3498db',
        borderColor: '#2980b9',
        borderWidth: 1,
      },
    ],
  };

  const trendsChartData = {
    labels: analytics.last30Days.map(date => new Date(date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })),
    datasets: [
      {
        label: 'Jobs Posted',
        data: analytics.jobsByDate,
        borderColor: '#9b59b6',
        backgroundColor: 'rgba(155, 89, 182, 0.1)',
        tension: 0.4,
      },
    ],
  };

  const chartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        position: 'bottom',
      },
    },
  };

  return (
    <div className="analytics-dashboard">
      <div className="analytics-header">
        <h3>Job Market Analytics</h3>
        <div className="analytics-stats">
          <div className="stat-item">
            <TrendingUp size={20} />
            <span>{analytics.totalJobs} Total Jobs</span>
          </div>
          <div className="stat-item">
            <DollarSign size={20} />
            <span>${analytics.avgSalary} Avg Salary</span>
          </div>
        </div>
      </div>

      <div className="charts-grid">
        <div className="chart-container">
          <div className="chart-header">
            <h4>Salary Distribution</h4>
          </div>
          <div className="chart-content">
            <Doughnut data={salaryChartData} options={chartOptions} />
          </div>
        </div>

        <div className="chart-container">
          <div className="chart-header">
            <h4>Jobs by Location</h4>
          </div>
          <div className="chart-content">
            <Bar data={locationChartData} options={chartOptions} />
          </div>
        </div>

        <div className="chart-container full-width">
          <div className="chart-header">
            <h4>Posting Trends (Last 30 Days)</h4>
          </div>
          <div className="chart-content">
            <Line data={trendsChartData} options={chartOptions} />
          </div>
        </div>

        <div className="chart-container">
          <div className="chart-header">
            <h4>Top Paying Locations</h4>
          </div>
          <div className="chart-content">
            <div className="location-list">
              {analytics.avgSalaryByLocation.slice(0, 5).map((item, index) => (
                <div key={item.location} className="location-item">
                  <span className="location-rank">#{index + 1}</span>
                  <span className="location-name">{item.location}</span>
                  <span className="location-salary">${item.average}/hr</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AnalyticsDashboard;