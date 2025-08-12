const exp = require('express')
const exe = require('child_process').exec
const nfs = require('fs')

const app = exp()

app.use(exp.static('web'))
app.use(exp.json())

app.get('/config', (req, res) => {
  res.sendFile(__dirname + '/config.json')
})

app.post('/config', (req, res) => {
  // Save the new configuration
  nfs.writeFile('./config.json', JSON.stringify(req.body, null, "  "), err => {
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

// Add multi-screen functionality
try {
  const { addMultiScreenRoutes } = require('./multiscreen-api')
  addMultiScreenRoutes(app)
  console.log('Multi-screen functionality loaded')
} catch (error) {
  console.log('Multi-screen functionality not available:', error.message)
}

app.listen(3000, console.error)
