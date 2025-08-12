let multiscreen = {
    displays: [],

    init() {
        document.getElementById('startMulti').addEventListener('click', () => this.startMultiScreen());
        document.getElementById('stopMulti').addEventListener('click', () => this.stopMultiScreen());
        document.getElementById('detectDisplays').addEventListener('click', () => this.detectDisplays());
    },

    async detectDisplays() {
        try {
            const response = await fetch('/multiscreen/detect');
            const data = await response.json();
            this.displays = data.displays || [];
            this.renderDisplays();
            this.renderConfigs();
        } catch (error) {
            console.error('Error detecting displays:', error);
            this.showAlert('Failed to detect displays', 'danger');
        }
    },

    renderDisplays() {
        const displayList = document.getElementById('displayList');
        if (this.displays.length === 0) {
            displayList.innerHTML = '<p class="text-muted">No displays detected</p>';
            return;
        }

        const html = this.displays.map(display => 
            `<span class="badge bg-primary me-1">${display}</span>`
        ).join('');
        displayList.innerHTML = html;
    },

    renderConfigs() {
        const container = document.getElementById('screenConfigs');
        if (this.displays.length === 0) {
            container.innerHTML = '<p class="text-muted">Detect displays first to configure screens</p>';
            return;
        }

        const html = this.displays.map((display, index) => `
            <div class="card mb-3">
                <div class="card-header">
                    <h6 class="mb-0">
                        <span class="badge bg-primary me-2">${display}</span>
                        Display ${index + 1} ${index === 0 ? '(Primary)' : '(Secondary)'}
                    </h6>
                </div>
                <div class="card-body">
                    <div class="row">
                        <div class="col-md-8">
                            <label for="urls-${display}" class="form-label">Web Pages (one per line):</label>
                            <textarea class="form-control" id="urls-${display}" rows="3" 
                                      placeholder="Enter URLs (one per line)">https://time.is
https://weather.com</textarea>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">Controls:</label>
                            <div class="d-grid gap-2">
                                <button type="button" class="btn btn-primary" onclick="multiscreen.saveScreen('${display}')">Save Configuration</button>
                                <div class="btn-group w-100" role="group">
                                    <button type="button" class="btn btn-success" onclick="multiscreen.startScreen('${display}')">Start</button>
                                    <button type="button" class="btn btn-danger" onclick="multiscreen.stopScreen('${display}')">Stop</button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        `).join('');
        
        container.innerHTML = html;
    },

    async saveScreen(display) {
        const urlsText = document.getElementById(`urls-${display}`).value;
        const urls = urlsText.split('\n').filter(url => url.trim()).map(url => ({ url: url.trim() }));
        
        try {
            const response = await fetch(`/multiscreen/config/${display}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ urls })
            });
            
            if (response.ok) {
                this.showAlert(`Configuration saved for ${display}`, 'success');
            } else {
                throw new Error('Save failed');
            }
        } catch (error) {
            console.error('Error saving screen config:', error);
            this.showAlert(`Failed to save configuration for ${display}`, 'danger');
        }
    },

    async startScreen(display) {
        try {
            const response = await fetch(`/multiscreen/start/${display}`, { method: 'POST' });
            if (response.ok) {
                this.showAlert(`Started screen ${display}`, 'success');
            } else {
                throw new Error('Start failed');
            }
        } catch (error) {
            console.error('Error starting screen:', error);
            this.showAlert(`Failed to start screen ${display}`, 'danger');
        }
    },

    async stopScreen(display) {
        try {
            const response = await fetch(`/multiscreen/stop/${display}`, { method: 'POST' });
            if (response.ok) {
                this.showAlert(`Stopped screen ${display}`, 'success');
            } else {
                throw new Error('Stop failed');
            }
        } catch (error) {
            console.error('Error stopping screen:', error);
            this.showAlert(`Failed to stop screen ${display}`, 'danger');
        }
    },

    async startMultiScreen() {
        try {
            const response = await fetch('/multiscreen/start-all', { method: 'POST' });
            const data = await response.json();
            
            if (response.ok) {
                this.showAlert(data.message || 'Multi-screen mode started', 'success');
            } else {
                throw new Error(data.error || 'Start failed');
            }
        } catch (error) {
            console.error('Error starting multi-screen:', error);
            this.showAlert('Failed to start multi-screen mode: ' + error.message, 'danger');
        }
    },

    async stopMultiScreen() {
        try {
            const response = await fetch('/multiscreen/stop-all', { method: 'POST' });
            if (response.ok) {
                this.showAlert('All screens stopped', 'success');
            } else {
                throw new Error('Stop failed');
            }
        } catch (error) {
            console.error('Error stopping screens:', error);
            this.showAlert('Failed to stop screens', 'danger');
        }
    },

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
document.addEventListener('DOMContentLoaded', () => multiscreen.init());