// ============================================================
// BCS Quiz App — Main Application Logic with Cloudflare API
// ============================================================

// ── Configuration ──────────────────────────────────────────
const API_BASE = '/api'; // Assuming same domain for Pages + Worker

// ── State ──────────────────────────────────────────────────
let state = {
  mode:          'quiz',
  allQuestions:  [],           // Fetched or from data.js
  questions:     [],           // filtered question list
  currentIndex:  0,
  userAnswers:   {},
  timerInterval: null,
  timeLeft:      90 * 60,
  started:       false,
  studyIndex:    0,
  studyShowAns:  false,
  selectedFilter: 'all',
  playerName:    '',
  apiOnline:     false,
};

// ── Helpers ────────────────────────────────────────────────
const $ = id => document.getElementById(id);

function getFilteredQuestions(filter) {
  const source = state.allQuestions.length ? state.allQuestions : ALL_QUESTIONS;
  if (filter === 'all') return [...source];
  const subj = SUBJECTS[filter];
  if (!subj) return [...source];
  const [lo, hi] = subj.range;
  return source.filter(q => q.id >= lo && q.id <= hi);
}

function getSubjectForQ(q) {
  return SUBJECTS[q.subject] || { label: '?', color: '#fff' };
}

function optKey(i) {
  return ['ক', 'খ', 'গ', 'ঘ'][i] || String.fromCharCode(65 + i);
}

function showScreen(id) {
  document.querySelectorAll('.screen').forEach(s => {
    s.classList.remove('active');
    s.style.display = 'none';
  });
  const el = document.getElementById(id);
  el.style.display = 'flex';
  requestAnimationFrame(() => el.classList.add('active'));
}

// ── API Integration ────────────────────────────────────────
async function initApp() {
  spawnParticles();
  
  // Try to load questions from Cloudflare API
  try {
    const res = await fetch(`${API_BASE}/questions`);
    if (res.ok) {
      const data = await res.json();
      state.allQuestions = data.questions;
      state.apiOnline = true;
      setApiStatus('online', 'ক্লাউড ডেটাবেস যুক্ত (Online)');
    } else {
      throw new Error('API not ok');
    }
  } catch (err) {
    console.warn('Failed to load API questions, falling back to local data.js', err);
    state.allQuestions = [...ALL_QUESTIONS];
    state.apiOnline = false;
    setApiStatus('offline', 'অফলাইন মোড (লোকাল ডেটা)');
  }

  updateFilterInfo();
  showScreen('homeScreen');
  
  if (state.apiOnline) {
    refreshLeaderboard();
  } else {
    $('leaderboardBody').innerHTML = '<p class="lb-offline">অফলাইন মোডে লিডারবোর্ড বন্ধ আছে।</p>';
  }
}

function setApiStatus(status, text) {
  const dot = $('statusDot');
  dot.className = 'status-dot ' + status;
  $('statusText').textContent = text;
}

// ══════════════════════════════════════════════════════════
// HOME & LEADERBOARD
// ══════════════════════════════════════════════════════════
function goHome() {
  clearInterval(state.timerInterval);
  state.timerInterval = null;
  showScreen('homeScreen');
  if (state.apiOnline) refreshLeaderboard();
}

function updateFilterInfo() {
  const val = $('subjectFilter').value;
  state.selectedFilter = val;
  const qs = getFilteredQuestions(val);
  $('filterInfo').textContent = `${qs.length}টি প্রশ্ন`;
}

async function refreshLeaderboard() {
  if (!state.apiOnline) return;
  const tbody = $('leaderboardBody');
  tbody.innerHTML = '<p class="lb-loading">লিডারবোর্ড রিফ্রেশ হচ্ছে...</p>';
  
  try {
    const res = await fetch(`${API_BASE}/leaderboard?limit=10`);
    if (!res.ok) throw new Error('Failed');
    const data = await res.json();
    
    if (!data.leaderboard || data.leaderboard.length === 0) {
      tbody.innerHTML = '<p class="lb-loading">এখনও কোনো স্কোর নেই!</p>';
      return;
    }
    
    let html = '<table class="lb-table"><tr><th>র‌্যাংক</th><th>নাম</th><th>স্কোর</th><th>সময়</th></tr>';
    data.leaderboard.forEach((row, i) => {
      let rankClass = '';
      if (i === 0) rankClass = 'gold';
      else if (i === 1) rankClass = 'silver';
      else if (i === 2) rankClass = 'bronze';
      
      const mm = String(Math.floor(row.time_taken / 60)).padStart(2, '0');
      const ss = String(row.time_taken % 60).padStart(2, '0');
      
      html += `
        <tr>
          <td class="lb-rank ${rankClass}">#${i + 1}</td>
          <td>
            <div class="lb-name">${row.player_name || 'অজ্ঞাত'}</div>
            <div class="lb-subj">${SUBJECTS[row.subject_filter]?.label || 'সব বিষয়'}</div>
          </td>
          <td>
            <div class="lb-score">${row.correct}/${row.total}</div>
            <div class="lb-pct">${row.score_pct}%</div>
          </td>
          <td style="color:var(--text-muted);font-size:0.85rem">${mm}:${ss}</td>
        </tr>
      `;
    });
    html += '</table>';
    tbody.innerHTML = html;
    
  } catch (err) {
    tbody.innerHTML = '<p class="lb-offline">লিডারবোর্ড লোড করা যায়নি।</p>';
  }
}

// ══════════════════════════════════════════════════════════
// QUIZ MODE
// ══════════════════════════════════════════════════════════
function startQuiz() {
  const nameInput = $('playerNameInput').value.trim();
  if (state.apiOnline && !nameInput) {
    alert('দয়া করে আপনার নাম লিখুন!');
    $('playerNameInput').focus();
    return;
  }
  
  state.playerName = nameInput || 'অজ্ঞাত';
  const filter = $('subjectFilter').value;
  state.questions = getFilteredQuestions(filter);
  state.currentIndex = 0;
  state.userAnswers = {};
  state.questions.forEach(q => { state.userAnswers[q.id] = null; });
  state.timeLeft = 90 * 60; // 90 minutes
  state.mode = 'quiz';
  
  showScreen('quizScreen');
  renderQuestion();
  renderDots();
  startTimer();
}

// ── Timer ──────────────────────────────────────────────────
function startTimer() {
  clearInterval(state.timerInterval);
  state.timerInterval = setInterval(() => {
    state.timeLeft--;
    updateTimerDisplay();
    if (state.timeLeft <= 0) {
      clearInterval(state.timerInterval);
      finishQuiz();
    }
  }, 1000);
  updateTimerDisplay();
}

function updateTimerDisplay() {
  const m = Math.floor(state.timeLeft / 60);
  const s = state.timeLeft % 60;
  const display = `${String(m).padStart(2,'0')}:${String(s).padStart(2,'0')}`;
  $('timerDisplay').textContent = display;
  const box = $('timerBox');
  box.classList.remove('warning', 'danger');
  if (state.timeLeft <= 300) box.classList.add('danger');
  else if (state.timeLeft <= 600) box.classList.add('warning');
}

// ── Question Render ────────────────────────────────────────
function renderQuestion() {
  const q = state.questions[state.currentIndex];
  const total = state.questions.length;
  const subj = getSubjectForQ(q);

  $('qSubjectTag').textContent = subj.label;
  $('qSubjectTag').style.background = subj.color + '20';
  $('qSubjectTag').style.color = subj.color;
  $('qSubjectTag').style.borderColor = subj.color + '40';
  $('qProgress').textContent = `${state.currentIndex + 1} / ${total}`;

  const pct = ((state.currentIndex + 1) / total) * 100;
  $('progressFill').style.width = pct + '%';

  const card = $('questionCard');
  card.style.animation = 'none';
  card.offsetHeight;
  card.style.animation = '';

  $('questionNum').textContent = `প্রশ্ন ${q.id}`;
  $('questionText').textContent = q.q;

  const grid = $('optionsGrid');
  grid.innerHTML = '';
  const answered = state.userAnswers[q.id] !== null && state.userAnswers[q.id] !== undefined;

  q.opts.forEach((opt, i) => {
    const btn = document.createElement('button');
    btn.className = 'option-btn';
    btn.id = `opt_${q.id}_${i}`;
    btn.innerHTML = `<span class="opt-key">${optKey(i)}</span><span class="opt-text">${opt}</span>`;
    btn.onclick = () => selectAnswer(i);

    if (answered) {
      btn.disabled = true;
      const userAns = state.userAnswers[q.id];
      if (i === q.ans) btn.classList.add('correct');
      else if (i === userAns) btn.classList.add('wrong');
    }
    grid.appendChild(btn);
  });

  const fb = $('questionFeedback');
  fb.className = 'question-feedback hidden';
  fb.textContent = '';
  if (answered) {
    const userAns = state.userAnswers[q.id];
    fb.classList.remove('hidden');
    if (userAns === q.ans) {
      fb.classList.add('correct-fb');
      fb.textContent = '✅ সঠিক উত্তর! চমৎকার!';
    } else {
      fb.classList.add('wrong-fb');
      fb.textContent = `❌ ভুল! সঠিক উত্তর: ${optKey(q.ans)}. ${q.opts[q.ans]}` +
        (q.note ? `  (${q.note})` : '');
    }
  }

  $('prevBtn').disabled = state.currentIndex === 0;
  const isLast = state.currentIndex === total - 1;
  const nxtBtn = $('nextBtn');
  nxtBtn.textContent = isLast ? 'ফলাফল দেখুন ✔' : 'পরবর্তী ▶';
  nxtBtn.classList.toggle('btn-finish', isLast);

  updateDots();
}

function selectAnswer(optIdx) {
  const q = state.questions[state.currentIndex];
  if (state.userAnswers[q.id] !== null && state.userAnswers[q.id] !== undefined) return;

  state.userAnswers[q.id] = optIdx;
  renderQuestion();
  updateDots();
}

function nextQuestion() {
  if (state.currentIndex < state.questions.length - 1) {
    state.currentIndex++;
    renderQuestion();
  } else {
    finishQuiz();
  }
}

function prevQuestion() {
  if (state.currentIndex > 0) {
    state.currentIndex--;
    renderQuestion();
  }
}

function renderDots() {
  const container = $('questionDots');
  container.innerHTML = '';
  state.questions.forEach((q, i) => {
    const dot = document.createElement('div');
    dot.className = 'dot';
    dot.id = `dot_${i}`;
    dot.title = `প্রশ্ন ${q.id}`;
    dot.onclick = () => { state.currentIndex = i; renderQuestion(); updateDots(); };
    container.appendChild(dot);
  });
  updateDots();
}

function updateDots() {
  state.questions.forEach((q, i) => {
    const dot = $(`dot_${i}`);
    if (!dot) return;
    dot.className = 'dot';
    if (i === state.currentIndex) dot.classList.add('current');
    else if (state.userAnswers[q.id] !== null && state.userAnswers[q.id] !== undefined) {
      dot.classList.add(state.userAnswers[q.id] === q.ans ? 'answered-correct' : 'answered-wrong');
    }
    if (i === state.currentIndex) {
      dot.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'center' });
    }
  });
}

// ══════════════════════════════════════════════════════════
// RESULT & API SUBMIT
// ══════════════════════════════════════════════════════════
async function finishQuiz() {
  clearInterval(state.timerInterval);
  state.timerInterval = null;

  let correct = 0, wrong = 0, skipped = 0;
  const answersForApi = [];
  
  state.questions.forEach(q => {
    const ua = state.userAnswers[q.id];
    if (ua === null || ua === undefined) skipped++;
    else if (ua === q.ans) correct++;
    else wrong++;
    
    answersForApi.push({
      question_id: q.id,
      user_answer: ua === null || ua === undefined ? -1 : ua
    });
  });

  const total = state.questions.length;
  const pct = Math.round((correct / total) * 100);

  $('correctCount').textContent = correct;
  $('wrongCount').textContent = wrong;
  $('skipCount').textContent = skipped;
  $('scorePercent').textContent = pct + '%';

  if (pct >= 80) $('resultSubtitle').textContent = 'অসাধারণ! আপনি সত্যিই প্রস্তুত!';
  else if (pct >= 60) $('resultSubtitle').textContent = 'ভালো ফলাফল! আরও অনুশীলন করুন।';
  else if (pct >= 40) $('resultSubtitle').textContent = 'মোটামুটি ফলাফল। আরও পড়াশোনা দরকার।';
  else $('resultSubtitle').textContent = 'আরও মনোযোগ দিয়ে পড়ুন!';

  const gradeEl = $('resultGrade');
  gradeEl.className = 'result-grade';
  if (pct >= 80) { gradeEl.textContent = '🏆 গ্রেড: A+'; gradeEl.classList.add('grade-a'); }
  else if (pct >= 65) { gradeEl.textContent = '⭐ গ্রেড: A'; gradeEl.classList.add('grade-b'); }
  else if (pct >= 50) { gradeEl.textContent = '👍 গ্রেড: B'; gradeEl.classList.add('grade-c'); }
  else { gradeEl.textContent = '📖 পুনরায় পড়ুন'; gradeEl.classList.add('grade-d'); }

  const circumference = 2 * Math.PI * 85;
  const ring = $('scoreRing');
  ring.style.strokeDashoffset = circumference;
  ring.style.stroke = pct >= 80 ? '#22c55e' : pct >= 60 ? '#3b82f6' : pct >= 40 ? '#f5c842' : '#ef4444';

  const svg = ring.closest('svg');
  if (!svg.querySelector('defs')) {
    const defs = document.createElementNS('http://www.w3.org/2000/svg', 'defs');
    const grad = document.createElementNS('http://www.w3.org/2000/svg', 'linearGradient');
    grad.id = 'scoreGradient';
    grad.innerHTML = `<stop offset="0%" stop-color="#f5c842"/><stop offset="100%" stop-color="#22c55e"/>`;
    defs.appendChild(grad); svg.insertBefore(defs, svg.firstChild);
  }

  showScreen('resultScreen');

  setTimeout(() => {
    const offset = circumference - (pct / 100) * circumference;
    ring.style.strokeDashoffset = offset;
  }, 400);

  buildSubjectBreakdown();
  
  // Submit to Cloudflare API
  const rankBanner = $('rankBanner');
  if (state.apiOnline) {
    rankBanner.className = 'rank-banner saving';
    rankBanner.innerHTML = 'স্কোর সংরক্ষণ করা হচ্ছে...';
    
    try {
      const timeTaken = (90 * 60) - state.timeLeft;
      const res = await fetch(`${API_BASE}/scores`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          player_name: state.playerName,
          subject_filter: state.selectedFilter,
          answers: answersForApi,
          time_taken: timeTaken > 0 ? timeTaken : 0
        })
      });
      
      if (res.ok) {
        const data = await res.json();
        rankBanner.className = 'rank-banner';
        rankBanner.innerHTML = `
          <span class="rank-num">#${data.rank}</span>
          <span class="rank-label">লিডারবোর্ডে আপনার অবস্থান</span>
        `;
      } else {
        rankBanner.className = 'rank-banner hidden';
      }
    } catch (err) {
      rankBanner.className = 'rank-banner hidden';
      console.error('Failed to submit score', err);
    }
  } else {
    rankBanner.className = 'rank-banner hidden';
  }
}

function buildSubjectBreakdown() {
  const container = $('subjectBreakdown');
  container.innerHTML = '<h3 style="font-size:0.9rem;color:var(--text-muted);margin-bottom:16px;">বিষয়ভিত্তিক ফলাফল</h3>';

  Object.entries(SUBJECTS).forEach(([key, subj]) => {
    const subjQs = state.questions.filter(q => q.subject === key);
    if (subjQs.length === 0) return;
    const correct = subjQs.filter(q => state.userAnswers[q.id] === q.ans).length;
    const pct = Math.round((correct / subjQs.length) * 100);

    const row = document.createElement('div');
    row.className = 'subject-row';
    row.innerHTML = `
      <span class="sr-label" style="color:${subj.color}">${subj.label}</span>
      <div class="sr-bar-track">
        <div class="sr-bar-fill" style="background:${subj.color};width:0%" data-pct="${pct}"></div>
      </div>
      <span class="sr-score">${correct}/${subjQs.length}</span>
    `;
    container.appendChild(row);
  });

  setTimeout(() => {
    document.querySelectorAll('.sr-bar-fill').forEach(bar => {
      bar.style.width = bar.dataset.pct + '%';
    });
  }, 600);
}

function retakeQuiz() {
  startQuiz();
}

// ══════════════════════════════════════════════════════════
// REVIEW
// ══════════════════════════════════════════════════════════
let currentReviewFilter = 'all';

function reviewAnswers() {
  currentReviewFilter = 'all';
  buildReviewList('all');
  document.querySelectorAll('.rfb').forEach(b => b.classList.remove('active'));
  document.querySelectorAll('.rfb')[0].classList.add('active');
  showScreen('reviewScreen');
}

function filterReview(filter, btn) {
  currentReviewFilter = filter;
  document.querySelectorAll('.rfb').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  buildReviewList(filter);
}

function buildReviewList(filter) {
  const list = $('reviewList');
  list.innerHTML = '';

  let qs = state.questions;
  if (filter === 'correct') qs = qs.filter(q => state.userAnswers[q.id] === q.ans);
  else if (filter === 'wrong')   qs = qs.filter(q => state.userAnswers[q.id] !== null && state.userAnswers[q.id] !== undefined && state.userAnswers[q.id] !== q.ans);

  if (qs.length === 0) {
    list.innerHTML = '<p style="text-align:center;color:var(--text-muted);padding:40px;">কোনো প্রশ্ন পাওয়া যায়নি</p>';
    return;
  }

  qs.forEach(q => {
    const ua = state.userAnswers[q.id];
    const isCorrect = ua === q.ans;
    const isSkipped = ua === null || ua === undefined;
    const subj = getSubjectForQ(q);

    const item = document.createElement('div');
    item.className = `review-item ${isSkipped ? 'review-skip' : isCorrect ? 'review-correct' : 'review-wrong'}`;

    const badgeClass = isSkipped ? 'badge-skip' : isCorrect ? 'badge-correct' : 'badge-wrong';
    const badgeText  = isSkipped ? 'বাদ' : isCorrect ? 'সঠিক' : 'ভুল';

    item.innerHTML = `
      <div class="review-q-header">
        <span class="review-q-num" style="color:${subj.color}">প্র ${q.id}</span>
        <p class="review-q-text">${q.q}</p>
        <span class="review-badge ${badgeClass}">${badgeText}</span>
      </div>
      <div class="review-answers">
        ${q.opts.map((opt, i) => {
          let cls = '';
          if (i === q.ans) cls = 'is-correct';
          else if (i === ua && ua !== q.ans) cls = 'user-wrong';
          return `<div class="review-opt ${cls}">
            <strong>${optKey(i)}.</strong> ${opt}
            ${i === q.ans ? ' ✅' : (i === ua && ua !== q.ans ? ' ❌' : '')}
          </div>`;
        }).join('')}
        ${q.note ? `<div style="font-size:0.8rem;color:var(--text-muted);margin-top:4px;">📌 ${q.note}</div>` : ''}
      </div>
    `;
    list.appendChild(item);
  });
}

function backToResult() {
  showScreen('resultScreen');
}

// ══════════════════════════════════════════════════════════
// STUDY MODE
// ══════════════════════════════════════════════════════════
function startStudyMode() {
  const filter = $('subjectFilter').value;
  state.questions = getFilteredQuestions(filter);
  state.studyIndex = 0;
  state.studyShowAns = false;
  state.mode = 'study';
  showScreen('studyScreen');
  renderStudyQuestion();
}

function renderStudyQuestion() {
  const q = state.questions[state.studyIndex];
  const total = state.questions.length;
  const subj = getSubjectForQ(q);

  $('sProgress').textContent = `${state.studyIndex + 1} / ${total}`;
  $('studyProgressFill').style.width = ((state.studyIndex + 1) / total * 100) + '%';
  $('studyQNum').textContent = `প্রশ্ন ${q.id} — ${subj.label}`;
  $('studyQText').textContent = q.q;
  $('studyDotNav').textContent = `${state.studyIndex + 1} / ${total}`;

  const optGrid = $('studyOptions');
  optGrid.innerHTML = '';
  q.opts.forEach((opt, i) => {
    const btn = document.createElement('button');
    btn.className = 'option-btn';
    btn.innerHTML = `<span class="opt-key">${optKey(i)}</span><span class="opt-text">${opt}</span>`;
    optGrid.appendChild(btn);
  });

  const ansEl = $('studyAnswer');
  ansEl.classList.add('hidden');
  state.studyShowAns = false;

  $('studyPrev').disabled = state.studyIndex === 0;
  $('studyNext').textContent = state.studyIndex === total - 1 ? 'শেষ ✔' : 'পরবর্তী ▶';
}

function toggleStudyAnswer() {
  const q = state.questions[state.studyIndex];
  const ansEl = $('studyAnswer');
  const optBtns = document.querySelectorAll('#studyOptions .option-btn');

  state.studyShowAns = !state.studyShowAns;
  if (state.studyShowAns) {
    ansEl.classList.remove('hidden');
    ansEl.textContent = `✅ সঠিক উত্তর: ${optKey(q.ans)}. ${q.opts[q.ans]}` + (q.note ? ` (${q.note})` : '');
    optBtns.forEach((btn, i) => {
      if (i === q.ans) btn.classList.add('correct');
    });
  } else {
    ansEl.classList.add('hidden');
    optBtns.forEach(btn => btn.classList.remove('correct'));
  }
}

function studyNext() {
  if (state.studyIndex < state.questions.length - 1) {
    state.studyIndex++;
    renderStudyQuestion();
  } else {
    goHome();
  }
}

function studyPrev() {
  if (state.studyIndex > 0) {
    state.studyIndex--;
    renderStudyQuestion();
  }
}

// ══════════════════════════════════════════════════════════
// INIT
// ══════════════════════════════════════════════════════════
document.addEventListener('DOMContentLoaded', () => {
  initApp();

  document.addEventListener('keydown', e => {
    const screen = document.querySelector('.screen.active');
    if (!screen) return;
    const id = screen.id;

    if (id === 'quizScreen') {
      if (['1','2','3','4'].includes(e.key)) {
        selectAnswer(parseInt(e.key) - 1);
      }
      if (e.key === 'ArrowRight' || e.key === 'Enter') nextQuestion();
      if (e.key === 'ArrowLeft') prevQuestion();
    }
    if (id === 'studyScreen') {
      if (e.key === 'ArrowRight') studyNext();
      if (e.key === 'ArrowLeft') studyPrev();
      if (e.key === ' ') { e.preventDefault(); toggleStudyAnswer(); }
    }
  });
});

