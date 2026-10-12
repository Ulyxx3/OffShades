/**
 * OffShades Shaderpack - Showcase Website Scripts
 */

document.addEventListener('DOMContentLoaded', () => {
  initNavbar();
  initTimeSlider();
  initCopyButtons();
  initScrollAnimations();
});

/* ==========================================================================
   1. Navigation & Header Scroll State
   ========================================================================== */
function initNavbar() {
  const header = document.querySelector('.site-header');
  const mobileToggle = document.querySelector('.mobile-toggle');
  const navLinks = document.querySelector('.nav-links');
  const links = document.querySelectorAll('.nav-link');

  // Sticky header background
  window.addEventListener('scroll', () => {
    if (window.scrollY > 40) {
      header.classList.add('scrolled');
    } else {
      header.classList.remove('scrolled');
    }
  }, { passive: true });

  // Mobile menu toggle
  if (mobileToggle && navLinks) {
    mobileToggle.addEventListener('click', () => {
      const isVisible = navLinks.style.display === 'flex';
      navLinks.style.display = isVisible ? 'none' : 'flex';
      if (!isVisible) {
        navLinks.style.flexDirection = 'column';
        navLinks.style.position = 'absolute';
        navLinks.style.top = '70px';
        navLinks.style.left = '0';
        navLinks.style.right = '0';
        navLinks.style.background = 'rgba(10, 12, 16, 0.98)';
        navLinks.style.padding = '1.5rem';
        navLinks.style.borderBottom = '1px solid rgba(255, 255, 255, 0.1)';
      }
    });

    links.forEach(link => {
      link.addEventListener('click', () => {
        if (window.innerWidth <= 768) {
          navLinks.style.display = 'none';
        }
      });
    });
  }

  // Active section spy
  const sections = document.querySelectorAll('section[id], header[id]');
  window.addEventListener('scroll', () => {
    let current = '';
    const scrollPos = window.scrollY + 220;

    sections.forEach(section => {
      const sectionTop = section.offsetTop;
      const sectionHeight = section.offsetHeight;
      if (scrollPos >= sectionTop && scrollPos < sectionTop + sectionHeight) {
        current = section.getAttribute('id');
      }
    });

    links.forEach(link => {
      link.classList.remove('active');
      if (link.getAttribute('href') === `#${current}`) {
        link.classList.add('active');
      }
    });
  }, { passive: true });
}

/* ==========================================================================
   2. Clean Interactive Time-of-Day Slider (4 Synchronized Layers)
   ========================================================================== */
function initTimeSlider() {
  const slider = document.getElementById('time-range-input');
  const layerDay = document.getElementById('layer-day');
  const layerNoon = document.getElementById('layer-noon');
  const layerNight = document.getElementById('layer-night');
  const layerMidnight = document.getElementById('layer-midnight');
  const indicationStops = document.querySelectorAll('.time-indication-stop');

  if (!slider || !layerDay || !layerNoon || !layerNight || !layerMidnight) return;

  function updateTimeState(val) {
    val = Math.max(0, Math.min(300, parseFloat(val)));

    // Seamless opacity transitions between the 4 aligned viewpoints:
    if (val <= 100) {
      const t = val / 100;
      layerDay.style.opacity = '1';
      layerNoon.style.opacity = t.toFixed(3);
      layerNight.style.opacity = '0';
      layerMidnight.style.opacity = '0';
    } else if (val <= 200) {
      const t = (val - 100) / 100;
      layerDay.style.opacity = '0';
      layerNoon.style.opacity = '1';
      layerNight.style.opacity = t.toFixed(3);
      layerMidnight.style.opacity = '0';
    } else {
      const t = (val - 200) / 100;
      layerDay.style.opacity = '0';
      layerNoon.style.opacity = '0';
      layerNight.style.opacity = '1';
      layerMidnight.style.opacity = t.toFixed(3);
    }

    // Highlight nearest indication stop
    indicationStops.forEach(stop => {
      const target = parseFloat(stop.getAttribute('data-time'));
      const diff = Math.abs(val - target);
      if (diff <= 35) {
        stop.classList.add('active');
      } else {
        stop.classList.remove('active');
      }
    });
  }

  // Slider input
  slider.addEventListener('input', (e) => {
    updateTimeState(e.target.value);
  });

  // Clicking an indication label smoothly slides to that stop
  indicationStops.forEach(stop => {
    stop.addEventListener('click', () => {
      const targetVal = parseFloat(stop.getAttribute('data-time'));
      animateSliderTo(targetVal);
    });
  });

  function animateSliderTo(target) {
    const start = parseFloat(slider.value);
    const change = target - start;
    const duration = 300; // ms
    const startTime = performance.now();

    function step(currentTime) {
      const elapsed = currentTime - startTime;
      const progress = Math.min(elapsed / duration, 1);
      const ease = progress < 0.5 ? 2 * progress * progress : -1 + (4 - 2 * progress) * progress;
      const currentVal = start + change * ease;
      
      slider.value = currentVal;
      updateTimeState(currentVal);

      if (progress < 1) {
        requestAnimationFrame(step);
      }
    }
    requestAnimationFrame(step);
  }

  // Initial State: Day (0)
  updateTimeState(0);
}

/* ==========================================================================
   3. 1-Click Copy Buttons (Installation Path & Clone Command)
   ========================================================================== */
function initCopyButtons() {
  const copyBtns = document.querySelectorAll('.copy-btn');

  copyBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      const textToCopy = btn.getAttribute('data-copy');
      if (!textToCopy) return;

      navigator.clipboard.writeText(textToCopy).then(() => {
        const originalText = btn.innerHTML;
        btn.innerHTML = `
          <svg viewBox="0 0 24 24" fill="currentColor" style="width:14px;height:14px;">
            <path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/>
          </svg>
          Copied!
        `;
        btn.style.background = 'rgba(255, 255, 255, 0.25)';

        setTimeout(() => {
          btn.innerHTML = originalText;
          btn.style.background = '';
        }, 2000);
      }).catch(err => {
        console.error('Copy failed:', err);
      });
    });
  });
}

/* ==========================================================================
   4. Scroll Reveal Animations
   ========================================================================== */
function initScrollAnimations() {
  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('revealed');
        observer.unobserve(entry.target);
      }
    });
  }, {
    threshold: 0.1,
    rootMargin: '0px 0px -30px 0px'
  });

  document.querySelectorAll('.reveal-on-scroll').forEach(el => {
    observer.observe(el);
  });
}
