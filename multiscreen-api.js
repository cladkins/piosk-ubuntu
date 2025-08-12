// Multi-screen API endpoints - add to existing Express app
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');

const SCREEN_DIR = path.join(__dirname, 'screens');

// Ensure screen directory exists
if (!fs.existsSync(SCREEN_DIR)) {
    fs.mkdirSync(SCREEN_DIR, { recursive: true });
}

function addMultiScreenRoutes(app) {
    // Detect displays
    app.get('/multiscreen/detect', (req, res) => {
        exec(`DISPLAY=:0 ${path.join(__dirname, 'scripts', 'detect-displays.sh')}`, (error, stdout, stderr) => {
            if (error) {
                console.error('Display detection error:', error);
                res.json({ displays: [':0'] }); // fallback
                return;
            }
            
            const displays = stdout.trim().split(/\s+/).filter(d => d.trim());
            res.json({ displays: displays.length > 0 ? displays : [':0'] });
        });
    });

    // Get screen configuration
    app.get('/multiscreen/config/:display', (req, res) => {
        const display = req.params.display;
        const configFile = path.join(SCREEN_DIR, `${display}.json`);
        
        if (fs.existsSync(configFile)) {
            try {
                const config = JSON.parse(fs.readFileSync(configFile, 'utf8'));
                res.json(config);
            } catch (error) {
                res.status(500).json({ error: 'Failed to read config' });
            }
        } else {
            // Return default config
            res.json({
                urls: [
                    { url: 'https://time.is' },
                    { url: 'https://weather.com' }
                ]
            });
        }
    });

    // Save screen configuration
    app.post('/multiscreen/config/:display', (req, res) => {
        const display = req.params.display;
        const configFile = path.join(SCREEN_DIR, `${display}.json`);
        
        try {
            fs.writeFileSync(configFile, JSON.stringify(req.body, null, 2));
            res.json({ message: 'Configuration saved' });
        } catch (error) {
            res.status(500).json({ error: 'Failed to save config' });
        }
    });

    // Start specific screen
    app.post('/multiscreen/start/:display', (req, res) => {
        const display = req.params.display;
        const configFile = path.join(SCREEN_DIR, `${display}.json`);
        
        // Ensure config exists
        if (!fs.existsSync(configFile)) {
            const defaultConfig = {
                urls: [
                    { url: 'https://time.is' },
                    { url: 'https://weather.com' }
                ]
            };
            fs.writeFileSync(configFile, JSON.stringify(defaultConfig, null, 2));
        }
        
        // Read URLs from config
        try {
            const config = JSON.parse(fs.readFileSync(configFile, 'utf8'));
            const urls = config.urls.map(u => u.url).join(' ');
            const port = 9222 + Math.floor(Math.random() * 100);
            
            const command = `DISPLAY=${display} nohup snap run chromium --kiosk --remote-debugging-port=${port} --user-data-dir=/tmp/piosk-${display} ${urls} > /tmp/piosk-${display}.log 2>&1 & echo $! > /tmp/piosk-${display}.pid`;
            
            exec(command, (error, stdout, stderr) => {
                if (error) {
                    res.status(500).json({ error: 'Failed to start screen', details: error.message });
                } else {
                    res.json({ message: `Screen ${display} started` });
                }
            });
        } catch (error) {
            res.status(500).json({ error: 'Failed to read config' });
        }
    });

    // Stop specific screen
    app.post('/multiscreen/stop/:display', (req, res) => {
        const display = req.params.display;
        const pidFile = `/tmp/piosk-${display}.pid`;
        
        if (fs.existsSync(pidFile)) {
            try {
                const pid = fs.readFileSync(pidFile, 'utf8').trim();
                exec(`kill ${pid}`, (error) => {
                    fs.unlinkSync(pidFile);
                    if (error) {
                        res.json({ message: `Screen ${display} process killed (may have already been stopped)` });
                    } else {
                        res.json({ message: `Screen ${display} stopped` });
                    }
                });
            } catch (error) {
                res.json({ message: `Screen ${display} was not running` });
            }
        } else {
            res.json({ message: `Screen ${display} was not running` });
        }
    });

    // Start all screens (multi-screen mode)
    app.post('/multiscreen/start-all', (req, res) => {
        // First stop single-screen mode and switcher to avoid conflicts
        exec('pkill -f "chromium.*kiosk" && systemctl --user stop piosk-switcher 2>/dev/null || true', (error1) => {
            // Now start multi-screen mode
            exec(path.join(__dirname, 'scripts', 'runner-multiscreen.sh'), (error, stdout, stderr) => {
                if (error) {
                    res.status(500).json({ error: 'Failed to start multi-screen mode', details: error.message });
                } else {
                    res.json({ message: 'Multi-screen mode started successfully' });
                }
            });
        });
    });

    // Stop all screens
    app.post('/multiscreen/stop-all', (req, res) => {
        exec('pkill -f "chromium.*kiosk"', (error, stdout, stderr) => {
            // Clean up PID files
            exec('rm -f /tmp/piosk-*.pid', () => {
                res.json({ message: 'All screens stopped' });
            });
        });
    });
}

module.exports = { addMultiScreenRoutes };