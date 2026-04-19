import assert from 'node:assert/strict';
import http from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { readFile } from 'node:fs/promises';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, '..', '..');
const publicDir = path.join(repoRoot, 'app', 'public');
let chromiumLauncher = null;

const bootstrapStub = `
(() => {
  const instances = new WeakMap();
  class Modal {
    constructor(element) {
      this.element = element;
      instances.set(element, this);
    }
    show() {
      this.element.classList.add('show');
      this.element.style.display = 'block';
      this.element.setAttribute('aria-hidden', 'false');
      document.body.classList.add('modal-open');
      this.bindDismiss();
      if (!document.querySelector('.modal-backdrop')) {
        const backdrop = document.createElement('div');
        backdrop.className = 'modal-backdrop';
        document.body.appendChild(backdrop);
      }
    }
    hide() {
      this.element.classList.remove('show');
      this.element.style.display = 'none';
      this.element.setAttribute('aria-hidden', 'true');
      document.body.classList.remove('modal-open');
      document.querySelectorAll('.modal-backdrop').forEach((node) => node.remove());
      this.element.dispatchEvent(new Event('hidden.bs.modal', { bubbles: true }));
    }
    bindDismiss() {
      this.element.querySelectorAll('[data-bs-dismiss="modal"]').forEach((button) => {
        button.onclick = (event) => {
          event.preventDefault();
          this.hide();
        };
      });
    }
  }
  class Toast {
    constructor(element) {
      this.element = element;
    }
    show() {
      this.element.classList.add('show');
    }
  }
  window.bootstrap = { Modal, Toast };
})();
`;

const terminalStub = `
(() => {
  class FakeTerminal {
    constructor() {
      this.cols = 80;
      this.rows = 24;
      this._dataHandler = null;
    }
    loadAddon(addon) {
      this._addon = addon;
    }
    open() {}
    clear() {}
    write() {}
    writeln() {}
    onData(handler) {
      this._dataHandler = handler;
      return {
        dispose: () => {
          this._dataHandler = null;
        }
      };
    }
  }
  class FakeFitAddon {
    fit() {}
  }
  window.Terminal = FakeTerminal;
  window.FitAddon = { FitAddon: FakeFitAddon };
})();
`;

const socketIoStub = `
(() => {
  window.io = function fakeIo() {
    const handlers = {};
    return {
      connected: false,
      on(event, handler) {
        handlers[event] = handler;
      },
      off(event) {
        delete handlers[event];
      },
      emit() {},
      connect() {
        this.connected = true;
        if (handlers.connect) {
          handlers.connect();
        }
      },
      disconnect() {
        this.connected = false;
      }
    };
  };
})();
`;

const markdownStub = `
(() => {
  window.marked = {
    setOptions() {},
    parse(markdownText) {
      return '<pre>' + String(markdownText)
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;') + '</pre>';
    }
  };
})();
`;

const highlightStub = `
(() => {
  window.hljs = {
    getLanguage() {
      return true;
    },
    highlight(code) {
      return { value: code };
    },
    highlightAuto(code) {
      return { value: code };
    },
    highlightElement() {}
  };
})();
`;

const emptyCss = '/* smoke stub */';

function buildExamResult({
  examId,
  totalScore,
  totalPossibleScore,
  rank,
  completedAt,
  evaluationResults
}) {
  return {
    examId,
    totalScore,
    totalPossibleScore,
    rank,
    completedAt,
    evaluationResults
  };
}

function buildQuestionResult(questionId, verificationMatrix) {
  return {
    id: String(questionId),
    verificationResults: verificationMatrix.map(([id, description, validAnswer, weightage = 1]) => ({
      id: String(id),
      description,
      validAnswer,
      score: validAnswer ? weightage : 0,
      weightage
    }))
  };
}

function contentTypeFor(filePath) {
  if (filePath.endsWith('.html')) return 'text/html; charset=utf-8';
  if (filePath.endsWith('.js')) return 'application/javascript; charset=utf-8';
  if (filePath.endsWith('.css')) return 'text/css; charset=utf-8';
  if (filePath.endsWith('.svg')) return 'image/svg+xml';
  if (filePath.endsWith('.json')) return 'application/json; charset=utf-8';
  return 'text/plain; charset=utf-8';
}

async function servePublicAsset(reqPath, res) {
  const routeAliases = {
    '/index': '/index.html',
    '/exam': '/exam.html',
    '/results': '/results.html',
    '/answers': '/answers.html'
  };
  const resolvedPath = routeAliases[reqPath] ?? (reqPath === '/' ? '/index.html' : reqPath);
  const normalized = path.normalize(resolvedPath).replace(/^(\.\.(\/|\\|$))+/, '');
  const filePath = path.join(publicDir, normalized);

  try {
    const content = await readFile(filePath);
    res.writeHead(200, { 'Content-Type': contentTypeFor(filePath) });
    res.end(content);
  } catch {
    res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end('not found');
  }
}

function writeJson(res, statusCode, payload) {
  res.writeHead(statusCode, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(payload));
}

function buildFixtureServer() {
  const fixtureLabs = [
    {
      id: 'ckad-003',
      category: 'CKAD',
      name: 'CKAD Quick Drill - Deployment Basics',
      description: 'Fixture CKAD drill.',
      difficulty: 'Easy',
      examDurationInMinutes: 15
    },
    {
      id: 'cka-016',
      category: 'CKA',
      track: 'planning-focused',
      name: 'CKA 2026 Single Domain Drill - Kubeadm Lifecycle Planning',
      description: 'Fixture planning-focused drill.',
      difficulty: 'Medium',
      examDurationInMinutes: 20
    },
    {
      id: 'cka-020',
      category: 'CKA',
      track: 'hands-on',
      name: 'CKA 2026 Single Domain Drill - Service and Pod Connectivity Diagnostics',
      description: 'Fixture hands-on drill.',
      difficulty: 'Medium',
      examDurationInMinutes: 20
    },
    {
      id: 'cka-024',
      category: 'CKA',
      track: 'ops-diagnostics',
      name: 'CKA 2026 Single Domain Drill - Resource quota and LimitRange troubleshooting',
      description: 'Fixture ops diagnostics drill.',
      difficulty: 'Medium',
      examDurationInMinutes: 20
    }
  ];

  const initialResults = buildExamResult({
    examId: 'fixture-results',
    totalScore: 1,
    totalPossibleScore: 2,
    rank: 'medium',
    completedAt: '2026-04-10T05:59:30.000Z',
    evaluationResults: [
      buildQuestionResult(1, [
        [1, 'Initial verification failed before re-evaluation.', false],
        [2, 'Initial verification passed before re-evaluation.', true]
      ])
    ]
  });

  const reEvaluatedResults = buildExamResult({
    examId: 'fixture-results',
    totalScore: 2,
    totalPossibleScore: 2,
    rank: 'high',
    completedAt: '2026-04-10T05:59:43.000Z',
    evaluationResults: [
      buildQuestionResult(1, [
        [1, 'Initial verification failed before re-evaluation.', true],
        [2, 'Initial verification passed before re-evaluation.', true]
      ])
    ]
  });

  const reviewResults = buildExamResult({
    examId: 'fixture-review',
    totalScore: 3,
    totalPossibleScore: 3,
    rank: 'high',
    completedAt: '2026-04-10T05:58:20.000Z',
    evaluationResults: [
      buildQuestionResult(1, [
        [1, 'Review session is available.', true],
        [2, 'Questions were restored for review.', true],
        [3, 'Results link remains available.', true]
      ])
    ]
  });

  const retryRecoveredResults = buildExamResult({
    examId: 'fixture-retry',
    totalScore: 2,
    totalPossibleScore: 2,
    rank: 'high',
    completedAt: '2026-04-10T06:01:12.000Z',
    evaluationResults: [
      buildQuestionResult(1, [
        [1, 'Retry flow restored the results page.', true],
        [2, 'Recovered score is rendered after retry.', true]
      ])
    ]
  });

  const feedbackSuccessResults = buildExamResult({
    examId: 'fixture-feedback-success',
    totalScore: 2,
    totalPossibleScore: 2,
    rank: 'high',
    completedAt: '2026-04-10T06:02:05.000Z',
    evaluationResults: [
      buildQuestionResult(1, [
        [1, 'Feedback prompt can appear after results load.', true],
        [2, 'Feedback submission can succeed.', true]
      ])
    ]
  });

  const feedbackFailureResults = buildExamResult({
    examId: 'fixture-feedback-failure',
    totalScore: 1,
    totalPossibleScore: 2,
    rank: 'medium',
    completedAt: '2026-04-10T06:02:25.000Z',
    evaluationResults: [
      buildQuestionResult(1, [
        [1, 'Feedback submission can surface an error toast.', true],
        [2, 'Results remain visible underneath the failure state.', false]
      ])
    ]
  });

  const state = {
    mode: 'index',
    currentExamChecks: 0,
    examStartTime: Date.now() - 60_000,
    resultsExam: {
      phase: 'baseline',
      statusChecks: 0,
      initialResults,
      reEvaluatedResults
    },
    retryExam: {
      recovered: false
    }
  };

  const server = http.createServer(async (req, res) => {
    const url = new URL(req.url, 'http://127.0.0.1');
    const { pathname } = url;

    if (pathname === '/favicon.ico') {
      res.writeHead(204);
      res.end();
      return;
    }

    if (pathname === '/api/vnc-info') {
      writeJson(res, 200, { defaultPassword: 'fixture-password' });
      return;
    }

    if (pathname === '/vnc-proxy/' || pathname === '/vnc-proxy') {
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
      res.end('<html><body>fixture vnc proxy</body></html>');
      return;
    }

    if (pathname === '/socket.io/' || pathname.startsWith('/socket.io/')) {
      res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('socket mock');
      return;
    }

    if (pathname === '/facilitator/api/v1/assessments/' || pathname === '/facilitator/api/v1/assessments') {
      writeJson(res, 200, fixtureLabs);
      return;
    }

    if (pathname === '/facilitator/api/v1/exams/current') {
      if (state.mode === 'index') {
        state.currentExamChecks += 1;
        if (state.currentExamChecks === 1) {
          writeJson(res, 404, { error: 'Not Found', message: 'No active exam' });
          return;
        }

        const examName = state.currentExamChecks === 2 ? 'CKA Alpha' : 'CKA Beta';
        writeJson(res, 200, {
          id: `fixture-index-${state.currentExamChecks}`,
          status: 'READY',
          info: {
            name: examName
          }
        });
        return;
      }

      if (state.mode === 'index-results') {
        writeJson(res, 200, {
          id: 'fixture-results',
          status: 'EVALUATED',
          info: {
            name: 'Fixture Results'
          }
        });
        return;
      }

      if (state.mode === 'review') {
        writeJson(res, 200, {
          id: 'fixture-review',
          status: 'EVALUATED',
          info: {
            name: 'Fixture Review',
            examDurationInMinutes: 120,
            events: {
              examStartTime: state.examStartTime,
              examEndTime: state.examStartTime + 60_000
            }
          }
        });
        return;
      }

      writeJson(res, 200, {
        id: 'fixture-exam',
        status: 'READY',
        info: {
          name: 'Fixture Exam',
          examDurationInMinutes: 120,
          events: {
            examStartTime: state.examStartTime
          }
        }
      });
      return;
    }

    if (pathname === '/facilitator/api/v1/exams/fixture-exam/status') {
      writeJson(res, 200, {
        id: 'fixture-exam',
        status: 'READY',
        warmUpTimeInSeconds: 30
      });
      return;
    }

    if (pathname === '/facilitator/api/v1/exams/fixture-review/status') {
      writeJson(res, 200, {
        id: 'fixture-review',
        status: 'EVALUATED',
        warmUpTimeInSeconds: 30
      });
      return;
    }

    if (pathname === '/facilitator/api/v1/exams/fixture-exam/questions') {
      writeJson(res, 200, {
        questions: [
          {
            id: '1',
            question: 'Inspect the fixture workload and verify terminal toggle behavior.',
            namespace: 'default',
            concepts: ['debugging'],
            machineHostname: 'ckad9999'
          }
        ]
      });
      return;
    }

    if (pathname === '/facilitator/api/v1/exams/fixture-review/questions') {
      writeJson(res, 200, {
        questions: [
          {
            id: '1',
            question: 'Review the completed fixture exam session.',
            namespace: 'default',
            concepts: ['review'],
            machineHostname: 'ckad9999'
          }
        ]
      });
      return;
    }

    if (pathname === '/facilitator/api/v1/exams/fixture-exam/events') {
      writeJson(res, 200, { success: true });
      return;
    }

    if (pathname === '/facilitator/api/v1/exams/fixture-exam/evaluate') {
      writeJson(res, 200, { success: true });
      return;
    }

    if (pathname === '/facilitator/api/v1/exams/fixture-exam/terminate') {
      writeJson(res, 200, { success: true, message: 'Fixture exam terminated' });
      return;
    }

    if (/^\/facilitator\/api\/v1\/exams\/fixture-index-\d+\/terminate$/.test(pathname)) {
      writeJson(res, 200, { success: true, message: 'Fixture index exam terminated' });
      return;
    }

    if (pathname === '/facilitator/api/v1/exams/fixture-results/evaluate') {
      state.resultsExam.phase = 'evaluating';
      state.resultsExam.statusChecks = 0;
      writeJson(res, 200, { success: true, status: 'EVALUATING' });
      return;
    }

    if (pathname === '/facilitator/api/v1/exams/fixture-results/terminate') {
      writeJson(res, 200, { success: true, message: 'Session terminated' });
      return;
    }

    if (pathname === '/facilitator/api/v1/exams/fixture-results/status') {
      if (state.resultsExam.phase === 'evaluating') {
        state.resultsExam.statusChecks += 1;
        if (state.resultsExam.statusChecks >= 2) {
          state.resultsExam.phase = 'evaluated';
          writeJson(res, 200, {
            id: 'fixture-results',
            status: 'EVALUATED'
          });
          return;
        }

        writeJson(res, 200, {
          id: 'fixture-results',
          status: 'EVALUATING'
        });
        return;
      }

      writeJson(res, 200, {
        id: 'fixture-results',
        status: 'EVALUATED'
      });
      return;
    }

    if (pathname === '/facilitator/api/v1/exams/fixture-failed/status') {
      writeJson(res, 200, {
        id: 'fixture-failed',
        status: 'EVALUATION_FAILED'
      });
      return;
    }

    if (pathname === '/facilitator/api/v1/exams/fixture-review/result') {
      writeJson(res, 200, { data: reviewResults });
      return;
    }

    if (pathname === '/facilitator/api/v1/exams/fixture-results/answers') {
      res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('# Fixture Answers\n\n- Recovery step 1\n- Recovery step 2\n');
      return;
    }

    if (pathname === '/facilitator/api/v1/exams/fixture-results/result') {
      const payload = state.resultsExam.phase === 'evaluated'
        ? state.resultsExam.reEvaluatedResults
        : state.resultsExam.initialResults;
      writeJson(res, 200, { data: payload });
      return;
    }

    if (pathname === '/facilitator/api/v1/exams/fixture-failed/result') {
      writeJson(res, 404, {
        error: 'Not Found',
        message: 'Exam evaluation result not found'
      });
      return;
    }

    if (pathname === '/facilitator/api/v1/exams/fixture-retry/status') {
      if (!state.retryExam.recovered) {
        state.retryExam.recovered = true;
        writeJson(res, 200, {
          id: 'fixture-retry',
          status: 'EVALUATION_FAILED'
        });
        return;
      }

      writeJson(res, 200, {
        id: 'fixture-retry',
        status: 'EVALUATED'
      });
      return;
    }

    if (pathname === '/facilitator/api/v1/exams/fixture-retry/result') {
      if (!state.retryExam.recovered) {
        writeJson(res, 404, {
          error: 'Not Found',
          message: 'Exam evaluation result not found'
        });
        return;
      }

      writeJson(res, 200, { data: retryRecoveredResults });
      return;
    }

    if (pathname === '/facilitator/api/v1/exams/fixture-feedback-success/result') {
      writeJson(res, 200, { data: feedbackSuccessResults });
      return;
    }

    if (pathname === '/facilitator/api/v1/exams/fixture-feedback-failure/result') {
      writeJson(res, 200, { data: feedbackFailureResults });
      return;
    }

    if (pathname === '/facilitator/api/v1/exams/metrics/fixture-feedback-success') {
      writeJson(res, 200, { success: true });
      return;
    }

    if (pathname === '/facilitator/api/v1/exams/metrics/fixture-feedback-failure') {
      writeJson(res, 500, {
        error: 'Feedback submission failed'
      });
      return;
    }

    await servePublicAsset(pathname, res);
  });

  return { server, state };
}

async function launchBrowser() {
  if (!chromiumLauncher) {
    ({ chromium: chromiumLauncher } = await import('playwright'));
  }

  try {
    return await chromiumLauncher.launch({ headless: true });
  } catch (error) {
    if (!error.message.includes('Executable')) {
      throw error;
    }

    return chromiumLauncher.launch({
      headless: true,
      executablePath: '/usr/bin/google-chrome',
      args: ['--no-sandbox', '--disable-dev-shm-usage']
    });
  }
}

async function stubExternalAssets(context) {
  await context.route('https://cdn.jsdelivr.net/**', async (route) => {
    const requestUrl = route.request().url();
    if (requestUrl.endsWith('bootstrap.bundle.min.js')) {
      await route.fulfill({ status: 200, contentType: 'application/javascript', body: bootstrapStub });
      return;
    }
    if (requestUrl.includes('/xterm@') && requestUrl.endsWith('/xterm.min.js')) {
      await route.fulfill({ status: 200, contentType: 'application/javascript', body: terminalStub });
      return;
    }
    if (requestUrl.includes('xterm-addon-fit') && requestUrl.endsWith('.js')) {
      await route.fulfill({ status: 200, contentType: 'application/javascript', body: '' });
      return;
    }
    if (requestUrl.includes('socket.io-client') && requestUrl.endsWith('.js')) {
      await route.fulfill({ status: 200, contentType: 'application/javascript', body: socketIoStub });
      return;
    }
    if (requestUrl.includes('/marked/') && requestUrl.endsWith('.js')) {
      await route.fulfill({ status: 200, contentType: 'application/javascript', body: markdownStub });
      return;
    }
    if (requestUrl.endsWith('.css')) {
      await route.fulfill({ status: 200, contentType: 'text/css', body: emptyCss });
      return;
    }
    await route.fulfill({ status: 200, contentType: 'application/javascript', body: '' });
  });

  await context.route('https://cdnjs.cloudflare.com/**', async (route) => {
    const requestUrl = route.request().url();
    if (requestUrl.endsWith('.css')) {
      await route.fulfill({ status: 200, contentType: 'text/css', body: emptyCss });
      return;
    }
    if (requestUrl.endsWith('.js')) {
      await route.fulfill({ status: 200, contentType: 'application/javascript', body: highlightStub });
      return;
    }
    await route.fulfill({ status: 204, body: '' });
  });

  await context.route('https://fonts.googleapis.com/**', async (route) => {
    await route.fulfill({ status: 200, contentType: 'text/css', body: emptyCss });
  });

  await context.route('https://fonts.gstatic.com/**', async (route) => {
    await route.fulfill({ status: 204, body: '' });
  });

  await context.addInitScript(() => {
    window.alert = () => {};
    document.exitFullscreen = async () => {};
    window.localStorage.setItem('ckx_feedback_submitted', 'true');
    const originalSetInterval = window.setInterval.bind(window);
    window.setInterval = (handler, timeout, ...args) => {
      return originalSetInterval(handler, Math.min(timeout, 50), ...args);
    };
    if (!Element.prototype.requestFullscreen) {
      Element.prototype.requestFullscreen = async () => {};
    }
  });
}

async function waitForModalState(page, selector, displayValue) {
  await page.waitForFunction(
    ({ modalSelector, value }) => {
      const element = document.querySelector(modalSelector);
      return Boolean(element) && window.getComputedStyle(element).display === value;
    },
    { modalSelector: selector, value: displayValue }
  );
}

async function runIndexSmoke(page, baseUrl, state) {
  state.mode = 'index';
  state.currentExamChecks = 0;

  await page.goto(`${baseUrl}/`, { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('#startExamBtn');

  await page.click('#startExamBtn');
  await waitForModalState(page, '#activeExamWarningModal', 'block');
  const firstModalText = await page.locator('#activeExamWarningModal #activeExamName').textContent();
  assert.match(firstModalText ?? '', /CKA Alpha/);

  await page.click('#activeExamWarningModal .btn-close');
  await waitForModalState(page, '#activeExamWarningModal', 'none');

  await page.click('#startExamBtn');
  await waitForModalState(page, '#activeExamWarningModal', 'block');
  const secondModalText = await page.locator('#activeExamWarningModal #activeExamName').textContent();
  assert.match(secondModalText ?? '', /CKA Beta/);
  assert.equal(await page.locator('#activeExamWarningModal').count(), 1);

  await page.locator('#terminateAndProceedBtn').click();
  await waitForModalState(page, '#examSelectionModal', 'block');

  await page.waitForFunction(() => {
    const trackGroup = document.getElementById('examTrackGroup');
    return trackGroup && window.getComputedStyle(trackGroup).display === 'none';
  });

  await page.selectOption('#examCategory', 'CKA');
  await page.waitForFunction(() => {
    const trackGroup = document.getElementById('examTrackGroup');
    const trackSelect = document.getElementById('examTrack');
    return trackGroup &&
      trackSelect &&
      window.getComputedStyle(trackGroup).display === 'block' &&
      Array.from(trackSelect.options).some((option) => option.value === 'planning-focused') &&
      Array.from(trackSelect.options).some((option) => option.value === 'ops-diagnostics') &&
      Array.from(trackSelect.options).some((option) => option.value === 'hands-on');
  });

  const trackOptions = await page.$$eval('#examTrack option', (options) =>
    options.map((option) => option.textContent?.trim() ?? '')
  );
  assert.deepEqual(trackOptions, ['All tracks (3)', 'Hands-on (1)', 'Ops diagnostics (1)', 'Planning-focused (1)']);
  assert.equal(await page.locator('#examTrack').inputValue(), 'hands-on');

  await page.waitForFunction(() => {
    const examName = document.getElementById('examName');
    if (!examName) return false;
    const values = Array.from(examName.options).map((option) => option.value);
    return values.includes('premium_CKA') &&
      values.includes('cka-020') &&
      !values.includes('cka-016') &&
      !values.includes('cka-024');
  });
  assert.equal(await page.locator('#examName').inputValue(), 'cka-020');

  await page.selectOption('#examTrack', 'planning-focused');
  await page.waitForFunction(() => {
    const examName = document.getElementById('examName');
    if (!examName) return false;
    const values = Array.from(examName.options).map((option) => option.value);
    return values.includes('premium_CKA') &&
      values.includes('cka-016') &&
      !values.includes('cka-020') &&
      !values.includes('cka-024');
  });
  assert.equal(await page.locator('#examName').inputValue(), 'cka-016');

  await page.selectOption('#examName', 'cka-016');
  await page.waitForFunction(() => {
    const description = document.getElementById('examDescription');
    const badge = description?.querySelector('.badge');
    return description &&
      badge &&
      window.getComputedStyle(description).display === 'block' &&
      badge.textContent?.includes('Planning-focused');
  });
}

async function runIndexViewResultsSmoke(page, baseUrl, state) {
  state.mode = 'index-results';

  await page.goto(`${baseUrl}/`, { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => {
    const button = document.getElementById('viewPastResultsBtn');
    return button && window.getComputedStyle(button.closest('li')).display === 'block';
  });

  await page.locator('#viewPastResultsBtn').click();
  await page.waitForURL(/\/results\?id=fixture-results/);
  await page.waitForFunction(() => {
    const results = document.getElementById('resultsContent');
    const examId = document.getElementById('examId');
    return results &&
      examId &&
      window.getComputedStyle(results).display === 'block' &&
      examId.textContent === 'Exam ID: fixture-results';
  });
}

async function runExamSmoke(page, baseUrl, state) {
  state.mode = 'exam';

  await page.goto(`${baseUrl}/exam.html?id=fixture-exam`, { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('#startExamBtn');
  await waitForModalState(page, '#startExamModal', 'block');

  const startLabel = await page.locator('#startExamBtn').textContent();
  assert.match(startLabel ?? '', /Continue Session/);

  await page.click('#startExamBtn');
  await waitForModalState(page, '#startExamModal', 'none');
  await page.waitForTimeout(200);

  const toggleButton = page.locator('#toggleViewBtn');
  await toggleButton.click();

  await page.waitForFunction(() => {
    const terminal = document.getElementById('sshTerminalContainer');
    const vnc = document.querySelector('.terminal-container');
    const toggle = document.getElementById('toggleViewBtn');
    return terminal && vnc && toggle &&
      window.getComputedStyle(terminal).display === 'flex' &&
      window.getComputedStyle(vnc).display === 'none' &&
      toggle.textContent === 'Switch to Remote Desktop';
  });

  await toggleButton.click();

  await page.waitForFunction(() => {
    const terminal = document.getElementById('sshTerminalContainer');
    const vnc = document.querySelector('.terminal-container');
    const toggle = document.getElementById('toggleViewBtn');
    return terminal && vnc && toggle &&
      window.getComputedStyle(terminal).display === 'none' &&
      window.getComputedStyle(vnc).display === 'flex' &&
      toggle.textContent === 'Switch to Terminal';
  });
}

async function runExamTerminateSmoke(page, baseUrl, state) {
  state.mode = 'exam';

  await page.goto(`${baseUrl}/exam.html?id=fixture-exam`, { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('#startExamBtn');
  await waitForModalState(page, '#startExamModal', 'block');
  await page.click('#startExamBtn');
  await waitForModalState(page, '#startExamModal', 'none');

  await page.locator('#terminateSessionBtn').click({ force: true });
  await waitForModalState(page, '#terminateModal', 'block');
  await page.locator('#confirmTerminateBtn').click();
  await page.waitForURL(`${baseUrl}/`);
}

async function runCompletedExamReviewSmoke(page, baseUrl, state) {
  state.mode = 'review';

  await page.goto(`${baseUrl}/exam.html?id=fixture-review`, { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('#connectToSessionBtn');
  await waitForModalState(page, '#examCompletedModal', 'block');

  await page.click('#connectToSessionBtn');

  await page.waitForFunction(() => {
    const badge = document.querySelector('.review-mode-badge');
    const viewResults = Array.from(document.querySelectorAll('.header-controls .btn-custom'))
      .some((button) => button.textContent === 'View Results');
    return Boolean(badge) && viewResults;
  });

  await page.getByRole('button', { name: 'View Results' }).click();
  await page.waitForURL(/\/results\?id=fixture-review/);
  await page.waitForFunction(() => {
    const results = document.getElementById('resultsContent');
    const examId = document.getElementById('examId');
    return results &&
      examId &&
      window.getComputedStyle(results).display === 'block' &&
      examId.textContent === 'Exam ID: fixture-review';
  });
}

async function runResultsReEvaluationSmoke(page, baseUrl, state) {
  state.resultsExam.phase = 'baseline';
  state.resultsExam.statusChecks = 0;

  await page.goto(`${baseUrl}/results?id=fixture-results`, { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => {
    const results = document.getElementById('resultsContent');
    const totalScore = document.getElementById('totalScore');
    return results &&
      totalScore &&
      window.getComputedStyle(results).display === 'block' &&
      totalScore.textContent === '1';
  });

  await page.getByRole('button', { name: /Re-evaluate Exam/i }).click();

  await page.waitForFunction(() => {
    const loader = document.getElementById('pageLoader');
    const button = document.getElementById('reEvaluateBtn');
    const results = document.getElementById('resultsContent');
    return loader &&
      button &&
      results &&
      button.disabled &&
      window.getComputedStyle(loader).display === 'flex' &&
      window.getComputedStyle(results).display === 'none';
  });

  await page.waitForFunction(() => {
    const results = document.getElementById('resultsContent');
    const button = document.getElementById('reEvaluateBtn');
    const totalScore = document.getElementById('totalScore');
    const rankText = document.getElementById('rankText');
    return results &&
      button &&
      totalScore &&
      rankText &&
      window.getComputedStyle(results).display === 'block' &&
      !button.disabled &&
      totalScore.textContent === '2' &&
      rankText.textContent === 'High Score' &&
      button.textContent.includes('Re-evaluate Exam');
  });

  assert.equal(await page.locator('.question-card').count(), 1);
  assert.equal(await page.locator('.status-success').count(), 2);
}

async function runResultsFailureSmoke(page, baseUrl) {
  await page.goto(`${baseUrl}/results?id=fixture-failed`, { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => {
    const errorMessage = document.getElementById('errorMessage');
    const errorText = document.getElementById('errorText');
    return errorMessage &&
      errorText &&
      window.getComputedStyle(errorMessage).display === 'block' &&
      errorText.textContent === 'Exam evaluation failed';
  });
}

async function runResultsRetryRecoverySmoke(page, baseUrl, state) {
  state.retryExam.recovered = false;

  await page.goto(`${baseUrl}/results?id=fixture-retry`, { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => {
    const errorMessage = document.getElementById('errorMessage');
    const errorText = document.getElementById('errorText');
    return errorMessage &&
      errorText &&
      window.getComputedStyle(errorMessage).display === 'block' &&
      errorText.textContent === 'Exam evaluation failed';
  });

  await page.locator('#retryButton').click();
  await page.waitForFunction(() => {
    const results = document.getElementById('resultsContent');
    const errorMessage = document.getElementById('errorMessage');
    const totalScore = document.getElementById('totalScore');
    const rankText = document.getElementById('rankText');
    const examId = document.getElementById('examId');
    return results &&
      errorMessage &&
      totalScore &&
      rankText &&
      examId &&
      window.getComputedStyle(results).display === 'block' &&
      window.getComputedStyle(errorMessage).display === 'none' &&
      totalScore.textContent === '2' &&
      rankText.textContent === 'High Score' &&
      examId.textContent === 'Exam ID: fixture-retry';
  });
}

async function runResultsActionSmoke(page, baseUrl) {
  await page.goto(`${baseUrl}/results?id=fixture-results`, { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => {
    const results = document.getElementById('resultsContent');
    return results && window.getComputedStyle(results).display === 'block';
  });

  const context = page.context();

  const [examPage] = await Promise.all([
    context.waitForEvent('page'),
    page.getByRole('button', { name: /Current Exam/i }).click()
  ]);
  await examPage.waitForLoadState('domcontentloaded');
  await examPage.waitForFunction(() => {
    const modal = document.getElementById('examCompletedModal');
    return modal && window.getComputedStyle(modal).display === 'block';
  });
  await examPage.close();

  const [answersPage] = await Promise.all([
    context.waitForEvent('page'),
    page.getByRole('button', { name: /View Answers/i }).click()
  ]);
  await answersPage.waitForLoadState('domcontentloaded');
  await answersPage.waitForFunction(() => {
    const content = document.getElementById('answersContent');
    const examId = document.getElementById('examId');
    const markdown = document.getElementById('markdownContent');
    return content &&
      examId &&
      markdown &&
      window.getComputedStyle(content).display === 'block' &&
      examId.textContent === 'Exam ID: fixture-results' &&
      markdown.textContent.includes('Fixture Answers');
  });
  await answersPage.close();

  await page.getByRole('button', { name: /Terminate Session/i }).click();
  await page.waitForFunction(() => {
    const modal = document.getElementById('terminateModal');
    return modal && window.getComputedStyle(modal).display === 'flex';
  });

  await page.getByRole('button', { name: /^Cancel$/i }).click();
  await page.waitForFunction(() => {
    const modal = document.getElementById('terminateModal');
    return modal && window.getComputedStyle(modal).display === 'none';
  });

  await page.getByRole('button', { name: /Terminate Session/i }).click();
  await page.waitForFunction(() => {
    const modal = document.getElementById('terminateModal');
    return modal && window.getComputedStyle(modal).display === 'flex';
  });
  await page.locator('#confirmTerminateBtn').click();
  await page.waitForURL(`${baseUrl}/`);
}

async function runResultsFeedbackSmoke(page, baseUrl) {
  await page.goto(`${baseUrl}/results?id=fixture-feedback-success`, { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => {
    const results = document.getElementById('resultsContent');
    const examId = document.getElementById('examId');
    return results &&
      examId &&
      window.getComputedStyle(results).display === 'block' &&
      examId.textContent === 'Exam ID: fixture-feedback-success';
  });

  await page.evaluate(() => {
    window.localStorage.removeItem('ckx_feedback_submitted');
    window.localStorage.removeItem('ckx_feedback_skip_until');
    window.showFeedbackModal();
  });
  await page.waitForFunction(() => {
    const modal = document.getElementById('feedbackModal');
    return modal && window.getComputedStyle(modal).display === 'flex';
  });

  await page.locator('#star5').evaluate((element) => {
    element.checked = true;
    element.dispatchEvent(new Event('change', { bubbles: true }));
  });
  await page.locator('#feedbackComment').fill('Fixture feedback success path.');
  await page.locator('#testimonialConsent').check({ force: true });
  await page.waitForFunction(() => {
    const fields = document.getElementById('testimonialFields');
    return fields && window.getComputedStyle(fields).display === 'block';
  });
  await page.locator('#testimonialName').fill('Fixture User');
  await page.locator('#testimonialSocial').fill('@fixture');
  await page.locator('#submitFeedbackBtn').click();

  await page.waitForFunction(() => {
    const modal = document.getElementById('feedbackModal');
    const toast = document.querySelector('.toast-notification .toast-message');
    return modal &&
      toast &&
      window.getComputedStyle(modal).display === 'none' &&
      toast.textContent.includes('submitted successfully');
  });
  const successSubmitted = await page.evaluate(() => window.localStorage.getItem('ckx_feedback_submitted'));
  assert.equal(successSubmitted, 'true');

  await page.goto(`${baseUrl}/results?id=fixture-feedback-failure`, { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => {
    const results = document.getElementById('resultsContent');
    const examId = document.getElementById('examId');
    return results &&
      examId &&
      window.getComputedStyle(results).display === 'block' &&
      examId.textContent === 'Exam ID: fixture-feedback-failure';
  });

  await page.evaluate(() => {
    window.localStorage.removeItem('ckx_feedback_submitted');
    window.localStorage.removeItem('ckx_feedback_skip_until');
    window.showFeedbackModal();
  });
  await page.waitForFunction(() => {
    const modal = document.getElementById('feedbackModal');
    return modal && window.getComputedStyle(modal).display === 'flex';
  });

  await page.locator('#star4').evaluate((element) => {
    element.checked = true;
    element.dispatchEvent(new Event('change', { bubbles: true }));
  });
  await page.locator('#feedbackComment').fill('Fixture feedback failure path.');
  await page.locator('#submitFeedbackBtn').click();

  await page.waitForFunction(() => {
    const modal = document.getElementById('feedbackModal');
    const toast = document.querySelector('.toast-notification .toast-message');
    return modal &&
      toast &&
      window.getComputedStyle(modal).display === 'none' &&
      toast.textContent.includes("couldn't submit your feedback");
  });
  const failureSubmitted = await page.evaluate(() => window.localStorage.getItem('ckx_feedback_submitted'));
  assert.equal(failureSubmitted, null);
}

function buildScenarioPlan(context, baseUrl, state) {
  return [
    {
      name: 'index-active-exam-warning',
      run: () => runIndexSmoke(context.mainPage, baseUrl, state)
    },
    {
      name: 'index-view-results-redirect',
      run: async () => runIndexViewResultsSmoke(await context.newPage(), baseUrl, state)
    },
    {
      name: 'exam-terminal-toggle',
      run: () => runExamSmoke(context.mainPage, baseUrl, state)
    },
    {
      name: 'exam-terminate-session',
      run: async () => runExamTerminateSmoke(await context.newPage(), baseUrl, state)
    },
    {
      name: 'exam-review-mode-results',
      run: () => runCompletedExamReviewSmoke(context.mainPage, baseUrl, state)
    },
    {
      name: 'results-re-evaluation',
      run: async () => runResultsReEvaluationSmoke(await context.newPage(), baseUrl, state)
    },
    {
      name: 'results-evaluation-failed',
      run: async () => runResultsFailureSmoke(await context.newPage(), baseUrl)
    },
    {
      name: 'results-retry-recovery',
      run: async () => runResultsRetryRecoverySmoke(await context.newPage(), baseUrl, state)
    },
    {
      name: 'results-actions',
      run: async () => runResultsActionSmoke(await context.newPage(), baseUrl)
    },
    {
      name: 'results-feedback',
      run: async () => runResultsFeedbackSmoke(await context.newPage(), baseUrl)
    }
  ];
}

async function runScenario(name, handler) {
  console.log(`scenario:start ${name}`);
  await handler();
  console.log(`scenario:pass ${name}`);
}

async function main() {
  const { server, state } = buildFixtureServer();
  const scenarios = buildScenarioPlan(
    {
      mainPage: null,
      newPage: () => {
        throw new Error('browser-ui-smoke:list does not open browser pages');
      }
    },
    'http://fixture.invalid',
    state
  );

  if (process.argv.includes('--list')) {
    scenarios.forEach((scenario) => console.log(scenario.name));
    return;
  }

  await new Promise((resolve) => {
    server.listen(0, '127.0.0.1', resolve);
  });

  const address = server.address();
  const baseUrl = `http://127.0.0.1:${address.port}`;

  let browser;
  try {
    browser = await launchBrowser();
    const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
    await stubExternalAssets(context);

    const mainPage = await context.newPage();
    const scenarioContext = {
      mainPage,
      newPage: () => context.newPage()
    };
    const runnableScenarios = buildScenarioPlan(scenarioContext, baseUrl, state);

    for (const scenario of runnableScenarios) {
      await runScenario(scenario.name, scenario.run);
    }

    await context.close();
    console.log('browser ui smoke passed');
  } finally {
    await browser?.close();
    await new Promise((resolve, reject) => {
      server.close((error) => {
        if (error) {
          reject(error);
          return;
        }
        resolve();
      });
    });
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
