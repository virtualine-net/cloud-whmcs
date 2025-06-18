<script src="https://client.virtualine.net/diyovm/js/jquery-ui.min.js"></script>
<!-- WMKS Library -->
<script src="https://client.virtualine.net/diyovm/js/wmks.min.js"></script>

<div class="vi-dashboard">
  {if isset($actionMessage) && $actionMessage}
    <div class="vi-notification vi-notification-top">{$actionMessage}</div>
  {/if}

  <!-- Usage Graphs -->
  <div class="vi-usage-graphs">
    <div class="vi-usage-graph">
      <canvas id="cpuChart" width="90" height="90"></canvas>
      <div class="vi-usage-label">CPU</div>
      <div class="vi-usage-value">{$api['CPU Usage']} / {$api['Total CPU']}</div>
    </div>
    <div class="vi-usage-graph">
      <canvas id="ramChart" width="90" height="90"></canvas>
      <div class="vi-usage-label">RAM</div>
      <div class="vi-usage-value">{$api['RAM Usage']} / {$api['Total RAM']}</div>
    </div>
    <div class="vi-usage-graph">
      <canvas id="diskChart" width="90" height="90"></canvas>
      <div class="vi-usage-label">DISK</div>
      <div class="vi-usage-value">{$api['Disk Usage']} / {$api['Total Disk']}</div>
    </div>
    <div class="vi-usage-graph">
      <canvas id="netChart" width="90" height="90"></canvas>
      <div class="vi-usage-label">NET</div>
      <div class="vi-usage-value">{$api['Network Speed']}</div>
    </div>
  </div>
  <div class="vi-last-sync">Last updated: <span id="lastSyncTime">{$api['Last Sync']|default:date('Y-m-d H:i:s')}</span></div>

  <!-- Info Cards Row with Actions Card at Right -->
  <div class="vi-info-cards vi-info-cards-row">
    <div class="vi-card vi-card-login">
      <h3>Login</h3>
      <ul>
        <li><strong>User:</strong> {$service.username}</li>
        <li><strong>Password:</strong> {$service.password}</li>
        <li><strong>IP Address:</strong> {$api['Dedicated IP']}</li>
      </ul>
    </div>
    <div class="vi-card vi-card-serverinfo">
      <h3>Server</h3>
      <ul>
        <li><strong>Product:</strong> {$service.product}</li>
        <li><strong>Price:</strong> {$service.amount}</li>
        <li><strong>Next Due:</strong> {$service.nextduedate}</li>
        <li><strong>Purchased:</strong> {$service.regdate}</li>
      </ul>
    </div>
    <div class="vi-card vi-card-os">
      <h3>System</h3>
      <ul>
        <li><strong>OS:</strong> {$api['Operating System']}</li>
        <li><strong>Uptime:</strong> {$api['Uptime']}</li>
        <li><strong>Status:</strong> <span class="vi-status-{if $api.Status == 'Running'}running{else}stopped{/if}">{if $api.Status == 'Running'}Running{else}Stopped{/if}</span></li>
      </ul>
    </div>
    <div class="vi-card vi-card-internet">
      <h3>Network</h3>
      <ul>
        <li><strong>IP:</strong> {$api['Dedicated IP']}</li>
        <li><strong>Connection:</strong> <span class="vi-status-{if $api.Status == 'Running'}connected{else}disconnected{/if}">{if $api.Status == 'Running'}Connected{else}Disconnected{/if}</span></li>
        <li><strong>Speed:</strong> {$api['Network Speed']}</li>
      </ul>
    </div>
    <!-- Actions Card (rightmost) -->
    <div class="vi-card vi-card-actions vi-card-actions-vertical">
      <h3>Actions</h3>
      <form method="post">
        {if $api['Power Status'] == 'On'}
          <button class="vi-btn" name="customAction" value="stop">Stop</button>
          <button class="vi-btn" name="customAction" value="reboot">Restart</button>
        {else}
          <button class="vi-btn" name="customAction" value="start">Start</button>
        {/if}
      </form>
    </div>
  </div>
</div>

<!-- Tabs Section -->
<div class="vi-tabs">
  <ul class="vi-tab-list">
    <li class="vi-tab-item vi-tab-active" onclick="showTab('consoleTab')">Console</li>
    <li class="vi-tab-item" onclick="showTab('reinstallTab')">Reinstall</li>
  </ul>
  <div class="vi-tab-content" id="consoleTab" style="display:block;">
    <div id="wmksmaincontainer" style="position:relative;width:100%;height:400px">
      <div id="wmkscontainer" style="position:absolute;left:0;top:0;"></div>
    </div>
    <div class="vi-console-actions">
      <button class="vi-btn vi-btn-sm" id="fullscreen">Fullscreen</button>
      <button class="vi-btn vi-btn-sm" id="sendCAD">CTRL+ALT+DELETE</button>
      <input type="text" class="vi-form-control" id="consoleCommand" placeholder="Send Command">
      <button class="vi-btn vi-btn-sm" id="sendCommand">Send</button>
    </div>
  </div>
  <div class="vi-tab-content" id="reinstallTab" style="display:none;">
    <form method="post">
      <input type="hidden" name="customAction" value="reinstall" />
      <div class="vi-form-group">
        <label for="osTemplate">Operating System:</label>
        <select id="osTemplate" name="osTemplate" class="vi-form-control" required>
          {foreach from=$osTemplates item=template}
            <option value="{$template.id}">{$template.name}</option>
          {/foreach}
        </select>
      </div>
      <div class="vi-form-group">
        <label for="reinstallPassword">New Password:</label>
        <input type="password" id="reinstallPassword" name="reinstallPassword" class="vi-form-control" required />
      </div>
      <button type="submit" class="vi-btn vi-btn-danger">Reinstall Server</button>
    </form>
  </div>
</div>

<style>
:root {
  --vi-primary: #2d6cdf;
  --vi-primary-dark: #1b3a6b;
  --vi-success: #22c55e;
  --vi-warning: #fbbf24;
  --vi-danger: #ef4444;
  --vi-bg: #f4f7fb;
  --vi-card-bg: #fff;
  --vi-text: #1e293b;
  --vi-text-light: #64748b;
  --vi-border: #d1d5db;
  --vi-shadow: 0 2px 8px 0 rgb(0 0 0 / 0.07);
  --vi-shadow-lg: 0 8px 24px 0 rgb(0 0 0 / 0.10);
  --vi-secondary: #e0e7ef;
  --vi-accent: #7dd3fc;
}

body {
  background: var(--vi-bg);
}

.vi-notification-top {
  top: 18px;
  left: 50%;
  z-index: 10000;
  min-width: 320px;
  max-width: 90vw;
  background: #e0f7fa;
  color: #0f5132;
  border: 1px solid #7dd3fc;
  box-shadow: var(--vi-shadow-lg);
  border-radius: 10px;
  padding: 14px 28px;
  font-size: 1rem;
  font-weight: 500;
  text-align: center;
  margin-bottom: 0;
}

.vi-dashboard {
display: flex;
flex-direction: column;
gap: 18px;
padding: 24px 0 0 0;
background: var(--vi-bg);
align-items: center;
}

.vi-usage-graphs {
display: flex;
gap: 32px;
justify-content: center;
margin-bottom: 8px;
flex-wrap: wrap;
}

.vi-usage-graph {
display: flex;
flex-direction: column;
align-items: center;
background: var(--vi-card-bg);
border-radius: 16px;
box-shadow: var(--vi-shadow);
padding: 18px 18px 10px 18px;
min-width: 120px;
min-height: 140px;
position: relative;
}

.vi-usage-label {
margin-top: 8px;
color: var(--vi-text-light);
font-size: 15px;
font-weight: 500;
}

.vi-usage-value {
color: var(--vi-primary);
font-size: 15px;
font-weight: 600;
margin-top: 2px;
}

.vi-usage-percentage {
position: absolute;
top: 35%;
left: 50%;
transform: translate(-50%, -50%);
font-size: 18px;
font-weight: 600;
color: var(--vi-text);
}

.vi-info-cards-row {
display: flex;
gap: 18px;
flex-wrap: wrap;
justify-content: center;
width: 100%;
align-items: stretch;
}

.vi-card {
background: var(--vi-card-bg);
border-radius: 12px;
box-shadow: var(--vi-shadow);
padding: 18px 20px;
min-width: 220px;
max-width: 270px;
flex: 1 1 220px;
border: 1px solid var(--vi-border);
margin-bottom: 0;
display: flex;
flex-direction: column;
justify-content: flex-start;
}

.vi-card-actions-vertical {
min-width: 170px;
max-width: 170px;
align-items: stretch;
justify-content: flex-start;
gap: 0;
}

.vi-card-actions-vertical h3 {
margin-bottom: 16px;
font-size: 1.08rem;
color: var(--vi-primary-dark);
font-weight: 700;
border-bottom: 1px solid var(--vi-border);
padding-bottom: 8px;
}

.vi-card-actions-vertical form {
display: flex;
flex-direction: column;
gap: 10px;
}

.vi-card h3 {
margin: 0 0 12px 0;
color: var(--vi-primary-dark);
font-size: 1.08rem;
font-weight: 700;
padding-bottom: 8px;
border-bottom: 1px solid var(--vi-border);
}

.vi-card ul {
list-style: none;
padding: 0;
margin: 0;
}

.vi-card li {
margin-bottom: 8px;
display: flex;
align-items: center;
color: var(--vi-text-light);
font-size: 15px;
word-break: break-all;
overflow-wrap: break-word;
}

.vi-card li strong {
color: var(--vi-text);
min-width: 90px;
font-weight: 500;
flex-shrink: 0;
}

.vi-status-running {
color: var(--vi-success);
font-weight: 600;
}
.vi-status-stopped {
color: var(--vi-danger);
font-weight: 600;
}
.vi-status-connected {
color: var(--vi-success);
font-weight: 600;
}
.vi-status-disconnected {
color: var(--vi-danger);
font-weight: 600;
}

.vi-btn {
background: var(--vi-primary);
color: #fff;
border: none;
padding: 9px 18px;
border-radius: 8px;
cursor: pointer;
font-weight: 500;
font-size: 15px;
transition: all 0.2s ease;
margin-bottom: 0;
}

.vi-btn:hover {
background: #1b3a6b;
}

.vi-btn-danger {
background: var(--vi-danger);
}
.vi-btn-danger:hover {
background: #b91c1c;
}

.vi-btn-sm {
padding: 6px 14px;
font-size: 14px;
}

.vi-tabs {
margin: 32px auto 0 auto;
background: var(--vi-card-bg);
border-radius: 12px;
box-shadow: var(--vi-shadow);
padding: 18px 24px;
max-width: 900px;
}

.vi-tab-list {
display: flex;
gap: 16px;
border-bottom: 2px solid var(--vi-border);
margin-bottom: 18px;
padding-left: 0;
}

.vi-tab-item {
list-style: none;
padding: 10px 24px;
cursor: pointer;
color: var(--vi-text-light);
border-radius: 8px 8px 0 0;
font-weight: 500;
transition: background 0.2s, color 0.2s;
}

.vi-tab-active {
background: var(--vi-bg);
color: var(--vi-primary);
border-bottom: 2px solid var(--vi-primary);
}

.vi-tab-content {
display: none;
}

.vi-tab-content.active {
display: block;
}

.vi-form-control {
padding: 8px 12px;
border: 1px solid var(--vi-border);
border-radius: 6px;
font-size: 14px;
margin-right: 10px;
}

.vi-form-group {
margin-bottom: 16px;
}

.vi-form-group label {
display: block;
margin-bottom: 8px;
color: var(--vi-text);
font-weight: 500;
}

.vi-form-group select.vi-form-control {
width: 100%;
margin-right: 0;
}

.vi-form-group input.vi-form-control {
width: 100%;
margin-right: 0;
margin-bottom: 16px;
}

.vi-console-actions {
display: flex;
gap: 10px;
margin-top: 16px;
}

.vi-last-sync {
text-align: center;
color: var(--vi-text-light);
font-size: 14px;
margin-top: 8px;
margin-bottom: 16px;
}

@media (max-width: 1100px) {
.vi-info-cards-row {
flex-wrap: wrap;
gap: 12px;
}
.vi-card {
min-width: 180px;
max-width: 100vw;
}
.vi-card-actions-vertical {
min-width: 100%;
max-width: 100vw;
margin-top: 12px;
}
}
@media (max-width: 800px) {
.vi-info-cards-row {
flex-direction: column;
align-items: stretch;
}
.vi-card, .vi-card-actions-vertical {
min-width: 100%;
max-width: 100vw;
}
}

@media (max-width: 768px) {
.vi-usage-graphs {
gap: 16px;
}

.vi-usage-graph {
min-width: 100px;
min-height: 120px;
}

.vi-info-cards-row {
padding: 0 16px;
}

.vi-card {
min-width: 100%;
}

.vi-tabs {
margin: 24px 16px;
padding: 16px;
}

.vi-tab-list {
gap: 8px;
}

.vi-tab-item {
padding: 8px 16px;
font-size: 14px;
}

.vi-console-actions {
flex-wrap: wrap;
}

.vi-form-control {
width: 100%;
margin-right: 0;
margin-bottom: 8px;
}
}
</style>
<script>
function showTab(tabId) {
  document.getElementById('consoleTab').style.display = 'none';
  document.getElementById('reinstallTab').style.display = 'none';
  document.getElementById(tabId).style.display = 'block';
  var tabs = document.querySelectorAll('.vi-tab-item');
  tabs.forEach(function(tab) { tab.classList.remove('vi-tab-active'); });
  if(tabId === 'consoleTab') {
    tabs[0].classList.add('vi-tab-active');
  } else {
    tabs[2].classList.add('vi-tab-active');
  }
}

function openConsoleModal() {
  showTab('consoleTab');
}
function openReinstallModal() {
  showTab('reinstallTab');
}

// WMKS Console Initialization
var wmks = null;
function initWMKS() {
  if (wmks) return;
  wmks = WMKS.createWMKS("wmkscontainer", { keyboardLayoutId: "en-US" });
  wmks.register(WMKS.CONST.Events.CONNECTION_STATE_CHANGE, function(evt, data) {
    if(data.state === WMKS.CONST.ConnectionState.CONNECTED) {
      $("#mainCanvas").attr("role", "img");
      $("#mainCanvas").attr("aria-label", "Virtual Console");
    }
  });
  wmks.connect('{$wmksUrl}');
}

function updateUsageData() {
  $.ajax({
    url: window.location.href,
    method: 'POST',
    dataType: "json",
    data: {
      customAction: 'details'
    },
    success: function(response) {
      if (response.result == 'success') {
        // Update last sync time
        $('#lastSyncTime').text(response.timestamp);
        
        // Update usage values
        var data = response.data;
        
        // Update CPU usage
        $('.vi-usage-value').each(function() {
          var label = $(this).prev('.vi-usage-label').text();
          if (label === 'CPU') {
            $(this).text(data['CPU Usage'] + ' / ' + data['Total CPU']);
          } else if (label === 'RAM') {
            $(this).text(data['RAM Usage'] + ' / ' + data['Total RAM']);
          } else if (label === 'DISK') {
            $(this).text(data['Disk Usage'] + ' / ' + data['Total Disk']);
          } else if (label === 'NET') {
            $(this).text(data['Network Speed']);
          }
        });

        // Update status indicators
        $('.vi-status-running, .vi-status-stopped').each(function() {
          if ($(this).parent().find('strong').text().includes('Status')) {
            $(this).text(data['Status']);
            $(this).removeClass('vi-status-running vi-status-stopped')
                   .addClass(data['Status'] === 'Running' ? 'vi-status-running' : 'vi-status-stopped');
          }
        });

        $('.vi-status-connected, .vi-status-disconnected').each(function() {
          if ($(this).parent().find('strong').text().includes('Connection')) {
            $(this).text(data['Status'] === 'Running' ? 'Connected' : 'Disconnected');
            $(this).removeClass('vi-status-connected vi-status-disconnected')
                   .addClass(data['Status'] === 'Running' ? 'vi-status-connected' : 'vi-status-disconnected');
          }
        });
        
        // Redraw charts with new data
        drawUsageCharts(data);
      }
    }
  });
}

// Update every minute
setInterval(updateUsageData, 60000);

// Initial draw
window.onload = function() { 
  initWMKS(); 
  drawUsageCharts(); 
  updateUsageData(); // Initial data fetch
};

document.getElementById('sendCAD')?.addEventListener('click', function() {
  wmks?.sendCAD();
});
document.getElementById('sendCommand')?.addEventListener('click', function() {
  wmks?.sendInputString(document.getElementById('consoleCommand').value);
  document.getElementById('consoleCommand').value = '';
});
document.getElementById('fullscreen')?.addEventListener('click', function() {
  wmks?.enterFullScreen();
});

// Usage Graphs
function drawCircle(canvasId, percent, color, bgColor, showText=true) {
  var canvas = document.getElementById(canvasId);
  if (!canvas) return;
  var ctx = canvas.getContext('2d');
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  var centerX = canvas.width / 2;
  var centerY = canvas.height / 2;
  var radius = 36;
  var startAngle = -0.5 * Math.PI;
  var endAngle = startAngle + (percent * 2 * Math.PI);
  
  // BG
  ctx.beginPath();
  ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI, false);
  ctx.strokeStyle = bgColor;
  ctx.lineWidth = 8;
  ctx.stroke();
  
  // Value
  ctx.beginPath();
  ctx.arc(centerX, centerY, radius, startAngle, endAngle, false);
  ctx.strokeStyle = color;
  ctx.lineWidth = 8;
  ctx.lineCap = 'round';
  ctx.stroke();
  
  // Add percentage label
  var percentageElement = document.createElement('div');
  percentageElement.className = 'vi-usage-percentage';
  percentageElement.textContent = Math.round(percent * 100) + '%';
  
  // Remove existing percentage if any
  var existingPercentage = canvas.parentElement.querySelector('.vi-usage-percentage');
  if (existingPercentage) {
    existingPercentage.remove();
  }
  
  if (showText) {
    canvas.parentElement.appendChild(percentageElement);
  }
}
function parseUsage(usage, total) {
  if (!usage || !total) return 0;
  var u = parseFloat(usage);
  var t = parseFloat(total);
  if (isNaN(u) || isNaN(t) || t === 0) return 0;
  return Math.min(u / t, 1);
}
function parseMB(str) {
  if (!str) return 0;
  var m = str.match(/([\d.]+)\s*MB/i);
  return m ? parseFloat(m[1]) : 0;
}
function parseGB(str) {
  if (!str) return 0;
  var m = str.match(/([\d.]+)\s*GB/i);
  return m ? parseFloat(m[1]) : 0;
}
function drawUsageCharts(data) {
  if (!data) {
    data = {
      'CPU Usage': '{$api['CPU Usage']}',
      'Total CPU': '{$api['Total CPU']}',
      'RAM Usage': '{$api['RAM Usage']}',
      'Total RAM': '{$api['Total RAM']}',
      'Disk Usage': '{$api['Disk Usage']}',
      'Total Disk': '{$api['Total Disk']}'
    };
  }

  // CPU
  var cpuUsage = parseFloat(data['CPU Usage'].replace(/[^\d.]/g, ''));
  var cpuTotal = parseFloat(data['Total CPU'].replace(/[^\d.]/g, ''));
  drawCircle('cpuChart', cpuTotal ? cpuUsage / cpuTotal : 0, '#2d6cdf', '#e0e7ef');

  // RAM
  var ramUsage = parseMB(data['RAM Usage']);
  var ramTotal = parseMB(data['Total RAM']);
  drawCircle('ramChart', ramTotal ? ramUsage / ramTotal : 0, '#22c55e', '#e0e7ef');

  // DISK
  var diskUsage = parseGB(data['Disk Usage']);
  var diskTotal = parseGB(data['Total Disk']);
  drawCircle('diskChart', diskTotal ? diskUsage / diskTotal : 0, '#fbbf24', '#e0e7ef');

  // NET (simulate, always 100%)
  drawCircle('netChart', 1, '#7dd3fc', '#e0e7ef', false);
}
</script>