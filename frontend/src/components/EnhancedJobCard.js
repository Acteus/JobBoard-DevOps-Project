import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { MapPin, DollarSign, Calendar, Building, Star, Bookmark, Share2, MoreVertical } from 'lucide-react';

const EnhancedJobCard = ({ job, onBookmark, onShare }) => {
  const [isBookmarked, setIsBookmarked] = useState(false);
  const [showActions, setShowActions] = useState(false);

  const handleBookmark = (e) => {
    e.stopPropagation();
    setIsBookmarked(!isBookmarked);
    if (onBookmark) {
      onBookmark(job.id, !isBookmarked);
    }
  };

  const handleShare = (e) => {
    e.stopPropagation();
    if (onShare) {
      onShare(job);
    }
  };

  const formatSalary = (salary) => {
    if (!salary) return 'N/A';
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 2,
    }).format(salary);
  };

  const formatDate = (dateString) => {
    if (!dateString) return 'No date';
    const date = new Date(dateString);
    const now = new Date();
    const diffTime = Math.abs(now - date);
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    if (diffDays === 1) return '1 day ago';
    if (diffDays < 7) return `${diffDays} days ago`;
    if (diffDays < 30) return `${Math.ceil(diffDays / 7)} weeks ago`;
    return date.toLocaleDateString();
  };

  const getSalaryColor = (salary) => {
    if (salary >= 20) return '#27ae60'; // High salary
    if (salary >= 15) return '#f39c12'; // Medium salary
    return '#95a5a6'; // Lower salary
  };

  return (
    <div className="enhanced-job-card">
      <div className="job-card-header">
        <div className="job-title-section">
          <h3 className="job-title">{job.title}</h3>
          <div className="job-employer">
            <Building size={16} />
            <span>{job.employer}</span>
          </div>
        </div>

        <div className="job-actions">
          <button
            className={`action-btn bookmark-btn ${isBookmarked ? 'bookmarked' : ''}`}
            onClick={handleBookmark}
            title={isBookmarked ? 'Remove bookmark' : 'Bookmark job'}
          >
            <Bookmark size={18} fill={isBookmarked ? '#3498db' : 'none'} />
          </button>

          <button
            className="action-btn share-btn"
            onClick={handleShare}
            title="Share job"
          >
            <Share2 size={18} />
          </button>

          <button
            className="action-btn more-btn"
            onClick={() => setShowActions(!showActions)}
            title="More options"
          >
            <MoreVertical size={18} />
          </button>
        </div>
      </div>

      <div className="job-card-body">
        <div className="job-details-grid">
          <div className="job-detail-item">
            <MapPin size={16} className="detail-icon" />
            <span className="detail-text">{job.location}</span>
          </div>

          <div className="job-detail-item">
            <DollarSign size={16} className="detail-icon" />
            <span
              className="detail-text salary-text"
              style={{ color: getSalaryColor(job.salary) }}
            >
              {formatSalary(job.salary)}/hour
            </span>
          </div>

          <div className="job-detail-item">
            <Calendar size={16} className="detail-icon" />
            <span className="detail-text">{formatDate(job.posted_date)}</span>
          </div>
        </div>

        {job.description && (
          <div className="job-description">
            <p>{job.description}</p>
          </div>
        )}

        <div className="job-card-footer">
          <div className="job-tags">
            <span className="job-tag">Full-time</span>
            <span className="job-tag">Entry Level</span>
          </div>

          <div className="job-rating">
            {[1, 2, 3, 4, 5].map((star) => (
              <Star
                key={star}
                size={14}
                className="rating-star"
                fill={star <= 4 ? '#ffd700' : 'none'}
              />
            ))}
            <span className="rating-text">(4.0)</span>
          </div>
        </div>
      </div>

      {showActions && (
        <div className="job-actions-dropdown">
          <button className="dropdown-item">Report Job</button>
          <button className="dropdown-item">Hide Job</button>
          <button className="dropdown-item">Similar Jobs</button>
        </div>
      )}
    </div>
  );
};

EnhancedJobCard.propTypes = {
  job: PropTypes.shape({
    id: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
    title: PropTypes.string.isRequired,
    employer: PropTypes.string.isRequired,
    location: PropTypes.string.isRequired,
    salary: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
    description: PropTypes.string,
    posted_date: PropTypes.string.isRequired,
  }).isRequired,
  onBookmark: PropTypes.func,
  onShare: PropTypes.func,
};

export default EnhancedJobCard;