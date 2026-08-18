(function () {
  'use strict';

  const languageButtons = document.querySelectorAll('[data-lang]');
  const status = document.querySelector('#copy-status');
  const copyButton = document.querySelector('#copy-install');
  const installCommand = document.querySelector('#install-code').textContent;
  const demo = document.querySelector('.demo-shell');
  const demoStatus = document.querySelector('#demo-status-text');
  const demoOutput = document.querySelector('#demo-output');
  const outputTexts = {
    'en': 'Refactor this useEffect hook, then add retry logic to the FastAPI endpoint.',
    'zh-Hant': '幫我 refactor 這個 useEffect hook，然後在 FastAPI endpoint 加上 retry logic。'
  };
  const settingsImage = document.querySelector('#settings-image');
  const phaseLabels = {
    ready: ['Ready', '準備好了'],
    listening: ['Listening', '聆聽中'],
    processing: ['Processing', '處理中'],
    typing: ['Typing at cursor', '輸入至游標'],
    done: ['Done', '完成']
  };
  const phases = ['ready', 'listening', 'processing', 'typing', 'done'];

  function setLanguage(language, announce) {
    const nextLanguage = language === 'en' ? 'en' : 'zh-Hant';
    document.documentElement.lang = nextLanguage;
    try { localStorage.setItem('lasay-language', nextLanguage); } catch (_) {}
    languageButtons.forEach(button => button.setAttribute('aria-pressed', String(button.dataset.lang === nextLanguage)));
    if (settingsImage) {
      settingsImage.src = nextLanguage === 'en' ? 'assets/settings-en.png' : 'assets/settings-zh.png';
      settingsImage.alt = nextLanguage === 'en'
        ? 'LaSay Settings: offline transcription, automatic language detection, shortcut, and launch at login.'
        : 'LaSay 設定：離線辨識、自動偵測語言、快捷鍵與登入啟動。';
    }
    if (announce) {
      const label = nextLanguage === 'en' ? 'Language changed to English' : '語言已切換為繁體中文';
      document.querySelector('#language-status')?.remove();
      const announcement = document.createElement('span');
      announcement.id = 'language-status';
      announcement.className = 'sr-only';
      announcement.setAttribute('aria-live', 'polite');
      announcement.textContent = label;
      document.body.append(announcement);
    }
    if (demo) setDemoPhase(demo.dataset.phase || 'ready');
  }

  languageButtons.forEach(button => button.addEventListener('click', () => setLanguage(button.dataset.lang, true)));
  setLanguage(document.documentElement.lang);

  async function copyInstallCommand() {
    try {
      await navigator.clipboard.writeText(installCommand);
    } catch (_) {
      const field = document.createElement('textarea');
      field.value = installCommand;
      field.setAttribute('readonly', '');
      field.style.position = 'fixed';
      field.style.opacity = '0';
      document.body.append(field);
      field.select();
      document.execCommand('copy');
      field.remove();
    }
    status.textContent = document.documentElement.lang === 'en' ? 'Install command copied' : '安裝指令已複製';
    copyButton.dataset.copied = 'true';
    window.setTimeout(() => { copyButton.dataset.copied = 'false'; }, 1800);
  }

  copyButton.addEventListener('click', copyInstallCommand);

  function updateDemoStatus(phase) {
    const labels = phaseLabels[phase] || phaseLabels.ready;
    demoStatus.textContent = document.documentElement.lang === 'en' ? labels[0] : labels[1];
  }

  function demoOutputText() {
    return outputTexts[document.documentElement.lang] || outputTexts['zh-Hant'];
  }

  function setDemoPhase(phase) {
    const nextPhase = phases.includes(phase) ? phase : 'ready';
    demo.dataset.phase = nextPhase;
    updateDemoStatus(nextPhase);
    const outputText = demoOutputText();
    if (nextPhase === 'typing' || nextPhase === 'done') demoOutput.textContent = outputText.slice(0, nextPhase === 'done' ? outputText.length : Math.max(1, Math.floor(outputText.length * .58)));
    else demoOutput.textContent = '';
  }

  function runDemo() {
    const params = new URLSearchParams(window.location.search);
    const requestedPhase = params.get('demoPhase');
    if (requestedPhase && phases.includes(requestedPhase)) {
      setDemoPhase(requestedPhase);
      const requestedProgress = Number(params.get('demoProgress'));
      if (requestedPhase === 'typing' && Number.isFinite(requestedProgress)) {
        const progress = Math.min(100, Math.max(0, requestedProgress));
        const outputText = demoOutputText();
        demoOutput.textContent = outputText.slice(0, Math.round(outputText.length * progress / 100));
      }
      return;
    }

    let phaseIndex = 0;
    let typingTimer;
    function advance() {
      const phase = phases[phaseIndex];
      setDemoPhase(phase);
      if (typingTimer) window.clearInterval(typingTimer);
      if (phase === 'typing') {
        let index = 0;
        typingTimer = window.setInterval(() => {
          const outputText = demoOutputText();
          demoOutput.textContent = outputText.slice(0, index += 1);
          if (index >= outputText.length) window.clearInterval(typingTimer);
        }, 55);
      }
      phaseIndex = (phaseIndex + 1) % phases.length;
      window.setTimeout(advance, phase === 'listening' ? 2700 : phase === 'processing' ? 1550 : phase === 'typing' ? 4300 : phase === 'done' ? 2300 : 1900);
    }
    advance();
  }

  setDemoPhase('ready');
  runDemo();
}());
