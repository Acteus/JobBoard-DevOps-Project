import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import { Search, Filter, X, MapPin, DollarSign } from 'lucide-react';

const SearchFilter = ({ jobs, onFilterChange }) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedLocation, setSelectedLocation] = useState('');
  const [salaryRange, setSalaryRange] = useState({ min: '', max: '' });
  const [sortBy, setSortBy] = useState('date');
  const [showFilters, setShowFilters] = useState(false);
  const [suggestions, setSuggestions] = useState([]);

  // Get unique locations for filter dropdown
  const locations = [...new Set(jobs.map(job => job.location).filter(Boolean))];

  // Generate search suggestions based on job titles and employers
  useEffect(() => {
    if (searchTerm.length > 0) {
      const matches = jobs
        .filter(job =>
          job.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
          job.employer.toLowerCase().includes(searchTerm.toLowerCase())
        )
        .slice(0, 5);
      setSuggestions(matches);
    } else {
      setSuggestions([]);
    }
  }, [searchTerm, jobs]);

  const handleSearchChange = (e) => {
    setSearchTerm(e.target.value);
  };

  const handleLocationChange = (e) => {
    setSelectedLocation(e.target.value);
  };

  const handleSalaryChange = (type, value) => {
    setSalaryRange(prev => ({
      ...prev,
      [type]: value
    }));
  };

  const clearFilters = () => {
    setSearchTerm('');
    setSelectedLocation('');
    setSalaryRange({ min: '', max: '' });
    setSortBy('date');
  };

  const applyFilters = () => {
    const filters = {
      search: searchTerm,
      location: selectedLocation,
      salaryMin: salaryRange.min,
      salaryMax: salaryRange.max,
      sortBy
    };
    onFilterChange(filters);
    setShowFilters(false);
  };

  const selectSuggestion = (job) => {
    setSearchTerm(job.title);
    setSuggestions([]);
  };

  const activeFiltersCount = [
    searchTerm,
    selectedLocation,
    salaryRange.min,
    salaryRange.max
  ].filter(Boolean).length;

  return (
    <div className="search-filter">
      <div className="search-bar">
        <div className="search-input-container">
          <Search size={20} className="search-icon" />
          <input
            type="text"
            placeholder="Search jobs, employers..."
            value={searchTerm}
            onChange={handleSearchChange}
            className="search-input"
          />
          {searchTerm && (
            <button
              className="clear-search"
              onClick={() => setSearchTerm('')}
            >
              <X size={16} />
            </button>
          )}
        </div>

        <div className="search-controls">
          <button
            className={`filter-toggle ${showFilters ? 'active' : ''}`}
            onClick={() => setShowFilters(!showFilters)}
          >
            <Filter size={20} />
            {activeFiltersCount > 0 && (
              <span className="filter-badge">{activeFiltersCount}</span>
            )}
          </button>

          <select
            value={sortBy}
            onChange={(e) => setSortBy(e.target.value)}
            className="sort-select"
          >
            <option value="date">Newest First</option>
            <option value="salary-high">Highest Salary</option>
            <option value="salary-low">Lowest Salary</option>
            <option value="title">Job Title A-Z</option>
          </select>
        </div>
      </div>

      {/* Search Suggestions */}
      {suggestions.length > 0 && (
        <div className="search-suggestions">
          {suggestions.map(job => (
            <div
              key={job.id}
              className="suggestion-item"
              onClick={() => selectSuggestion(job)}
            >
              <div className="suggestion-title">{job.title}</div>
              <div className="suggestion-employer">{job.employer}</div>
            </div>
          ))}
        </div>
      )}

      {/* Advanced Filters */}
      {showFilters && (
        <div className="advanced-filters">
          <div className="filter-section">
            <h4>Location</h4>
            <div className="location-filter">
              <MapPin size={16} />
              <select
                value={selectedLocation}
                onChange={handleLocationChange}
                className="location-select"
              >
                <option value="">All Locations</option>
                {locations.map(location => (
                  <option key={location} value={location}>{location}</option>
                ))}
              </select>
            </div>
          </div>

          <div className="filter-section">
            <h4>Salary Range</h4>
            <div className="salary-filter">
              <DollarSign size={16} />
              <input
                type="number"
                placeholder="Min"
                value={salaryRange.min}
                onChange={(e) => handleSalaryChange('min', e.target.value)}
                className="salary-input"
              />
              <span className="salary-separator">-</span>
              <input
                type="number"
                placeholder="Max"
                value={salaryRange.max}
                onChange={(e) => handleSalaryChange('max', e.target.value)}
                className="salary-input"
              />
            </div>
          </div>

          <div className="filter-actions">
            <button className="clear-filters-btn" onClick={clearFilters}>
              Clear All
            </button>
            <button className="apply-filters-btn" onClick={applyFilters}>
              Apply Filters
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

SearchFilter.propTypes = {
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
  onFilterChange: PropTypes.func.isRequired,
};

export default SearchFilter;