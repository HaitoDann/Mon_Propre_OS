(function () {
  'use strict';

  var reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var body = document.body;

  /* ---- Dernière ISO publiée (GitHub Releases de VinX_OS) ---- */
  fetch('https://api.github.com/repos/HaitoDann/VinX_OS/releases/latest')
    .then(function (r) { if (!r.ok) throw r; return r.json(); })
    .then(function (data) {
      var iso = (data.assets || []).filter(function (a) { return /\.iso$/.test(a.name); })[0];
      var sums = (data.assets || []).filter(function (a) { return /^SHA256SUMS$/.test(a.name); })[0];
      if (iso) document.querySelectorAll('[data-dl="iso"]').forEach(function (el) { el.href = iso.browser_download_url; });
      if (sums) document.querySelectorAll('[data-dl="sums"]').forEach(function (el) { el.href = sums.browser_download_url; });
      var mb = iso ? ' · ' + (iso.size / 1073741824).toFixed(1).replace('.', ',') + ' Go' : '';
      document.querySelectorAll('[data-dl-version]').forEach(function (el) {
        el.textContent = 'Version ' + data.tag_name.replace(/^(iso-|shell-)?v/, '') + ' · Debian 13 · 64 bits' + mb;
      });
    })
    .catch(function () {
      document.querySelectorAll('[data-dl-version]').forEach(function (el) { el.textContent = 'Debian 13 « trixie » · PC 64 bits'; });
    });

  /* ---- Menu mobile ---- */
  var toggle = document.querySelector('.nav-toggle');
  var links  = document.querySelector('.nav-links');
  if (toggle && links) {
    toggle.addEventListener('click', function () {
      var open = links.classList.toggle('open');
      toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
    });
    links.querySelectorAll('a').forEach(function (a) {
      a.addEventListener('click', function () {
        links.classList.remove('open');
        toggle.setAttribute('aria-expanded', 'false');
      });
    });
  }

  /* ---- Barre de navigation + bouton retour en haut (au scroll) ---- */
  var header = document.querySelector('.site-header');
  var toTop  = document.querySelector('.to-top');
  function onScroll() {
    var y = window.scrollY || window.pageYOffset;
    if (header) header.classList.toggle('scrolled', y > 52);
    if (toTop)  toTop.classList.toggle('show', y > 600);
  }
  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll();

  if (toTop) {
    toTop.addEventListener('click', function () {
      window.scrollTo({ top: 0, behavior: reduce ? 'auto' : 'smooth' });
    });
  }

  /* ---- Apparition au scroll (fade + slide) ---- */
  if (!reduce && 'IntersectionObserver' in window) {
    body.classList.add('js-reveal');

    var revealEls = Array.prototype.slice.call(document.querySelectorAll('.reveal'));

    document.querySelectorAll('[data-stagger]').forEach(function (group) {
      Array.prototype.slice.call(group.children).forEach(function (child, i) {
        child.classList.add('reveal');
        child.style.transitionDelay = (i * 70) + 'ms';
        revealEls.push(child);
      });
    });

    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add('in');
          io.unobserve(entry.target);
        }
      });
    }, { threshold: 0.12, rootMargin: '0px 0px -40px 0px' });

    revealEls.forEach(function (el) { io.observe(el); });
  }

  /* ---- Vague animée : couper si mouvement réduit ---- */
  if (reduce) {
    var waveAnim = document.getElementById('waveAnim');
    if (waveAnim && waveAnim.parentNode) waveAnim.parentNode.removeChild(waveAnim);
  }

  /* ---- Année courante ---- */
  var yearEl = document.getElementById('year');
  if (yearEl) yearEl.textContent = new Date().getFullYear();

  /* ---- Carousel screenshots ---- */
  var carousel = document.querySelector('.screenshot-carousel');
  if (carousel) {
    var slideImgs = Array.prototype.slice.call(carousel.querySelectorAll('.screenshot-img'));
    var slideTabs = Array.prototype.slice.call(carousel.querySelectorAll('.stab'));
    var available = [];
    var currentPos = 0;
    var carouselTimer = null;

    function carouselShow(imgIdx) {
      slideImgs.forEach(function (img, i) { img.classList.toggle('active', i === imgIdx); });
      slideTabs.forEach(function (tab) { tab.classList.toggle('active', parseInt(tab.dataset.view) === imgIdx); });
    }

    function carouselNext() {
      if (available.length < 2) return;
      currentPos = (currentPos + 1) % available.length;
      carouselShow(available[currentPos]);
    }

    function carouselResetTimer() {
      clearInterval(carouselTimer);
      if (!reduce && available.length > 1) carouselTimer = setInterval(carouselNext, 4000);
    }

    slideImgs.forEach(function (img, i) {
      function onLoad() {
        if (available.indexOf(i) !== -1) return;
        available.push(i);
        available.sort(function (a, b) { return a - b; });
        if (available.length === 1) { currentPos = 0; carouselShow(i); }
        if (available.length === 2) carouselResetTimer();
      }
      function onError() {
        if (slideTabs[i]) slideTabs[i].style.display = 'none';
      }
      if (img.complete) { img.naturalWidth > 0 ? (img.classList.add('loaded'), onLoad()) : onError(); }
      else { img.addEventListener('load', function () { img.classList.add('loaded'); onLoad(); }); img.addEventListener('error', onError); }
    });

    slideTabs.forEach(function (tab) {
      tab.addEventListener('click', function () {
        var idx = parseInt(tab.dataset.view);
        var pos = available.indexOf(idx);
        if (pos === -1) return;
        currentPos = pos;
        carouselShow(idx);
        carouselResetTimer();
      });
    });
  }
})();
