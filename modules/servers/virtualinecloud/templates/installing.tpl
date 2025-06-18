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

.installing-box {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  background: var(--vi-bg);
  padding: 24px;
}

.installing-content {
  background: var(--vi-card-bg);
  border-radius: 12px;
  box-shadow: var(--vi-shadow);
  padding: 48px;
  text-align: center;
  max-width: 400px;
  width: 100%;
  border: 1px solid var(--vi-border);
  animation: slideIn 0.3s ease;
}

.loading-spinner {
  width: 48px;
  height: 48px;
  border: 4px solid var(--vi-border);
  border-top: 4px solid var(--vi-warning);
  border-radius: 50%;
  margin: 0 auto 24px;
  animation: spin 1s linear infinite;
}

.loading-spinner.error {
  border-top-color: var(--vi-danger);
  animation: none;
}

.loading-spinner.warning {
  border-top-color: var(--vi-warning);
  animation: none;
}

.progress-container {
  width: 100%;
  margin: 16px 0;
  display: none;
}

.progress-bar {
  width: 100%;
  height: 8px;
  background: var(--vi-border);
  border-radius: 4px;
  overflow: hidden;
}

.progress-bar-fill {
  height: 100%;
  background: var(--vi-primary);
  width: 0%;
  transition: width 0.3s ease;
}

.progress-text {
  font-size: 14px;
  color: var(--vi-text-light);
  margin-top: 8px;
}

.installing-content p {
  color: var(--vi-text);
  font-size: 18px;
  font-weight: 500;
  margin: 0;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

@keyframes slideIn {
  from {
    transform: translateY(-20px);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
}
</style>

<div class="installing-box">
  <div class="installing-content">
    <div class="loading-spinner"></div>
    <p>{$statusText|default:"Installing..."}</p>
    <div class="progress-container">
      <div class="progress-bar">
        <div class="progress-bar-fill"></div>
      </div>
      <div class="progress-text">0%</div>
    </div>
  </div>
</div>

<script>
    let checkCount = 0;
    const maxChecks = 60; // 5 minutes maximum (5 seconds * 60)

    function updateProgress(progress) {
        const progressContainer = document.querySelector('.progress-container');
        const progressBarFill = document.querySelector('.progress-bar-fill');
        const progressText = document.querySelector('.progress-text');
        
        if (progress > 0) {
            progressContainer.style.display = 'block';
            progressBarFill.style.width = progress + '%';
            progressText.textContent = progress + '%';
        } else {
            progressContainer.style.display = 'none';
        }
    }

    function checkStatus() {
        $.ajax({
            type: "POST",
            dataType: "json",
            data: {
                customAction: "checkStatus"
            },
            success: function (res) {
                if (res.result === 'success') {
                    window.location.href = 'clientarea.php?action=productdetails&id={$serviceid}';
                } else if (res.result === 'error') {
                    document.querySelector('.installing-content p').textContent = res.message || 'An error occurred during installation.';
                    document.querySelector('.loading-spinner').classList.add('error');
                    updateProgress(0);
                } else {
                    checkCount++;
                    if (res.progress !== undefined) {
                        updateProgress(res.progress);
                    }
                    if (checkCount >= maxChecks) {
                        document.querySelector('.installing-content p').textContent = 'Installation is taking longer than expected. Please contact support if this persists.';
                        document.querySelector('.loading-spinner').classList.add('warning');
                    }
                }
            },
            error: function(xhr, status, error) {
                console.error('AJAX Error:', status, error);
                document.querySelector('.installing-content p').textContent = 'Failed to check installation status. Please try refreshing the page.';
                document.querySelector('.loading-spinner').classList.add('error');
                updateProgress(0);
            }
        });
    }

    // Check status every 5 seconds
    setInterval(checkStatus, 5000);
    // Initial check
    checkStatus();
</script>