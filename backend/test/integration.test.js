import 'dotenv/config';
import test from 'node:test';
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { createServer } from 'node:net';
import { randomBytes } from 'node:crypto';
import mysql from 'mysql2/promise';
import jwt from 'jsonwebtoken';

test('signup without email verification, mixed exam authoring and idempotent auto-submit', {timeout: 90000}, async () => {
  const database = `edumate_test_${randomBytes(8).toString('hex')}`;
  const secret = randomBytes(32).toString('hex');
  const db = await mysql.createConnection({host:process.env.DB_HOST || '127.0.0.1', port:Number(process.env.DB_PORT || 3306), user:process.env.DB_USER || 'root', password:process.env.DB_PASSWORD || ''});
  const [[exists]] = await db.query('SELECT COUNT(*) AS n FROM information_schema.SCHEMATA WHERE SCHEMA_NAME = ?', [database]);
  assert.equal(Number(exists.n), 0);
  let child;
  let logs = '';
  try {
    const probe = createServer();
    await new Promise((resolve) => probe.listen(0, '127.0.0.1', resolve));
    const port = probe.address().port;
    await new Promise((resolve) => probe.close(resolve));
    const base = `http://127.0.0.1:${port}`;
    child = spawn(process.execPath, ['server.js'], {cwd: new URL('..', import.meta.url), env:{...process.env,
      NODE_ENV:'test', PORT:String(port), DB_NAME:database, JWT_SECRET:secret,
    }, stdio:['ignore','pipe','pipe'], windowsHide:true});
    child.stdout.on('data', (s) => { logs += s; });
    child.stderr.on('data', (s) => { logs += s; });
    let ready = false;
    for (let i=0; i<100; i++) {
      try { ready = (await fetch(`${base}/api/health`)).ok; } catch {}
      if (ready) break;
      if (child.exitCode !== null) throw new Error(logs);
      await new Promise((resolve) => setTimeout(resolve,100));
    }
    assert.ok(ready, logs);
    await db.query(`USE \`${database}\``);
    const request = async (path, body, token, method = body ? 'POST' : 'GET') => {
      const res = await fetch(base+path,{method, headers:{'Content-Type':'application/json',...(token ? {Authorization:`Bearer ${token}`} : {})}, ...(body ? {body:JSON.stringify(body)} : {})});
      return {status:res.status, body:await res.json()};
    };
    const signup = {name:'Student test',email:'student@example.test',password:'TestPassword123!'};
    let response = await request('/api/auth/signup', signup);
    assert.equal(response.status,201);
    assert.equal(typeof response.body.token,'string');
    assert.equal(response.body.user.role,'student');
    const studentId = response.body.user.id;
    const discussionTitle = `Student question ${randomBytes(4).toString('hex')}`;
    assert.equal((await request('/api/discussions',{
      title:discussionTitle,content:'Can you explain this topic?',
    },response.body.token)).status,201);
    assert.equal((await request('/api/auth/me',null,response.body.token)).status,200);
    response = await request('/api/auth/login',signup);
    assert.equal(response.status,200);
    const studentToken = response.body.token;
    const forgedSession = jwt.sign({id:studentId,role:'student'},secret);
    assert.equal((await request('/api/auth/me',null,forgedSession)).status,200);
    const teacher = await request('/api/auth/login',{email:'teacher@edumate.com',password:'demo123'});
    const [[discussion]] = await db.query(
      'SELECT id FROM discussions WHERE user_id = ? AND title = ?',
      [studentId,discussionTitle],
    );
    const teacherDiscussions = await request('/api/discussions',null,teacher.body.token);
    assert.ok(teacherDiscussions.body.discussions.some((item) => item.id === discussion.id));
    assert.equal((await request(`/api/discussions/${discussion.id}`,null,teacher.body.token)).status,200);
    assert.equal((await request(`/api/discussions/${discussion.id}/reply`,{
      content:'I will explain it in class.',
    },teacher.body.token)).status,201);
    const [course] = await db.query('INSERT INTO courses (title,instructor_id) VALUES (?,?)',['Integration course',teacher.body.user.id]);
    await db.query('INSERT INTO course_enrollments (course_id,student_id) VALUES (?,?)',[course.insertId,studentId]);
    const exam = {title:'Mixed exam',subject:'General',duration:5,per_mcq_mark:2,negative_marking:0.5,shuffle_mode:'questions_and_options',questions:[
      {question_type:'mcq',question_text:'2+2?',options:['3','4','5','6'],correct_option:1},
      {question_type:'fill_blank',question_text:'India capital is ___',correct_answer:'New Delhi'},
      {question_type:'fill_blank',question_text:'Bangladesh capital is ___',correct_answer:'ঢাকা'},
    ]};
    response = await request(`/api/instructor/courses/${course.insertId}/exams`,exam,teacher.body.token);
    assert.equal(response.status,201,JSON.stringify(response.body));
    const examId = response.body.id;
    response = await request(`/api/instructor/exams/${examId}`,null,teacher.body.token);
    assert.equal(response.body.exam.questions[1].correct_answer,'New Delhi');
    assert.equal((await request(`/api/instructor/exams/${examId}`,exam,teacher.body.token,'PUT')).status,200);
    response = await request(`/api/student/tests/${examId}`,null,studentToken);
    assert.equal(response.status,200);
    for (const q of response.body.questions) { assert.equal(q.correct_answer,undefined); assert.equal(q.correct_option,undefined); }
    const answers = {};
    for (const q of response.body.questions) answers[q.id] = q.question_type === 'mcq' ? 1 : q.question_text.startsWith('India') ? '  NEW   delhi ' : '';
    const submission = {test_id:examId,answers,submission_id:randomBytes(16).toString('hex'),submission_reason:'left_exam'};
    const results = await Promise.all([request('/api/student/tests/submit',submission,studentToken),request('/api/student/tests/submit',submission,studentToken)]);
    for (const r of results) {
      assert.ok([200,201].includes(r.status),JSON.stringify(r));
      assert.equal(r.body.correct_answers,2); assert.equal(r.body.unanswered,1);
      assert.equal(r.body.earned_marks,4); assert.equal(r.body.submission_reason,'left_exam');
    }
    const [[count]] = await db.query('SELECT COUNT(*) AS n FROM test_results WHERE test_id = ?',[examId]);
    assert.equal(Number(count.n),1);
    assert.equal((await request(`/api/instructor/exams/${examId}`,exam,teacher.body.token,'PUT')).status,409);
    for (let i=0;i<2;i++) assert.equal((await request('/api/student/tests/submit',{...submission,submission_id:randomBytes(16).toString('hex')},studentToken)).status,201);
    assert.equal((await request('/api/student/tests/submit',{...submission,submission_id:randomBytes(16).toString('hex')},studentToken)).status,409);
    assert.equal((await request('/api/student/tests/submit',submission,studentToken)).status,200);
  } finally {
    if (child && child.exitCode === null) {
      const exited = new Promise((resolve) => child.once('exit',resolve));
      child.kill(); await exited;
    }
    // Only the freshly created, uniquely named integration database is removed.
    assert.match(database,/^edumate_test_[a-f0-9]{16}$/);
    await db.query(`DROP DATABASE IF EXISTS \`${database}\``);
    await db.end();
  }
});
