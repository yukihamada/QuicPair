// QuicPair Website JavaScript

// Platform Detection
function detectPlatform() {
  const userAgent = navigator.userAgent.toLowerCase();
  const platform = navigator.platform.toLowerCase();
  
  if (/iphone|ipad|ipod/.test(userAgent)) {
    return 'ios';
  } else if (/mac/.test(platform)) {
    return 'mac';
  } else if (/android/.test(userAgent)) {
    return 'android';
  } else if (/win/.test(platform)) {
    return 'windows';
  } else if (/linux/.test(platform)) {
    return 'linux';
  }
  return 'unknown';
}

// Update download buttons based on platform
function updateDownloadButtons() {
  const platform = detectPlatform();
  const platformNote = document.getElementById('platformDetected');
  const downloadSection = document.getElementById('downloadSection');
  
  // Platform-specific messages
  const messages = {
    ios: 'iOS を検出しました',
    mac: 'macOS を検出しました',
    android: 'Android を検出しました（iOS版をApp Storeでご利用ください）',
    windows: 'Windows を検出しました（現在はmacOS/iOSのみ対応）',
    linux: 'Linux を検出しました（現在はmacOS/iOSのみ対応）',
    unknown: 'お使いのプラットフォームに合わせてダウンロード'
  };
  
  if (platformNote) {
    platformNote.textContent = messages[platform] || messages.unknown;
  }
  
  // Reorder buttons based on platform
  if (platform === 'ios' && downloadSection) {
    const iosButton = downloadSection.querySelector('.download-ios');
    const macButton = downloadSection.querySelector('.download-mac');
    if (iosButton && macButton) {
      downloadSection.insertBefore(iosButton, macButton);
      iosButton.classList.remove('secondary');
      iosButton.classList.add('primary');
      macButton.classList.remove('primary');
      macButton.classList.add('secondary');
    }
  }
}

// Mobile menu toggle
function setupMobileMenu() {
  const mobileMenuButton = document.querySelector('.mobile-menu');
  const mobileNav = document.querySelector('.mobile-nav');
  
  if (mobileMenuButton && mobileNav) {
    mobileMenuButton.addEventListener('click', () => {
      const isOpen = mobileNav.style.display === 'block';
      mobileNav.style.display = isOpen ? 'none' : 'block';
      
      // Animate hamburger
      const spans = mobileMenuButton.querySelectorAll('span');
      if (isOpen) {
        spans[0].style.transform = 'rotate(0) translateY(0)';
        spans[1].style.opacity = '1';
        spans[2].style.transform = 'rotate(0) translateY(0)';
      } else {
        spans[0].style.transform = 'rotate(45deg) translateY(7px)';
        spans[1].style.opacity = '0';
        spans[2].style.transform = 'rotate(-45deg) translateY(-7px)';
      }
    });
    
    // Close mobile menu when clicking a link
    const mobileLinks = mobileNav.querySelectorAll('a');
    mobileLinks.forEach(link => {
      link.addEventListener('click', () => {
        mobileNav.style.display = 'none';
      });
    });
  }
}

// Smooth scroll with offset for sticky header
function setupSmoothScroll() {
  const links = document.querySelectorAll('a[href^="#"]');
  const headerHeight = 80;
  
  links.forEach(link => {
    link.addEventListener('click', (e) => {
      const href = link.getAttribute('href');
      if (href === '#') return;
      
      const target = document.querySelector(href);
      if (target) {
        e.preventDefault();
        const targetPosition = target.offsetTop - headerHeight;
        window.scrollTo({
          top: targetPosition,
          behavior: 'smooth'
        });
        
        // Close mobile menu if open
        const mobileNav = document.querySelector('.mobile-nav');
        if (mobileNav && mobileNav.style.display === 'block') {
          mobileNav.style.display = 'none';
        }
      }
    });
  });
}

// Animate stats on scroll
function setupStatsAnimation() {
  const stats = document.querySelectorAll('.stat-value');
  const observerOptions = {
    threshold: 0.5,
    rootMargin: '0px'
  };
  
  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const stat = entry.target;
        const value = stat.textContent.match(/\d+/);
        if (value) {
          animateValue(stat, 0, parseInt(value[0]), 1000);
          observer.unobserve(stat);
        }
      }
    });
  }, observerOptions);
  
  stats.forEach(stat => observer.observe(stat));
}

// Animate numeric value
function animateValue(element, start, end, duration) {
  const range = end - start;
  const minTimer = 50;
  let stepTime = Math.abs(Math.floor(duration / range));
  stepTime = Math.max(stepTime, minTimer);
  const startTime = new Date().getTime();
  const endTime = startTime + duration;
  let timer;
  
  function run() {
    const now = new Date().getTime();
    const remaining = Math.max((endTime - now) / duration, 0);
    const value = Math.round(end - (remaining * range));
    const unit = element.querySelector('.unit');
    if (unit) {
      element.innerHTML = value + unit.outerHTML;
    } else {
      element.textContent = value + (element.textContent.match(/[a-zA-Z]+/) || [''])[0];
    }
    if (value === end) {
      clearInterval(timer);
    }
  }
  
  timer = setInterval(run, stepTime);
  run();
}

// Download tracking
function setupDownloadTracking() {
  const downloadLinks = document.querySelectorAll('a[download], a[href*="download"], a[href*="apps.apple.com"], a[href*="testflight"]');
  
  downloadLinks.forEach(link => {
    link.addEventListener('click', (e) => {
      const platform = link.getAttribute('data-platform') || 'unknown';
      const fileName = link.getAttribute('download') || link.href.split('/').pop();
      
      // Track download (placeholder for analytics)
      console.log('Download:', {
        platform: platform,
        file: fileName,
        timestamp: new Date().toISOString()
      });
      
      // You can add actual analytics here
      // gtag('event', 'download', { platform, file: fileName });
    });
  });
}

// TTFT Demo Animation
function setupTTFTDemo() {
  const ttftDisplay = document.querySelector('.stat-value');
  if (!ttftDisplay) return;
  
  // Simulate TTFT variations
  setInterval(() => {
    const baseTime = 100;
    const variation = Math.random() * 50 - 25; // ±25ms variation
    const newTime = Math.round(baseTime + variation);
    
    if (ttftDisplay.textContent.includes('ms')) {
      ttftDisplay.innerHTML = `${newTime}<span class="unit">ms</span>`;
    }
  }, 5000);
}

// Form handling
function setupForms() {
  const forms = document.querySelectorAll('form');
  
  forms.forEach(form => {
    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      
      const formData = new FormData(form);
      const button = form.querySelector('button[type="submit"]');
      const originalText = button.textContent;
      
      // Update button state
      button.disabled = true;
      button.textContent = '送信中...';
      
      try {
        // Placeholder for actual form submission
        // const response = await fetch('/api/subscribe', {
        //   method: 'POST',
        //   body: formData
        // });
        
        // Simulate API call
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        // Success
        button.textContent = '✓ 登録完了';
        form.reset();
        
        setTimeout(() => {
          button.disabled = false;
          button.textContent = originalText;
        }, 3000);
        
      } catch (error) {
        // Error
        button.textContent = 'エラーが発生しました';
        button.disabled = false;
        
        setTimeout(() => {
          button.textContent = originalText;
        }, 3000);
      }
    });
  });
}

// Initialize everything when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  updateDownloadButtons();
  setupMobileMenu();
  setupSmoothScroll();
  setupStatsAnimation();
  setupDownloadTracking();
  setupTTFTDemo();
  setupForms();
});

// Update on resize
let resizeTimer;
window.addEventListener('resize', () => {
  clearTimeout(resizeTimer);
  resizeTimer = setTimeout(() => {
    // Reset mobile menu on resize
    const mobileNav = document.querySelector('.mobile-nav');
    if (mobileNav && window.innerWidth > 768) {
      mobileNav.style.display = 'none';
    }
  }, 250);
});