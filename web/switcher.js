let switcher = {
  config: {},
  
  // Initialize the page
  init() {
    this.loadConfig();
    this.loadStatus();
    this.bindEvents();
  },
  
  // Load current configuration
  loadConfig() {
    fetch('/config')
      .then(response => response.json())
      .then(data => {
        this.config = data;
        this.updateForm();
        this.updateConfigDisplay();
      })
      .catch(error => {
        console.error('Error loading config:', error);
        this.showAlert('Error loading configuration', 'danger');
      });
  },
  
  // Load switcher status
  loadStatus() {
    fetch('/switcher/status')
      .then(response => response.json())
      .then(data => {
        this.updateStatus(data);
      })
      .catch(error => {
        console.error('Error loading status:', error);
        this.updateStatus({ status: 'error', error: error.message });
      });
  },
  
  // Update the form with current values
  updateForm() {
    const switcherConfig = this.config.switcher || {};
    
    document.getElementById('switcher-enabled').checked = switcherConfig.enabled !== false;
    document.getElementById('switcher-interval').value = switcherConfig.interval || 10;
    document.getElementById('switcher-refresh').value = switcherConfig.refresh_cycle || 10;
  },
  
  // Update status display
  updateStatus(data) {
    const statusBadge = document.getElementById('status-badge');
    const statusText = document.getElementById('status-text');
    const startBtn = document.getElementById('start-btn');
    const stopBtn = document.getElementById('stop-btn');
    const restartBtn = document.getElementById('restart-btn');
    
    if (data.status === 'active') {
      statusBadge.className = 'badge bg-success me-2';
      statusBadge.textContent = 'Active';
      statusText.textContent = 'Switcher is running';
      startBtn.disabled = true;
      stopBtn.disabled = false;
      restartBtn.disabled = false;
    } else if (data.status === 'inactive') {
      statusBadge.className = 'badge bg-danger me-2';
      statusBadge.textContent = 'Inactive';
      statusText.textContent = 'Switcher is stopped';
      startBtn.disabled = false;
      stopBtn.disabled = true;
      restartBtn.disabled = false;
    } else {
      statusBadge.className = 'badge bg-secondary me-2';
      statusBadge.textContent = 'Unknown';
      statusText.textContent = `Unable to determine status (${data.status})`;
      startBtn.disabled = false;
      stopBtn.disabled = false;
      restartBtn.disabled = false;
    }
  },
  
  // Update configuration display
  updateConfigDisplay() {
    const display = document.getElementById('config-display');
    display.textContent = JSON.stringify(this.config, null, 2);
  },
  
  // Bind event listeners
  bindEvents() {
    // Control buttons
    document.getElementById('start-btn').addEventListener('click', () => this.startSwitcher());
    document.getElementById('stop-btn').addEventListener('click', () => this.stopSwitcher());
    document.getElementById('restart-btn').addEventListener('click', () => this.restartSwitcher());
    
    // Action buttons
    document.getElementById('apply-settings-btn').addEventListener('click', () => this.applySettings());
    document.getElementById('refresh-status-btn').addEventListener('click', () => this.loadStatus());
  },
  
  // Start switcher
  startSwitcher() {
    fetch('/switcher/start', { method: 'POST' })
      .then(response => response.json())
      .then(data => {
        if (data.error) {
          this.showAlert('Failed to start switcher: ' + data.error, 'danger');
        } else {
          this.showAlert('Switcher started successfully', 'success');
          setTimeout(() => this.loadStatus(), 1000);
        }
      })
      .catch(error => {
        this.showAlert('Error starting switcher: ' + error.message, 'danger');
      });
  },
  
  // Stop switcher
  stopSwitcher() {
    fetch('/switcher/stop', { method: 'POST' })
      .then(response => response.json())
      .then(data => {
        if (data.error) {
          this.showAlert('Failed to stop switcher: ' + data.error, 'danger');
        } else {
          this.showAlert('Switcher stopped successfully', 'success');
          setTimeout(() => this.loadStatus(), 1000);
        }
      })
      .catch(error => {
        this.showAlert('Error stopping switcher: ' + error.message, 'danger');
      });
  },
  
  // Restart switcher
  restartSwitcher() {
    fetch('/switcher/restart', { method: 'POST' })
      .then(response => response.json())
      .then(data => {
        if (data.error) {
          this.showAlert('Failed to restart switcher: ' + data.error, 'danger');
        } else {
          this.showAlert('Switcher restarted successfully', 'success');
          setTimeout(() => this.loadStatus(), 1000);
        }
      })
      .catch(error => {
        this.showAlert('Error restarting switcher: ' + error.message, 'danger');
      });
  },
  
  // Apply settings
  applySettings() {
    // Get form values
    const enabled = document.getElementById('switcher-enabled').checked;
    const interval = parseInt(document.getElementById('switcher-interval').value);
    const refresh = parseInt(document.getElementById('switcher-refresh').value);
    
    // Validate inputs
    if (interval < 1 || interval > 300) {
      this.showAlert('Switch interval must be between 1 and 300 seconds', 'warning');
      return;
    }
    
    if (refresh < 1 || refresh > 50) {
      this.showAlert('Refresh cycle must be between 1 and 50', 'warning');
      return;
    }
    
    // Update configuration
    this.config.switcher = {
      enabled: enabled,
      interval: interval,
      refresh_cycle: refresh
    };
    
    // Save configuration
    fetch('/config', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(this.config)
    })
      .then(response => {
        if (response.ok) {
          this.showAlert('Settings applied successfully. System will reboot to apply changes.', 'success');
          this.updateConfigDisplay();
        } else {
          return response.text().then(text => {
            throw new Error(text);
          });
        }
      })
      .catch(error => {
        this.showAlert('Error applying settings: ' + error.message, 'danger');
      });
  },
  
  // Show alert message
  showAlert(message, type) {
    const container = document.getElementById('alert-container');
    const alert = document.createElement('div');
    alert.className = `alert alert-${type} alert-dismissible fade show`;
    alert.innerHTML = `
      ${message}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    
    container.appendChild(alert);
    
    // Auto-remove after 5 seconds
    setTimeout(() => {
      if (alert.parentNode) {
        alert.remove();
      }
    }, 5000);
  }
};

// Initialize when page loads
document.addEventListener('DOMContentLoaded', () => {
  switcher.init();
}); 