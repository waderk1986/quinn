/* ═══════════════════════════════════════════
   QUINN ARCHIBEQUE FOR SHERIFF
   main.js
═══════════════════════════════════════════ */

/* ── Nav scroll effect ── */
const nav = document.getElementById('nav');
window.addEventListener(
  'scroll',
  () => {
    nav.classList.toggle('scrolled', window.scrollY > 40);
  },
  { passive: true }
);

/* ── Mobile hamburger ── */
const hamburger = document.getElementById('hamburger');
const navMobile = document.getElementById('navMobile');
hamburger.addEventListener('click', () => {
  navMobile.classList.toggle('open');
});
navMobile.querySelectorAll('a').forEach((a) => {
  a.addEventListener('click', () => navMobile.classList.remove('open'));
});

/* ── Scroll reveal ── */
const revealEls = document.querySelectorAll('.reveal');
const revealObserver = new IntersectionObserver(
  (entries) => {
    entries.forEach((e) => {
      if (e.isIntersecting) {
        e.target.classList.add('visible');
        revealObserver.unobserve(e.target);
      }
    });
  },
  { threshold: 0.15 }
);

revealEls.forEach((el) => revealObserver.observe(el));

// Trigger hero reveals immediately
document.querySelectorAll('.hero .reveal').forEach((el) => {
  setTimeout(() => el.classList.add('visible'), 100);
});

/* ── Value cards & timeline scroll reveal ── */
const scrollRevealEls = document.querySelectorAll(
  '.value-card, .timeline-item, .about-inner, .quote-break-inner, .contact-inner'
);
const fadeObserver = new IntersectionObserver(
  (entries) => {
    entries.forEach((e) => {
      if (e.isIntersecting) {
        setTimeout(() => {
          e.target.style.opacity = '1';
          e.target.style.transform = 'translateY(0)';
        }, 80);
        fadeObserver.unobserve(e.target);
      }
    });
  },
  { threshold: 0.1 }
);

scrollRevealEls.forEach((el) => {
  el.style.opacity = '0';
  el.style.transform = 'translateY(32px)';
  el.style.transition = 'opacity 0.7s ease, transform 0.7s ease';
  fadeObserver.observe(el);
});

// Stagger value cards
document.querySelectorAll('.value-card').forEach((card, i) => {
  card.style.transitionDelay = `${i * 0.12}s`;
});

// Stagger timeline items
document.querySelectorAll('.timeline-item').forEach((item, i) => {
  item.style.transitionDelay = `${i * 0.15}s`;
});

/* ── Hero WebGL canvas — animated flag-like fluid in navy/gold ── */
(function () {
  const canvas = document.getElementById('heroCanvas');
  if (!canvas) return;

  const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
  if (!gl) return;

  function resize() {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
    gl.viewport(0, 0, canvas.width, canvas.height);
  }
  resize();
  window.addEventListener('resize', resize, { passive: true });

  const vertSrc = `
    attribute vec2 aPos;
    void main() {
      gl_Position = vec4(aPos, 0.0, 1.0);
    }
  `;

  const fragSrc = `
    precision mediump float;
    uniform float uTime;
    uniform vec2  uRes;
    uniform vec2  uMouse;

    float hash(vec2 p) {
      return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
    }
    float noise(vec2 p) {
      vec2 i = floor(p), f = fract(p);
      vec2 u = f * f * (3.0 - 2.0 * f);
      return mix(
        mix(hash(i), hash(i + vec2(1,0)), u.x),
        mix(hash(i + vec2(0,1)), hash(i + vec2(1,1)), u.x),
        u.y
      );
    }
    float fbm(vec2 p) {
      float v = 0.0, a = 0.5;
      for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p  = p * 2.1 + vec2(1.7, 9.2);
        a *= 0.5;
      }
      return v;
    }

    void main() {
      vec2 uv = gl_FragCoord.xy / uRes;
      vec2 mouse = uMouse / uRes;
      mouse.y = 1.0 - mouse.y;

      float t = uTime * 0.14;
      vec2 q = vec2(fbm(uv + t), fbm(uv + vec2(1.0)));
      vec2 r = vec2(
        fbm(uv + q + vec2(1.7, 9.2) + 0.15 * t),
        fbm(uv + q + vec2(8.3, 2.8) + 0.12 * t)
      );
      float f = fbm(uv + r);

      /* subtle cursor glow */
      float d = distance(uv, mouse);
      float glow = smoothstep(0.35, 0.0, d) * 0.18;

      /* Navy → navy-mid → very subtle gold hint */
      vec3 colA = vec3(0.05, 0.11, 0.18);
      vec3 colB = vec3(0.08, 0.17, 0.28);
      vec3 colC = vec3(0.13, 0.14, 0.09);

      vec3 col = mix(colA, colB, clamp(f * f * 4.0, 0.0, 1.0));
      col      = mix(col,  colC, clamp(f * 0.6,     0.0, 1.0));
      col     += glow * vec3(0.18, 0.14, 0.03);

      gl_FragColor = vec4(col, 1.0);
    }
  `;

  function compileShader(type, src) {
    const s = gl.createShader(type);
    gl.shaderSource(s, src);
    gl.compileShader(s);
    if (!gl.getShaderParameter(s, gl.COMPILE_STATUS)) {
      console.warn(gl.getShaderInfoLog(s));
      return null;
    }
    return s;
  }

  const vert = compileShader(gl.VERTEX_SHADER, vertSrc);
  const frag = compileShader(gl.FRAGMENT_SHADER, fragSrc);
  if (!vert || !frag) return;

  const prog = gl.createProgram();
  gl.attachShader(prog, vert);
  gl.attachShader(prog, frag);
  gl.linkProgram(prog);
  gl.useProgram(prog);

  const quad = new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]);
  const buf = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, buf);
  gl.bufferData(gl.ARRAY_BUFFER, quad, gl.STATIC_DRAW);

  const aPos = gl.getAttribLocation(prog, 'aPos');
  const uTime = gl.getUniformLocation(prog, 'uTime');
  const uRes = gl.getUniformLocation(prog, 'uRes');
  const uMouse = gl.getUniformLocation(prog, 'uMouse');

  gl.enableVertexAttribArray(aPos);
  gl.vertexAttribPointer(aPos, 2, gl.FLOAT, false, 0, 0);

  const mouse = { x: 0, y: 0 };
  window.addEventListener(
    'mousemove',
    (e) => {
      mouse.x = e.clientX;
      mouse.y = e.clientY;
    },
    { passive: true }
  );

  const startTime = performance.now();
  function render() {
    const t = (performance.now() - startTime) / 1000;
    gl.uniform1f(uTime, t);
    gl.uniform2f(uRes, canvas.width, canvas.height);
    gl.uniform2f(uMouse, mouse.x, mouse.y);
    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
    requestAnimationFrame(render);
  }
  render();
})();

/* ── Contact form ── */
const form = document.getElementById('contactForm');
const formSuccess = document.getElementById('formSuccess');

form.addEventListener('submit', async (e) => {
  e.preventDefault();
  const btn = form.querySelector('button[type="submit"]');
  btn.textContent = 'Sending...';
  btn.disabled = true;

  const data = {
    fname: form.fname.value.trim(),
    lname: form.lname.value.trim(),
    email: form.email.value.trim(),
    interest: form.interest.value,
    message: form.message.value.trim(),
  };

  try {
    const res = await fetch(
      'https://n8n.srv1427028.hstgr.cloud/webhook/efd6356f-aa9b-4cf8-aaeb-fb49f8ceca89',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      }
    );

    if (!res.ok) throw new Error('Network response was not ok');

    form.reset();
    formSuccess.textContent = "Thank you! We'll be in touch soon.";
    formSuccess.classList.add('show');
    setTimeout(() => formSuccess.classList.remove('show'), 5000);
  } catch (err) {
    console.error('Form submission error:', err);
    formSuccess.textContent = 'Something went wrong. Please try again or email Quinn directly.';
    formSuccess.style.color = '#9e2a2b';
    formSuccess.classList.add('show');
    setTimeout(() => {
      formSuccess.classList.remove('show');
      formSuccess.style.color = '';
      formSuccess.textContent = "Thank you! We'll be in touch soon.";
    }, 5000);
  } finally {
    btn.textContent = 'Send Message';
    btn.disabled = false;
  }
});
