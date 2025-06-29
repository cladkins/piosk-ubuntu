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
  // Read current config to check if switcher enabled status changed
  let currentConfig = {}
  try {
    if (nfs.existsSync('./config.json')) {
      currentConfig = JSON.parse(nfs.readFileSync('./config.json', 'utf8'))
    }
  } catch (err) {
    console.error('Error reading current config:', err)
  }

  const newConfig = req.body
  const oldSwitcherEnabled = currentConfig.switcher?.enabled !== false
  const newSwitcherEnabled = newConfig.switcher?.enabled !== false

  // Save the new configuration
  nfs.writeFile('./config.json', JSON.stringify(newConfig, null, "  "), err => {
    if (err) {
      console.error(err)
      res.status(500).send('Could not save config.')
      return
    }

    // If switcher enabled status changed, update the service
    if (oldSwitcherEnabled !== newSwitcherEnabled) {
      console.log(`Switcher enabled status changed from ${oldSwitcherEnabled} to ${newSwitcherEnabled}`)
      
      if (newSwitcherEnabled) {
        // Enable and start the switcher service
        exe('systemctl --user enable piosk-switcher', (err, stdout, stderr) => {
          if (err) {
            console.error('Error enabling switcher service:', stderr)
          } else {
            console.log('Switcher service enabled')
            // Start the service
            exe('systemctl --user start piosk-switcher', (err, stdout, stderr) => {
              if (err) {
                console.error('Error starting switcher service:', stderr)
              } else {
                console.log('Switcher service started')
              }
            })
          }
        })
      } else {
        // Stop and disable the switcher service
        exe('systemctl --user stop piosk-switcher', (err, stdout, stderr) => {
          if (err) {
            console.error('Error stopping switcher service:', stderr)
          } else {
            console.log('Switcher service stopped')
            // Disable the service
            exe('systemctl --user disable piosk-switcher', (err, stdout, stderr) => {
              if (err) {
                console.error('Error disabling switcher service:', stderr)
              } else {
                console.log('Switcher service disabled')
              }
            })
          }
        })
      }
    }

    res.status(200).send('Settings saved. Please reboot the system to apply changes.')
  })
})

// Switcher control endpoints
app.get('/switcher/status', (req, res) => {
  // First check if switcher is enabled in configuration
  let configEnabled = true
  try {
    if (nfs.existsSync('./config.json')) {
      const config = JSON.parse(nfs.readFileSync('./config.json', 'utf8'))
      configEnabled = config.switcher?.enabled !== false
    }
  } catch (err) {
    console.error('Error reading config for status:', err)
  }

  // If switcher is disabled in config, return inactive status
  if (!configEnabled) {
    res.json({ status: 'inactive', reason: 'disabled_in_config' })
    return
  }

  // Check service status
  exe('systemctl --user is-active piosk-switcher', (err, stdout, stderr) => {
    if (err) {
      res.json({ status: 'inactive', reason: 'service_not_running', error: stderr })
    } else {
      res.json({ status: stdout.trim() })
    }
  })
})

app.post('/switcher/start', (req, res) => {
  // Check if switcher is enabled in configuration
  let configEnabled = true
  try {
    if (nfs.existsSync('./config.json')) {
      const config = JSON.parse(nfs.readFileSync('./config.json', 'utf8'))
      configEnabled = config.switcher?.enabled !== false
    }
  } catch (err) {
    console.error('Error reading config for start:', err)
  }

  if (!configEnabled) {
    res.status(400).json({ error: 'Switcher is disabled in configuration. Enable it first in the configuration.' })
    return
  }

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
  // Check if switcher is enabled in configuration
  let configEnabled = true
  try {
    if (nfs.existsSync('./config.json')) {
      const config = JSON.parse(nfs.readFileSync('./config.json', 'utf8'))
      configEnabled = config.switcher?.enabled !== false
    }
  } catch (err) {
    console.error('Error reading config for restart:', err)
  }

  if (!configEnabled) {
    res.status(400).json({ error: 'Switcher is disabled in configuration. Enable it first in the configuration.' })
    return
  }

  exe('systemctl --user restart piosk-switcher', (err, stdout, stderr) => {
    if (err) {
      res.status(500).json({ error: 'Failed to restart switcher', details: stderr })
    } else {
      res.json({ message: 'Switcher restarted successfully' })
    }
  })
})

app.listen(3000, console.error)
