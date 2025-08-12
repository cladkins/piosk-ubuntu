let piosk = {
  addNewUrl () {
    let newUrl = $('#new-url').val()
    if (!newUrl) return

    piosk.appendUrl(newUrl)
    $('#new-url').val('')
  },
  appendUrl (url) {
    let tmpUrl = $('#template-url').contents().clone()

    $(tmpUrl).find('a').attr('href', url).html(url)
    $('#urls .list-group').append(tmpUrl)
  },
  renderPage (data) {
    $.each(data.urls, (index, item) => {
      piosk.appendUrl(item.url)
    })
  },
  showStatus (xhr) {
    let message = xhr.responseText || xhr.message || 'Action completed';
    let type = xhr.status && xhr.status >= 400 ? 'danger' : 'success';
    piosk.showAlert(message, type);
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
}

$(document).ready(() => {
  $.getJSON('/config')
  .done(piosk.renderPage)
  .fail(piosk.showStatus)

  $('#add-url').on('click', piosk.addNewUrl)
  $('#new-url').on('keyup', (e) => { if (e.key === 'Enter') piosk.addNewUrl() })

  $('#urls').on('click', 'button.btn-close', (e) => {
    $(e.target).parent().remove()
  })

  $('#execute').on('click', (e) => {
    let config = {}
    config.urls = []
    $('li.list-group-item').each((index, item) => {
      config.urls.push({ url: $(item).find('a').attr('href') })
    })

    $.ajax({
      url: '/config',
      type: 'POST',
      data: JSON.stringify(config),
      contentType: "application/json; charset=utf-8",
      dataType: "json",
      success: piosk.showStatus,
      error: piosk.showStatus
    })
  })

  // System check button
  $('#system-check').on('click', () => {
    $.getJSON('/system/check')
      .done((data) => {
        let message = 'System Check Results:\n\n'
        data.checks.forEach(check => {
          if (check.installed !== undefined) {
            const status = check.installed ? '✓ Installed' : '✗ Not installed'
            const details = check.path || check.details || check.value || ''
            message += `${check.name}: ${status} ${details}\n`
          } else {
            message += `${check.name}: ${check.value}\n`
          }
        })
        piosk.showAlert(`<pre>${message}</pre>`, 'info')
      })
      .fail((xhr) => {
        piosk.showAlert('Failed to check system status: ' + (xhr.responseText || xhr.statusText), 'danger')
      })
  })

  // Mode control buttons
  $('#start-single').on('click', () => {
    $.ajax({
      url: '/single-screen/start',
      type: 'POST',
      success: (data) => piosk.showStatus({ responseText: data.message }),
      error: piosk.showStatus
    })
  })

  $('#stop-single').on('click', () => {
    $.ajax({
      url: '/single-screen/stop',
      type: 'POST',
      success: (data) => piosk.showStatus({ responseText: data.message }),
      error: piosk.showStatus
    })
  })
})
