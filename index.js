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
  nfs.writeFile('./config.json', JSON.stringify(req.body, null, "  "), err => {
    if (err) {
      console.error(err)
      res.status(500).send('Could not save config.')
    }
    exe('reboot', err => {
      if (err) {
        console.error(err)
        res.status(500).send('Could not reboot to apply config. Retry or reboot manually.')
      }
      res.status(200).send('New config applied; rebooting for changes to take effect...')
    })
  })
})

// Switcher control endpoints
app.get('/switcher/status', (req, res) => {
  // Get the current user from the process
  const user = process.env.SUDO_USER || process.env.USER || 'ubuntu'
  exe(`sudo -u ${user} systemctl --user is-active piosk-switcher`, (err, stdout, stderr) => {
    if (err) {
      res.json({ status: 'inactive', error: stderr })
    } else {
      res.json({ status: stdout.trim() })
    }
  })
})

app.post('/switcher/start', (req, res) => {
  const user = process.env.SUDO_USER || process.env.USER || 'ubuntu'
  exe(`sudo -u ${user} systemctl --user start piosk-switcher`, (err, stdout, stderr) => {
    if (err) {
      res.status(500).json({ error: 'Failed to start switcher', details: stderr })
    } else {
      res.json({ message: 'Switcher started successfully' })
    }
  })
})

app.post('/switcher/stop', (req, res) => {
  const user = process.env.SUDO_USER || process.env.USER || 'ubuntu'
  exe(`sudo -u ${user} systemctl --user stop piosk-switcher`, (err, stdout, stderr) => {
    if (err) {
      res.status(500).json({ error: 'Failed to stop switcher', details: stderr })
    } else {
      res.json({ message: 'Switcher stopped successfully' })
    }
  })
})

app.post('/switcher/restart', (req, res) => {
  const user = process.env.SUDO_USER || process.env.USER || 'ubuntu'
  exe(`sudo -u ${user} systemctl --user restart piosk-switcher`, (err, stdout, stderr) => {
    if (err) {
      res.status(500).json({ error: 'Failed to restart switcher', details: stderr })
    } else {
      res.json({ message: 'Switcher restarted successfully' })
    }
  })
})

app.listen(3000, console.error)
