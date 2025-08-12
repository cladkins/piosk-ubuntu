const exp = require('express')
const exe = require('child_process').exec
const nfs = require('fs')
const path = require('path')

const app = exp()

app.use(exp.static('web'))
app.use(exp.json())

app.get('/config', (req, res) => {
  res.sendFile(path.join(__dirname, 'config.json'))
})

app.post('/config', (req, res) => {
  // Save the new configuration
  nfs.writeFile(path.join(__dirname, 'config.json'), JSON.stringify(req.body, null, "  "), err => {
    if (err) {
      console.error(err)
      res.status(500).send('Could not save config.')
      return
    }

    res.status(200).send('Settings saved. The switcher service will be updated on the next login or reboot.')
  })
})

// Switcher control endpoints
app.get('/switcher/status', (req, res) => {
  // Check if switcher service is enabled and running
  exe('systemctl --user is-active piosk-switcher', (err, stdout, stderr) => {
    if (err) {
      // Service is not running, check if it's enabled
      exe('systemctl --user is-enabled piosk-switcher', (err2, stdout2, stderr2) => {
        if (err2) {
          res.json({ status: 'inactive', reason: 'service_disabled' })
        } else {
          res.json({ status: 'inactive', reason: 'service_not_running' })
        }
      })
    } else {
      res.json({ status: stdout.trim() })
    }
  })
})

app.post('/switcher/start', (req, res) => {
  exe('systemctl --user start piosk-switcher', (err, stdout, stderr) => {
    if (err) {
      res.status(500).json({ error: 'Failed to start switcher', details: stderr })
    } else {
      res.json({ message: 'Switcher started successfully' })
    }
  })
})

app.post('/switcher/stop', (req, res) => {
  exe('systemctl --user stop piosk-switcher', (err, stdout, stderr) => {
    if (err) {
      res.status(500).json({ error: 'Failed to stop switcher', details: stderr })
    } else {
      res.json({ message: 'Switcher stopped successfully' })
    }
  })
})

app.post('/switcher/restart', (req, res) => {
  exe('systemctl --user restart piosk-switcher', (err, stdout, stderr) => {
    if (err) {
      res.status(500).json({ error: 'Failed to restart switcher', details: stderr })
    } else {
      res.json({ message: 'Switcher restarted successfully' })
    }
  })
})

// System check endpoint
app.get('/system/check', (req, res) => {
  const checks = []
  let completed = 0
  const total = 4
  
  const checkComplete = () => {
    completed++
    if (completed === total) {
      res.json({ checks })
    }
  }
  
  exe('command -v snap', (err1, stdout1) => {
    checks.push({ name: 'snap', installed: !err1, path: err1 ? 'Not found' : stdout1.trim() })
    checkComplete()
  })
  
  exe('snap list chromium', (err2, stdout2) => {
    checks.push({ name: 'chromium', installed: !err2, details: err2 ? 'Not installed' : 'Installed' })
    checkComplete()
  })
  
  exe('command -v jq', (err3, stdout3) => {
    checks.push({ name: 'jq', installed: !err3, path: err3 ? 'Not found' : stdout3.trim() })
    checkComplete()
  })
  
  exe('echo $DISPLAY', (err4, stdout4) => {
    checks.push({ name: 'DISPLAY', value: stdout4.trim() || 'Not set' })
    checkComplete()
  })
})

// Single-screen mode control
app.post('/single-screen/start', (req, res) => {
  // Stop multi-screen mode first
  exe('pkill -f "chromium.*kiosk" 2>/dev/null || true', (err1) => {
    // Start single-screen mode
    exe(`${path.join(__dirname, 'scripts', 'runner.sh')} > /tmp/piosk-single.log 2>&1 &`, (err, stdout, stderr) => {
      if (err) {
        res.status(500).json({ error: 'Failed to start single-screen mode', details: stderr || 'Check /tmp/piosk-single.log for details' })
      } else {
        res.json({ message: 'Single-screen mode started successfully' })
      }
    })
  })
})

app.post('/single-screen/stop', (req, res) => {
  exe('pkill -f "chromium.*kiosk" 2>/dev/null || true', (err, stdout, stderr) => {
    res.json({ message: 'Single-screen mode stopped' })
  })
})

// Add multi-screen functionality
try {
  const { addMultiScreenRoutes } = require('./multiscreen-api')
  addMultiScreenRoutes(app)
  console.log('Multi-screen functionality loaded')
} catch (error) {
  console.log('Multi-screen functionality not available:', error.message)
}

app.listen(3000, console.error)
