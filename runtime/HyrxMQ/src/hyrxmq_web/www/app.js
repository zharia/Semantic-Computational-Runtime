async function load() {
  // Status
  const s = await fetch('/status');
  const st = await s.json();
  const sdiv = document.getElementById('status');
  sdiv.innerHTML = `
    <strong>Ready:</strong> ${st.ready ? 'yes' : 'no'}<br/>
    <strong>Listening:</strong> ${st.listening ? 'yes' : 'no'}<br/>
    <strong>Uptime:</strong> ${st.uptime ? 'running' : 'stopped'}<br/>
    <strong>Node:</strong> ${st.node_name}<br/>
    <strong>Queues:</strong> ${st.queues}<br/>
    <strong>Messages published:</strong> ${st.messages_published}
  `;

  // Endpoints
  const e = await fetch('/api/endpoints');
  const ep = await e.json();
  const ediv = document.getElementById('endpoints');
  let html = '<h3>Endpoints</h3>';
  if (ep.endpoints) {
    for (const ep_item of ep.endpoints) {
      html += `<div class="endpoint">${ep_item}</div>`;
    }
  }
  ediv.innerHTML = html;
}
load();
setInterval(load, 5000);