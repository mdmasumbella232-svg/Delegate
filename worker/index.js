// ============================================================
// BCS Quiz App — Cloudflare Worker API
// Routes:
//   GET  /api/questions?subject=all&shuffle=false
//   GET  /api/leaderboard?subject=all&limit=10
//   POST /api/scores  { player_name, subject_filter, answers: [{question_id, user_answer}] }
// ============================================================

const CORS = {
  'Access-Control-Allow-Origin':  '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json; charset=utf-8', ...CORS },
  });
}

function err(msg, status = 400) {
  return json({ error: msg }, status);
}

// ── Router ──────────────────────────────────────────────────
export default {
  async fetch(request, env) {
    const url    = new URL(request.url);
    const method = request.method.toUpperCase();
    const path   = url.pathname;

    // Preflight
    if (method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS });
    }

    // ── GET /api/questions ──────────────────────────────────
    if (method === 'GET' && path === '/api/questions') {
      const subject = url.searchParams.get('subject') || 'all';

      let query = 'SELECT * FROM questions';
      const params = [];
      if (subject !== 'all') {
        query += ' WHERE subject = ?';
        params.push(subject);
      }
      query += ' ORDER BY id ASC';

      const { results } = await env.DB.prepare(query).bind(...params).all();

      // Map DB columns → app-friendly shape
      const questions = results.map(r => ({
        id:      r.id,
        subject: r.subject,
        q:       r.question_text,
        opts:    [r.opt_a, r.opt_b, r.opt_c, r.opt_d],
        ans:     r.correct_ans,
        note:    r.note || undefined,
      }));

      return json({ questions, total: questions.length });
    }

    // ── GET /api/leaderboard ────────────────────────────────
    if (method === 'GET' && path === '/api/leaderboard') {
      const subject = url.searchParams.get('subject') || 'all';
      const limit   = Math.min(parseInt(url.searchParams.get('limit') || '10', 10), 50);

      let query = `
        SELECT id, player_name, subject_filter, correct, wrong, skipped, total, time_taken, created_at,
               ROUND(correct * 100.0 / total, 1) AS score_pct
        FROM scores
      `;
      const params = [];
      if (subject !== 'all') {
        query += ' WHERE subject_filter = ?';
        params.push(subject);
      }
      query += ' ORDER BY correct DESC, time_taken ASC LIMIT ?';
      params.push(limit);

      const { results } = await env.DB.prepare(query).bind(...params).all();
      return json({ leaderboard: results });
    }

    // ── POST /api/scores ────────────────────────────────────
    if (method === 'POST' && path === '/api/scores') {
      let body;
      try { body = await request.json(); }
      catch { return err('Invalid JSON body'); }

      const {
        player_name    = 'অজ্ঞাত',
        subject_filter = 'all',
        answers        = [],   // [{ question_id, user_answer }]
        time_taken     = 0,
      } = body;

      if (!answers.length) return err('answers array is empty');

      // Fetch correct answers for submitted question IDs
      const ids = answers.map(a => a.question_id);
      const placeholders = ids.map(() => '?').join(',');
      const { results: qs } = await env.DB
        .prepare(`SELECT id, correct_ans FROM questions WHERE id IN (${placeholders})`)
        .bind(...ids)
        .all();

      const correctMap = {};
      qs.forEach(q => { correctMap[q.id] = q.correct_ans; });

      let correct = 0, wrong = 0, skipped = 0;
      const processedAnswers = answers.map(a => {
        const ca = correctMap[a.question_id];
        const is_correct = (ca !== undefined && a.user_answer === ca) ? 1 : 0;
        if (a.user_answer === -1 || a.user_answer === null) skipped++;
        else if (is_correct) correct++;
        else wrong++;
        return { question_id: a.question_id, user_answer: a.user_answer ?? -1, is_correct };
      });

      const total = answers.length;

      // Insert score row
      const scoreInsert = await env.DB
        .prepare(`INSERT INTO scores (player_name, subject_filter, correct, wrong, skipped, total, time_taken)
                  VALUES (?, ?, ?, ?, ?, ?, ?) RETURNING id`)
        .bind(player_name.trim().slice(0, 60), subject_filter, correct, wrong, skipped, total, time_taken)
        .first();

      const scoreId = scoreInsert.id;

      // Bulk insert attempts
      const stmts = processedAnswers.map(a =>
        env.DB.prepare('INSERT INTO attempts (score_id, question_id, user_answer, is_correct) VALUES (?,?,?,?)')
          .bind(scoreId, a.question_id, a.user_answer, a.is_correct)
      );
      await env.DB.batch(stmts);

      // Leaderboard position
      const { results: rankResult } = await env.DB
        .prepare(`SELECT COUNT(*) + 1 AS rank FROM scores
                  WHERE subject_filter = ? AND (correct > ? OR (correct = ? AND time_taken < ?))`)
        .bind(subject_filter, correct, correct, time_taken)
        .all();

      const rank = rankResult[0]?.rank ?? 1;
      const score_pct = total > 0 ? Math.round(correct * 100 / total) : 0;

      return json({ score_id: scoreId, correct, wrong, skipped, total, score_pct, rank }, 201);
    }

    // ── 404 ─────────────────────────────────────────────────
    return err('Not found', 404);
  },
};
