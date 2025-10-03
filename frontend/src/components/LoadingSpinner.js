import React from 'react';
import PropTypes from 'prop-types';

const LoadingSpinner = ({ size = 'medium', message = 'Loading...' }) => {
  const getSizeClass = () => {
    switch (size) {
    case 'small':
      return 'spinner-small';
    case 'large':
      return 'spinner-large';
    default:
      return 'spinner-medium';
    }
  };

  return (
    <div className={`loading-spinner ${getSizeClass()}`}>
      <div className="spinner"></div>
      {message && <p className="loading-message">{message}</p>}
    </div>
  );
};

LoadingSpinner.propTypes = {
  size: PropTypes.oneOf(['small', 'medium', 'large']),
  message: PropTypes.string,
};

export default LoadingSpinner;