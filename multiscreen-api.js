// Multi-screen API endpoints - add to existing Express app
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');

// Use /opt/piosk if it exists (installed system), otherwise use local directory
const BASE_DIR = require('fs').existsSync('/opt/piosk') ? '/opt/piosk' : __dirname;
const SCREEN_DIR = path.join(BASE_DIR, 'screens');

// Ensure screen directory exists
if (!fs.existsSync(SCREEN_DIR)) {
    fs.mkdirSync(SCREEN_DIR, { recursive: true });
}

function addMultiScreenRoutes(app) {
    // Detect displays
    app.get('/multiscreen/detect', (req, res) => {
        exec(`DISPLAY=:0 ${path.join(BASE_DIR, 'scripts', 'detect-displays.sh')}`, (error, stdout, stderr) => {
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
            
            const command = `DISPLAY=${display} XAUTHORITY=\${XAUTHORITY:-$HOME/.Xauthority} nohup snap run chromium --start-fullscreen --start-maximized --kiosk --disable-infobars --disable-extensions --disable-plugins --disable-translate --disable-default-apps --disable-notifications --disable-popup-blocking --disable-prompt-on-repost --disable-hang-monitor --disable-features=TranslateUI --disable-ipc-flooding-protection --no-first-run --no-default-browser-check --disable-background-timer-throttling --disable-renderer-backgrounding --disable-backgrounding-occluded-windows --disable-features=VizDisplayCompositor --autoplay-policy=no-user-gesture-required --remote-debugging-port=${port} --user-data-dir=/tmp/piosk-${display} ${urls} > /tmp/piosk-${display}.log 2>&1 & echo $! > /tmp/piosk-${display}.pid`;
            
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
        console.log(`${new Date().toISOString()}: Starting multi-screen mode requested`);
        console.log(`${new Date().toISOString()}: BASE_DIR: ${BASE_DIR}`);
        
        const scriptPath = path.join(BASE_DIR, 'scripts', 'runner-multiscreen.sh');
        console.log(`${new Date().toISOString()}: Script path: ${scriptPath}`);
        console.log(`${new Date().toISOString()}: Script exists: ${require('fs').existsSync(scriptPath)}`);
        
        // Save the current mode state
        fs.writeFile(path.join(BASE_DIR, 'last-mode.txt'), 'multi-screen', () => {})
        
        // First stop single-screen mode and switcher to avoid conflicts
        exec('pkill -f "chromium.*remote-debugging-port" && systemctl --user stop piosk-switcher 2>/dev/null || true', (error1) => {
            console.log(`${new Date().toISOString()}: Cleanup completed, starting multi-screen script`);
            
            // Now start multi-screen mode
            exec(scriptPath, (error, stdout, stderr) => {
                console.log(`${new Date().toISOString()}: Multi-screen script execution completed`);
                console.log(`${new Date().toISOString()}: Error:`, error);
                console.log(`${new Date().toISOString()}: Stdout:`, stdout);
                console.log(`${new Date().toISOString()}: Stderr:`, stderr);
                
                if (error) {
                    const errorDetails = `Error: ${error.message}, Stdout: ${stdout}, Stderr: ${stderr}`;
                    console.log(`${new Date().toISOString()}: Multi-screen start failed: ${errorDetails}`);
                    res.status(500).json({ error: 'Failed to start multi-screen mode', details: errorDetails });
                } else {
                    console.log(`${new Date().toISOString()}: Multi-screen mode started successfully`);
                    res.json({ message: 'Multi-screen mode started successfully' });
                }
            });
        });
    });

    // Stop all screens
    app.post('/multiscreen/stop-all', (req, res) => {
        exec('pkill -f "chromium.*remote-debugging-port"', (error, stdout, stderr) => {
            // Clean up PID files
            exec('rm -f /tmp/piosk-*.pid', () => {
                res.json({ message: 'All screens stopped' });
            });
        });
    });
}

module.exports = { addMultiScreenRoutes };