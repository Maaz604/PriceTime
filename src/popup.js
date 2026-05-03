const wageInput = document.getElementById('wageInput');
const thresholdInput = document.getElementById('thresholdInput');
const enabledToggle = document.getElementById('enabledToggle');
const saveBtn = document.getElementById('saveBtn');
const statusMsg = document.getElementById('statusMsg');
const mainBody = document.getElementById('mainBody');

let statusTimeout = null;

function showStatus(message) {
  statusMsg.textContent = message;
  clearTimeout(statusTimeout);
  statusTimeout = setTimeout(() => { statusMsg.textContent = ''; }, 2200);
}

function syncBodyState(enabled) {
  mainBody.classList.toggle('popup__body--disabled', !enabled);
}

chrome.storage.sync.get(['hourlyWage', 'enabled', 'highlightThreshold'], (stored) => {
  wageInput.value = stored.hourlyWage ?? 20;
  thresholdInput.value = stored.highlightThreshold ?? 8;
  const isEnabled = stored.enabled !== undefined ? stored.enabled : true;
  enabledToggle.checked = isEnabled;
  syncBodyState(isEnabled);
});

enabledToggle.addEventListener('change', () => {
  const enabled = enabledToggle.checked;
  syncBodyState(enabled);
  chrome.storage.sync.set({ enabled });
});

saveBtn.addEventListener('click', () => {
  const wage = parseFloat(wageInput.value);
  const threshold = parseInt(thresholdInput.value, 10);
  if (isNaN(wage) || wage <= 0) { wageInput.focus(); showStatus('Enter a valid hourly wage.'); return; }
  if (isNaN(threshold) || threshold < 1) { thresholdInput.focus(); showStatus('Enter a valid threshold.'); return; }
  chrome.storage.sync.set({ hourlyWage: wage, highlightThreshold: threshold }, () => {
    showStatus('Settings saved.');
  });
});
