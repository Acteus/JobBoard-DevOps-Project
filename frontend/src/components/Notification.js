import React, { useEffect } from 'react';
import { CheckCircle, XCircle, AlertCircle, Info, X } from 'lucide-react';

const Notification = ({ type = 'info', message, onClose, autoClose = true, duration = 5000 }) => {
  useEffect(() => {
    if (autoClose && onClose) {
      const timer = setTimeout(onClose, duration);
      return () => clearTimeout(timer);
    }
  }, [autoClose, duration, onClose]);

  const getNotificationIcon = () => {
    switch (type) {
    case 'success':
      return <CheckCircle size={20} />;
    case 'error':
      return <XCircle size={20} />;
    case 'warning':
      return <AlertCircle size={20} />;
    default:
      return <Info size={20} />;
    }
  };

  const getNotificationColor = () => {
    switch (type) {
    case 'success':
      return '#27ae60';
    case 'error':
      return '#e74c3c';
    case 'warning':
      return '#f39c12';
    default:
      return '#3498db';
    }
  };

  if (!message) return null;

  return (
    <div className="notification" style={{ borderLeftColor: getNotificationColor() }}>
      <div className="notification-icon" style={{ color: getNotificationColor() }}>
        {getNotificationIcon()}
      </div>
      <div className="notification-content">
        <p className="notification-message">{message}</p>
      </div>
      {onClose && (
        <button className="notification-close" onClick={onClose}>
          <X size={16} />
        </button>
      )}
    </div>
  );
};

export default Notification;