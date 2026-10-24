import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import mysql from 'mysql2/promise';
import { randomUUID } from 'node:crypto';
import { cleanQuestion, gradeExam } from './exam-grading.js';

const app = express();
const port = Number(process.env.PORT || 5000);
const databaseName = process.env.DB_NAME || 'edumate';
const jwtSecret = process.env.JWT_SECRET || 'change-this-development-secret';

app.use(cors());
app.use(express.json());

let pool;

const userFields = `
  id, name, email, role, phone, institution, avatar, is_frozen,
  DATE_FORMAT(created_at, '%Y-%m-%dT%H:%i:%sZ') AS created_at
`;

function publicUser(user) {
  return {
    id: user.id,
    name: user.name,
    email: user.email,
    role: user.role,
    phone: user.phone,
    institution: user.institution,
    avatar: user.avatar,
    is_frozen: Boolean(user.is_frozen),
    created_at: user.created_at,
  };
}

function issueToken(user) {
  return jwt.sign({ id: user.id, role: user.role }, jwtSecret, {
    expiresIn: '7d',
  });
}

async function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ message: 'Authentication required' });

  try {
    req.auth = jwt.verify(token, jwtSecret);
    // A valid JWT is not enough: an administrator may have permanently
    // deleted this account after the token was issued.
    const [rows] = await pool.query(
      'SELECT id, role, is_frozen FROM users WHERE id = ? LIMIT 1',
      [req.auth.id],
    );
    if (!rows[0]) return res.status(401).json({ message: 'Account not found' });
    if (rows[0].is_frozen) return res.status(403).json({ message: 'Account is frozen' });
    req.auth.role = rows[0].role;
    next();
  } catch (_) {
    return res.status(401).json({ message: 'Invalid or expired token' });
  }
}

function requireAdmin(req, res, next) {
  if (req.auth?.role !== 'admin') {
    return res.status(403).json({ message: 'Admin access required' });
  }
  next();
}

function requireInstructor(req, res, next) {
  if (!['instructor', 'admin'].includes(req.auth?.role)) {
    return res.status(403).json({ message: 'Instructor access required' });
  }
  next();
}

function requireTeacher(req, res, next) {
  if (req.auth?.role !== 'instructor') {
    return res.status(403).json({ message: 'Teacher access required' });
  }
  next();
}

async function initializeDatabase() {
  const adminConnection = await mysql.createConnection({
    host: process.env.DB_HOST || '127.0.0.1',
    port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    connectTimeout: 3000,
  });
  await adminConnection.query(
    `CREATE DATABASE IF NOT EXISTS \`${databaseName}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`,
  );
  await adminConnection.end();

  pool = mysql.createPool({
    host: process.env.DB_HOST || '127.0.0.1',
    port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: databaseName,
    connectTimeout: 3000,
    waitForConnections: true,
    connectionLimit: 10,
  });

  await pool.query(`
    CREATE TABLE IF NOT EXISTS users (
      id INT PRIMARY KEY AUTO_INCREMENT,
      name VARCHAR(120) NOT NULL,
      email VARCHAR(190) NOT NULL UNIQUE,
      password_hash VARCHAR(255) NOT NULL,
      role ENUM('student', 'instructor', 'admin') NOT NULL DEFAULT 'student',
      phone VARCHAR(40),
      institution VARCHAR(180),
      avatar TEXT,
      is_frozen TINYINT(1) NOT NULL DEFAULT 0,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  `);
  const [frozenColumn] = await pool.query("SHOW COLUMNS FROM users LIKE 'is_frozen'");
  const [verifiedColumn] = await pool.query("SHOW COLUMNS FROM users LIKE 'email_verified'");
  if (verifiedColumn.length) {
    // Accounts created before email verification was removed remain usable.
    await pool.query('UPDATE users SET email_verified = TRUE');
    await pool.query('ALTER TABLE users DROP COLUMN email_verified');
  }
  await pool.query('DROP TABLE IF EXISTS email_verifications');
  if (!frozenColumn.length) {
    await pool.query('ALTER TABLE users ADD COLUMN is_frozen TINYINT(1) NOT NULL DEFAULT 0');
  }
  try {
    await pool.query(
      'ALTER TABLE users ADD UNIQUE KEY uq_users_phone (phone)',
    );
  } catch (error) {
    if (error.code !== 'ER_DUP_KEYNAME') throw error;
  }
  await pool.query(`
    CREATE TABLE IF NOT EXISTS system_seed_users (
      email VARCHAR(190) PRIMARY KEY,
      seeded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  `);
  await pool.query(`
    CREATE TABLE IF NOT EXISTS courses (
      id INT PRIMARY KEY AUTO_INCREMENT,
      title VARCHAR(180) NOT NULL,
      description TEXT,
      instructor_id INT,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (instructor_id) REFERENCES users(id) ON DELETE SET NULL
    )
  `);
  const [enrollmentTables] = await pool.query("SHOW TABLES LIKE 'course_enrollments'");
  await pool.query(`
    CREATE TABLE IF NOT EXISTS course_enrollments (
      course_id INT NOT NULL,
      student_id INT NOT NULL,
      enrolled_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (course_id, student_id),
      CONSTRAINT fk_enrollments_course FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE,
      FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE
    )
  `);
  if (enrollmentTables.length === 0) {
    // Preserve course access for students who used the app before enrollments existed.
    await pool.query(`
      INSERT IGNORE INTO course_enrollments (course_id, student_id)
      SELECT c.id, u.id FROM courses c CROSS JOIN users u WHERE u.role = 'student'
    `);
  }
  await pool.query(`
    CREATE TABLE IF NOT EXISTS reports (
      id INT PRIMARY KEY AUTO_INCREMENT,
      user_id INT,
      title VARCHAR(180) NOT NULL,
      description TEXT NOT NULL,
      status ENUM('open', 'in_progress', 'resolved') NOT NULL DEFAULT 'open',
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
    )
  `);
  await pool.query(`
    CREATE TABLE IF NOT EXISTS content (
      id INT PRIMARY KEY AUTO_INCREMENT,
      title VARCHAR(180) NOT NULL,
      type VARCHAR(50) NOT NULL DEFAULT 'course',
      description TEXT,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  `);
  await pool.query(`
    CREATE TABLE IF NOT EXISTS course_content (
      id INT PRIMARY KEY AUTO_INCREMENT,
      course_id INT NOT NULL,
      instructor_id INT NOT NULL,
      title VARCHAR(180) NOT NULL,
      type ENUM('pdf', 'video', 'exam', 'live') NOT NULL,
      url TEXT NOT NULL,
      description TEXT,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE,
      FOREIGN KEY (instructor_id) REFERENCES users(id) ON DELETE CASCADE
    )
  `);
  await pool.query(`
    CREATE TABLE IF NOT EXISTS course_ratings (
      course_id INT NOT NULL,
      student_id INT NOT NULL,
      rating TINYINT NOT NULL,
      updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (course_id, student_id),
      FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE,
      FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE
    )
  `);
  await pool.query(`
    CREATE TABLE IF NOT EXISTS packages (
      id INT PRIMARY KEY AUTO_INCREMENT,
      title VARCHAR(180) NOT NULL,
      subtitle VARCHAR(255),
      price VARCHAR(50) NOT NULL,
      period VARCHAR(50),
      features JSON NOT NULL,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  `);
  await pool.query(`
    CREATE TABLE IF NOT EXISTS tests (
      id INT PRIMARY KEY AUTO_INCREMENT,
      course_id INT NOT NULL,
      title VARCHAR(180) NOT NULL,
      description TEXT,
      subject VARCHAR(120),
      duration INT NOT NULL DEFAULT 30,
      per_mcq_mark DECIMAL(6,2) NOT NULL DEFAULT 1,
      negative_marking DECIMAL(6,2) NOT NULL DEFAULT 0,
      shuffle_mode ENUM('none', 'questions', 'questions_and_options') NOT NULL DEFAULT 'none',
      published BOOLEAN NOT NULL DEFAULT TRUE,
      FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  `);
  // Older installations already have tests without a course. Keep their demo
  // data by attaching it to the seeded course after that course is created.
  for (const [column, definition] of [
    ['course_id', 'INT NULL'],
    ['per_mcq_mark', 'DECIMAL(6,2) NOT NULL DEFAULT 1'],
    ['negative_marking', 'DECIMAL(6,2) NOT NULL DEFAULT 0'],
    ['shuffle_mode', "ENUM('none', 'questions', 'questions_and_options') NOT NULL DEFAULT 'none'"],
    ['published', 'BOOLEAN NOT NULL DEFAULT TRUE'],
  ]) {
    const [existing] = await pool.query(`SHOW COLUMNS FROM tests LIKE ?`, [column]);
    if (existing.length === 0) await pool.query(`ALTER TABLE tests ADD COLUMN ${column} ${definition}`);
  }
  const [courseForeignKey] = await pool.query(`
    SELECT CONSTRAINT_NAME FROM information_schema.KEY_COLUMN_USAGE
    WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'tests'
      AND COLUMN_NAME = 'course_id' AND REFERENCED_TABLE_NAME = 'courses'
  `, [databaseName]);
  if (courseForeignKey.length === 0) {
    await pool.query('ALTER TABLE tests ADD CONSTRAINT fk_tests_course FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE');
  }
  await pool.query(`
    CREATE TABLE IF NOT EXISTS questions (
      id INT PRIMARY KEY AUTO_INCREMENT,
      test_id INT NOT NULL,
      question_text TEXT NOT NULL,
      options JSON NOT NULL,
      correct_option INT NOT NULL DEFAULT 0,
      explanation TEXT,
      subject VARCHAR(120),
      FOREIGN KEY (test_id) REFERENCES tests(id) ON DELETE CASCADE
    )
  `);
  await pool.query(`
    CREATE TABLE IF NOT EXISTS test_results (
      id INT PRIMARY KEY AUTO_INCREMENT,
      user_id INT NOT NULL,
      test_id INT NOT NULL,
      score DECIMAL(5,2) NOT NULL DEFAULT 0,
      total_marks DECIMAL(8,2) NOT NULL DEFAULT 0,
      correct_answers INT NOT NULL DEFAULT 0,
      total_questions INT NOT NULL DEFAULT 0,
      completed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
      FOREIGN KEY (test_id) REFERENCES tests(id) ON DELETE CASCADE
    )
  `);
  const [marksColumn] = await pool.query("SHOW COLUMNS FROM test_results LIKE 'total_marks'");
  for (const [column, definition] of [
    ['question_type', "VARCHAR(20) NOT NULL DEFAULT 'mcq'"],
    ['correct_answer', 'VARCHAR(500) NULL'],
  ]) {
    const [existing] = await pool.query('SHOW COLUMNS FROM questions LIKE ?', [column]);
    if (!existing.length) await pool.query(`ALTER TABLE questions ADD COLUMN ${column} ${definition}`);
  }
  for (const [column, definition] of [
    ['submission_id', 'VARCHAR(80) NULL'],
    ['submission_reason', "VARCHAR(30) NOT NULL DEFAULT 'manual'"],
    ['result_payload', 'JSON NULL'],
  ]) {
    const [existing] = await pool.query('SHOW COLUMNS FROM test_results LIKE ?', [column]);
    if (!existing.length) await pool.query(`ALTER TABLE test_results ADD COLUMN ${column} ${definition}`);
  }
  const [submissionIndex] = await pool.query("SHOW INDEX FROM test_results WHERE Key_name = 'uq_submission'");
  if (!submissionIndex.length) await pool.query('ALTER TABLE test_results ADD UNIQUE KEY uq_submission (user_id, submission_id)');
  if (marksColumn[0] && !String(marksColumn[0].Type).startsWith('decimal')) {
    await pool.query('ALTER TABLE test_results MODIFY COLUMN total_marks DECIMAL(8,2) NOT NULL DEFAULT 0');
  }
  await pool.query(`
    CREATE TABLE IF NOT EXISTS discussions (
      id INT PRIMARY KEY AUTO_INCREMENT,
      user_id INT NOT NULL,
      course_id INT NULL,
      title VARCHAR(180) NOT NULL,
      content TEXT NOT NULL,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
      FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
    )
  `);
  const [discussionCourseColumn] = await pool.query("SHOW COLUMNS FROM discussions LIKE 'course_id'");
  if (!discussionCourseColumn.length) {
    await pool.query(`ALTER TABLE discussions ADD COLUMN course_id INT NULL,
      ADD CONSTRAINT fk_discussions_course FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE`);
  }
  await pool.query(`
    CREATE TABLE IF NOT EXISTS discussion_replies (
      id INT PRIMARY KEY AUTO_INCREMENT,
      discussion_id INT NOT NULL,
      user_id INT NOT NULL,
      content TEXT NOT NULL,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (discussion_id) REFERENCES discussions(id) ON DELETE CASCADE,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  `);

  const passwordHash = await bcrypt.hash('demo123', 10);
  const seedUsers = [
    ['Demo Admin', 'demo@edumate.com', 'admin'],
    ['Demo Student', 'student@edumate.com', 'student'],
    ['Demo Teacher', 'teacher@edumate.com', 'instructor'],
    ['Demo Admin 2', 'admin@edumate.com', 'admin'],
  ];
  const [[userCount]] = await pool.query('SELECT COUNT(*) AS count FROM users');
  const [[seedCount]] = await pool.query('SELECT COUNT(*) AS count FROM system_seed_users');
  const isFreshInstall = Number(userCount.count) === 0 && Number(seedCount.count) === 0;

  if (!isFreshInstall) {
    // Backfill markers only for demo accounts that still exist. This prevents
    // the first startup after this fix from resurrecting an older deletion.
    await pool.query(
      `INSERT IGNORE INTO system_seed_users (email)
       SELECT email FROM users WHERE email IN (?, ?, ?, ?)`,
      seedUsers.map(([, email]) => email),
    );
  }

  for (const [name, email, role] of seedUsers) {
    if (!isFreshInstall) continue;
    const [marker] = await pool.query(
      'INSERT IGNORE INTO system_seed_users (email) VALUES (?)',
      [email],
    );
    // The marker remains after deletion, so a removed demo account is never
    // recreated on a later server restart.
    if (marker.affectedRows === 1) {
      await pool.query(
        `INSERT IGNORE INTO users (name, email, password_hash, role)
         VALUES (?, ?, ?, ?)`,
        [name, email, passwordHash, role],
      );
    }
  }
  const [seedCourseResult] = await pool.query(
    `INSERT INTO courses (title, description, instructor_id)
     SELECT 'ভর্তি প্রস্তুতির বেসিক', 'প্রতিদিনের প্রস্তুতির জন্য একটি শুরু কোর্স', NULL
     WHERE NOT EXISTS (SELECT 1 FROM courses WHERE title = 'ভর্তি প্রস্তুতির বেসিক')`,
  );
  if (seedCourseResult.affectedRows === 1) {
    await pool.query(`
      INSERT IGNORE INTO course_enrollments (course_id, student_id)
      SELECT c.id, u.id FROM courses c CROSS JOIN users u
      WHERE c.title = 'ভর্তি প্রস্তুতির বেসিক' AND u.role = 'student'
    `);
  }
  await pool.query(`
    UPDATE tests t JOIN courses c ON c.title = 'ভর্তি প্রস্তুতির বেসিক'
    SET t.course_id = c.id WHERE t.course_id IS NULL
  `);
  const [testInsert] = await pool.query(
    `INSERT INTO tests (course_id, title, description, subject, duration)
     SELECT c.id, 'ডেমো মক টেস্ট', 'আপনার প্রস্তুতি যাচাই করুন', 'সাধারণ জ্ঞান', 30
     FROM courses c WHERE c.title = 'ভর্তি প্রস্তুতির বেসিক'
       AND NOT EXISTS (SELECT 1 FROM tests WHERE title = 'ডেমো মক টেস্ট')`,
  );
  const testId = testInsert.insertId || (await pool.query(
    'SELECT id FROM tests WHERE title = ?',
    ['ডেমো মক টেস্ট'],
  ))[0][0]?.id;
  if (testId) {
    await pool.query(
      `INSERT INTO questions (test_id, question_text, options, correct_option, subject)
       SELECT ?, 'বাংলাদেশের রাজধানী কোনটি?', JSON_ARRAY('ঢাকা', 'চট্টগ্রাম', 'রাজশাহী', 'সিলেট'), 0, 'সাধারণ জ্ঞান'
       WHERE NOT EXISTS (SELECT 1 FROM questions WHERE test_id = ?)`,
      [testId, testId],
    );
  }
}

app.get('/api/health', async (_req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ok', database: 'connected' });
  } catch (error) {
    res.status(503).json({ status: 'error', database: 'disconnected', message: error.message });
  }
});

app.post('/api/auth/login', async (req, res) => {
  const { email, password } = req.body || {};
  if (!email || !password) return res.status(400).json({ message: 'Email and password are required' });

  const [rows] = await pool.query(`SELECT ${userFields}, password_hash FROM users WHERE email = ?`, [String(email).trim().toLowerCase()]);
  const user = rows[0];
  if (!user || !(await bcrypt.compare(password, user.password_hash))) {
    return res.status(401).json({ message: 'Invalid email or password' });
  }
  if (user.is_frozen) {
    return res.status(403).json({ message: 'Account is frozen. Contact an administrator.' });
  }
  res.json({ token: issueToken(user), user: publicUser(user), message: 'Login successful' });
});

app.post('/api/auth/signup', async (req, res) => {
  const { name, password, phone, institution } = req.body || {};
  const email = String(req.body?.email ?? '').trim().toLowerCase();
  if (!name || !email || !password) return res.status(400).json({ message: 'Name, email and password are required' });
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || email.length > 190 ||
      typeof password !== 'string' || password.length < 8 || password.length > 200) {
    return res.status(400).json({ message: 'Enter a valid email and a password of at least 8 characters.' });
  }
  try {
    if (phone) {
      const [existingPhone] = await pool.query(
        'SELECT id FROM users WHERE phone = ? LIMIT 1',
        [phone],
      );
      if (existingPhone.length > 0) {
        return res.status(409).json({ message: 'Phone number already registered' });
      }
    }
    const passwordHash = await bcrypt.hash(password, 10);
    const [result] = await pool.query(
      'INSERT INTO users (name, email, password_hash, phone, institution) VALUES (?, ?, ?, ?, ?)',
      [name, email, passwordHash, phone || null, institution || null],
    );
    const [rows] = await pool.query(`SELECT ${userFields} FROM users WHERE id = ?`, [result.insertId]);
    const user = rows[0];
    res.status(201).json({
      token: issueToken(user),
      user: publicUser(user),
      message: 'Account created successfully',
    });
  } catch (error) {
    const duplicate = error.code === 'ER_DUP_ENTRY';
    res.status(duplicate ? 409 : 500).json({
      message: duplicate
          ? 'Email or phone number already registered'
          : 'Unable to create account',
    });
  }
});

app.post('/api/auth/logout', requireAuth, (_req, res) => res.json({ message: 'Logged out' }));

app.get('/api/auth/me', requireAuth, async (req, res) => {
  res.set('Cache-Control', 'no-store');
  const [rows] = await pool.query(
    `SELECT ${userFields} FROM users WHERE id = ?`,
    [req.auth.id],
  );
  if (!rows[0]) return res.status(401).json({ message: 'Account not found' });
  res.json({ user: rows[0] });
});

app.put('/api/profile', requireAuth, async (req, res) => {
  res.set('Cache-Control', 'no-store');
  const { name, phone, institution } = req.body || {};
  if (!name) return res.status(400).json({ message: 'Name is required' });
  try {
    await pool.query(
      'UPDATE users SET name = ?, phone = ?, institution = ? WHERE id = ?',
      [name, phone || null, institution || null, req.auth.id],
    );
    const [rows] = await pool.query(`SELECT ${userFields} FROM users WHERE id = ?`, [req.auth.id]);
    res.json({ message: 'Profile updated', user: rows[0] });
  } catch (error) {
    res.status(error.code === 'ER_DUP_ENTRY' ? 409 : 500).json({
      message: error.code === 'ER_DUP_ENTRY'
          ? 'Phone number already registered'
          : 'Unable to update profile',
    });
  }
});

app.get('/api/student/dashboard', requireAuth, async (req, res) => {
  const [[userStats]] = await pool.query(
    `SELECT COUNT(*) AS tests_completed, COALESCE(AVG(score), 0) AS avg_score
     FROM test_results WHERE user_id = ?`,
    [req.auth.id],
  );
  const [[rankRow]] = await pool.query(
    `SELECT COUNT(*) + 1 AS rank FROM (
       SELECT user_id, AVG(score) AS average_score FROM test_results GROUP BY user_id
     ) scores WHERE average_score > COALESCE((
       SELECT AVG(score) FROM test_results WHERE user_id = ?
     ), 0)`,
    [req.auth.id],
  );
  const [[courseCount]] = await pool.query(
    'SELECT COUNT(*) AS enrolled_courses FROM course_enrollments WHERE student_id = ?',
    [req.auth.id],
  );
  res.json({
    tests_completed: Number(userStats.tests_completed),
    avg_score: Number(Number(userStats.avg_score).toFixed(1)),
    rank: Number(userStats.tests_completed) > 0 ? Number(rankRow.rank) : null,
    enrolled_courses: Number(courseCount.enrolled_courses),
  });
});

app.get('/api/student/courses', requireAuth, async (req, res) => {
  const [courses] = await pool.query(`
    SELECT c.id, c.title, c.description, NULL AS category, NULL AS thumbnail,
      c.instructor_id, 0 AS total_lessons,
      (SELECT COUNT(*) FROM course_enrollments ce WHERE ce.course_id = c.id) AS enrolled_count,
      (SELECT ROUND(AVG(cr.rating), 1) FROM course_ratings cr
       WHERE cr.course_id = c.id) AS rating,
      FALSE AS is_premium, c.created_at
    FROM courses c JOIN course_enrollments e ON e.course_id = c.id
    WHERE e.student_id = ? ORDER BY c.created_at DESC
  `, [req.auth.id]);
  res.json({ courses: courses.map((course) => ({
    ...course,
    rating: course.rating == null ? null : Number(course.rating),
  })) });
});

app.get('/api/student/tests', requireAuth, async (req, res) => {
  const [tests] = await pool.query(`
    SELECT t.id, t.course_id, c.title AS course_title, t.title, t.description,
      t.subject, t.duration, t.per_mcq_mark, t.negative_marking,
      COUNT(q.id) AS total_questions, COUNT(q.id) * t.per_mcq_mark AS total_marks,
      (SELECT COUNT(*) FROM test_results r WHERE r.test_id = t.id AND r.user_id = ?) AS attempt_count,
      t.created_at
    FROM tests t JOIN courses c ON c.id = t.course_id
      JOIN course_enrollments e ON e.course_id = t.course_id AND e.student_id = ?
      LEFT JOIN questions q ON q.test_id = t.id
    WHERE t.published = TRUE
    GROUP BY t.id ORDER BY t.created_at DESC
  `, [req.auth.id, req.auth.id]);
  res.json({ tests: tests.map((test) => ({ ...test,
    is_completed: Number(test.attempt_count) > 0,
    total_marks: Number(test.total_marks),
    per_mcq_mark: Number(test.per_mcq_mark),
    negative_marking: Number(test.negative_marking),
  })) });
});

app.get('/api/student/tests/:id', requireAuth, async (req, res) => {
  const [[test]] = await pool.query(
    `SELECT t.id, t.course_id, c.title AS course_title, t.title, t.description,
      t.subject, t.duration, t.per_mcq_mark, t.negative_marking, t.shuffle_mode,
      t.created_at FROM tests t JOIN courses c ON c.id = t.course_id
      JOIN course_enrollments e ON e.course_id = t.course_id AND e.student_id = ?
      WHERE t.id = ? AND t.published = TRUE`,
    [req.auth.id, req.params.id],
  );
  if (!test) return res.status(404).json({ message: 'Test not found' });
  const [[attempts]] = await pool.query(
    'SELECT COUNT(*) AS count FROM test_results WHERE user_id = ? AND test_id = ?',
    [req.auth.id, req.params.id],
  );
  if (Number(attempts.count) >= 3) return res.status(409).json({ message: 'All 3 attempts have been used' });
  const [questions] = await pool.query(
    `SELECT id, question_text, question_type, options, subject
     FROM questions WHERE test_id = ? ORDER BY id`,
    [req.params.id],
  );
  if (test.shuffle_mode !== 'none') {
    for (let i = questions.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [questions[i], questions[j]] = [questions[j], questions[i]];
    }
  }
  res.json({
    ...test,
    per_mcq_mark: Number(test.per_mcq_mark),
    negative_marking: Number(test.negative_marking),
    total_questions: questions.length,
    total_marks: questions.length * Number(test.per_mcq_mark),
    questions: questions.map((question) => {
      const options = typeof question.options === 'string'
        ? JSON.parse(question.options) : question.options;
      const optionOrder = options.map((_, index) => index);
      if (test.shuffle_mode === 'questions_and_options') {
        for (let i = optionOrder.length - 1; i > 0; i--) {
          const j = Math.floor(Math.random() * (i + 1));
          [optionOrder[i], optionOrder[j]] = [optionOrder[j], optionOrder[i]];
        }
      }
      return { ...question, options: optionOrder.map((index) => options[index]),
        option_order: optionOrder };
    }),
  });
});

app.post('/api/student/tests/submit', requireAuth, async (req, res) => {
  const { test_id: testId, answers = {}, submission_id: suppliedId, submission_reason: reason = 'manual' } = req.body || {};
  const submissionId = suppliedId ?? randomUUID();
  if (typeof submissionId !== 'string' || !/^[a-zA-Z0-9_-]{16,80}$/.test(submissionId) ||
      !['manual', 'time_expired', 'left_exam'].includes(reason)) return res.status(400).json({ message: 'Invalid submission details' });
  if (answers == null || typeof answers !== 'object' || Array.isArray(answers)) {
    return res.status(400).json({ message: 'Answers must be an object' });
  }
  const connection = await pool.getConnection();
  try {
  await connection.beginTransaction();
  // Serialize attempts per student, including simultaneous retries.
  await connection.query('SELECT id FROM users WHERE id = ? FOR UPDATE', [req.auth.id]);
  const [[previous]] = await connection.query('SELECT test_id, result_payload FROM test_results WHERE user_id = ? AND submission_id = ?', [req.auth.id, submissionId]);
  if (previous) {
    await connection.rollback();
    if (Number(previous.test_id) !== Number(testId)) return res.status(409).json({ message: 'Submission belongs to another exam' });
    return res.json(typeof previous.result_payload === 'string' ? JSON.parse(previous.result_payload) : previous.result_payload);
  }
  const [[test]] = await connection.query(
    `SELECT t.id, t.per_mcq_mark, t.negative_marking FROM tests t
     JOIN course_enrollments e ON e.course_id = t.course_id AND e.student_id = ?
     WHERE t.id = ? AND t.published = TRUE`,
    [req.auth.id, testId],
  );
  if (!test) { await connection.rollback(); return res.status(404).json({ message: 'Test not found' }); }
  const [[attempts]] = await connection.query(
    'SELECT COUNT(*) AS count FROM test_results WHERE user_id = ? AND test_id = ?',
    [req.auth.id, testId],
  );
  if (Number(attempts.count) >= 3) {
    await connection.rollback();
    return res.status(409).json({ message: 'All 3 attempts have been used' });
  }
  const [questions] = await connection.query(
    'SELECT id, question_type, correct_option, correct_answer FROM questions WHERE test_id = ?',
    [testId],
  );
  if (questions.length === 0) { await connection.rollback(); return res.status(404).json({ message: 'Test not found' }); }
  const result = { message: 'Test submitted successfully',
    ...gradeExam(questions, answers, test.per_mcq_mark, test.negative_marking),
    submission_reason: reason };
  await connection.query(
    `INSERT INTO test_results
      (user_id, test_id, score, total_marks, correct_answers, total_questions, submission_id, submission_reason, result_payload)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [req.auth.id, testId, result.score, result.total_marks, result.correct_answers, questions.length,
      submissionId, reason, JSON.stringify(result)],
  );
  await connection.commit();
  res.status(201).json(result);
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally { connection.release(); }
});

app.get('/api/student/performance', requireAuth, async (req, res) => {
  const [[summary]] = await pool.query(`
    SELECT COALESCE(AVG(score), 0) AS average_score,
      COUNT(*) AS total_tests_taken, COALESCE(SUM(correct_answers), 0) AS total_correct,
      COALESCE(SUM(total_questions - correct_answers), 0) AS total_incorrect
    FROM test_results WHERE user_id = ?
  `, [req.auth.id]);
  const [recentResults] = await pool.query(`
    SELECT r.id, t.title AS test_title, r.score, r.total_marks,
      r.correct_answers, r.total_questions, r.completed_at
    FROM test_results r JOIN tests t ON t.id = r.test_id
    WHERE r.user_id = ? ORDER BY r.completed_at DESC LIMIT 10
  `, [req.auth.id]);
  const [[rankStats]] = await pool.query(`
    SELECT COUNT(*) AS total_participants,
      SUM(CASE WHEN average_score > (
        SELECT AVG(score) FROM test_results WHERE user_id = ?
      ) THEN 1 ELSE 0 END) + 1 AS rank
    FROM (SELECT user_id, AVG(score) AS average_score
      FROM test_results GROUP BY user_id) participant_scores
  `, [req.auth.id]);
  const [subjectRows] = await pool.query(`
    SELECT COALESCE(NULLIF(TRIM(t.subject), ''), 'General') AS subject,
      ROUND(AVG(r.score), 1) AS score,
      SUM(r.total_questions) AS total_questions,
      SUM(r.correct_answers) AS correct_answers
    FROM test_results r JOIN tests t ON t.id = r.test_id
    WHERE r.user_id = ?
    GROUP BY COALESCE(NULLIF(TRIM(t.subject), ''), 'General')
    ORDER BY subject
  `, [req.auth.id]);
  res.json({
    average_score: Number(Number(summary.average_score).toFixed(1)),
    total_tests_taken: Number(summary.total_tests_taken),
    total_correct: Number(summary.total_correct),
    total_incorrect: Number(summary.total_incorrect),
    rank: Number(summary.total_tests_taken) > 0 ? Number(rankStats.rank) : null,
    total_participants: Number(rankStats.total_participants),
    subject_wise: subjectRows.map((row) => ({
      subject: row.subject,
      score: Number(row.score),
      total_questions: Number(row.total_questions),
      correct_answers: Number(row.correct_answers),
    })),
    recent_results: recentResults,
  });
});

async function canAccessDiscussionCourse(auth, courseId) {
  if (auth.role === 'student') {
    const [[enrollment]] = await pool.query(
      'SELECT 1 FROM course_enrollments WHERE course_id = ? AND student_id = ?',
      [courseId, auth.id],
    );
    return !!enrollment;
  }
  if (auth.role === 'instructor') {
    const [[course]] = await pool.query(
      'SELECT 1 FROM courses WHERE id = ? AND instructor_id = ?',
      [courseId, auth.id],
    );
    return !!course;
  }
  return false;
}

app.get('/api/discussions', requireAuth, async (req, res) => {
  if (!['student', 'instructor'].includes(req.auth.role)) {
    return res.status(403).json({ message: 'Discussion access requires a student or instructor' });
  }
  const hasCourseFilter = req.query.course_id != null;
  const courseId = hasCourseFilter ? Number(req.query.course_id) : null;
  if (hasCourseFilter && (!Number.isInteger(courseId) || courseId <= 0)) {
    return res.status(400).json({ message: 'A valid course is required' });
  }
  if (hasCourseFilter && !await canAccessDiscussionCourse(req.auth, courseId)) {
    return res.status(403).json({ message: 'You do not have access to this course' });
  }
  const where = hasCourseFilter
    ? 'd.course_id = ?'
    : req.auth.role === 'student'
      ? 'd.course_id IS NULL'
      : '(d.course_id IS NULL OR c.instructor_id = ?)';
  const params = hasCourseFilter ? [courseId] : req.auth.role === 'student' ? [] : [req.auth.id];
  const [discussions] = await pool.query(`
    SELECT d.id, d.course_id, c.title AS course_title, d.title, d.content,
      d.user_id AS author_id, u.name AS author_name, u.role AS author_role,
      COUNT(dr.id) AS reply_count, d.created_at
    FROM discussions d JOIN users u ON u.id = d.user_id
      LEFT JOIN courses c ON c.id = d.course_id
      LEFT JOIN discussion_replies dr ON dr.discussion_id = d.id
    WHERE ${where}
    GROUP BY d.id ORDER BY d.created_at DESC, d.id DESC
  `, params);
  res.json({ discussions });
});

app.get('/api/discussions/:id', requireAuth, async (req, res) => {
  const [[discussion]] = await pool.query(`
    SELECT d.id, d.course_id, c.title AS course_title, d.title, d.content,
      d.user_id AS author_id, u.name AS author_name, u.role AS author_role,
      d.created_at
    FROM discussions d JOIN users u ON u.id = d.user_id
      LEFT JOIN courses c ON c.id = d.course_id
    WHERE d.id = ?
  `, [req.params.id]);
  if (!discussion) return res.status(404).json({ message: 'Discussion not found' });
  if (discussion.course_id == null) {
    if (!['student', 'instructor'].includes(req.auth.role)) {
      return res.status(403).json({ message: 'This discussion is for students and instructors' });
    }
  } else if (!await canAccessDiscussionCourse(req.auth, discussion.course_id)) {
    return res.status(403).json({ message: 'You do not have access to this course' });
  }
  const [replies] = await pool.query(`
    SELECT dr.id, dr.content, dr.user_id AS author_id,
      u.name AS author_name, u.role AS author_role, dr.created_at
    FROM discussion_replies dr JOIN users u ON u.id = dr.user_id
    WHERE dr.discussion_id = ? ORDER BY dr.created_at ASC
  `, [req.params.id]);
  res.json({ ...discussion, reply_count: replies.length, replies });
});

app.post('/api/discussions', requireAuth, async (req, res) => {
  if (!['student', 'instructor'].includes(req.auth.role)) {
    return res.status(403).json({ message: 'Only students and instructors can start discussions' });
  }
  const title = String(req.body?.title ?? '').trim();
  const content = String(req.body?.content ?? '').trim();
  const hasCourse = req.body?.course_id != null;
  const courseId = hasCourse ? Number(req.body.course_id) : null;
  if (req.auth.role === 'instructor' && !hasCourse) {
    return res.status(403).json({ message: 'Instructors can only start course discussions' });
  }
  if (!title || !content || title.length > 180) {
    return res.status(400).json({ message: 'A title (up to 180 characters) and content are required' });
  }
  if (hasCourse && (!Number.isInteger(courseId) || courseId <= 0)) {
    return res.status(400).json({ message: 'A valid course is required' });
  }
  if (hasCourse && !await canAccessDiscussionCourse(req.auth, courseId)) {
    return res.status(403).json({ message: 'You do not have access to this course' });
  }
  await pool.query(
    'INSERT INTO discussions (user_id, course_id, title, content) VALUES (?, ?, ?, ?)',
    [req.auth.id, courseId, title, content],
  );
  res.status(201).json({ message: 'Discussion created' });
});

app.post('/api/discussions/:id/reply', requireAuth, async (req, res) => {
  if (!['student', 'instructor'].includes(req.auth.role)) {
    return res.status(403).json({ message: 'Only students and instructors can reply' });
  }
  const discussionId = Number(req.params.id);
  const content = String(req.body?.content ?? '').trim();
  if (!Number.isInteger(discussionId) || discussionId <= 0 || !content) {
    return res.status(400).json({ message: 'A discussion and reply content are required' });
  }
  const [[discussion]] = await pool.query('SELECT id, course_id FROM discussions WHERE id = ?', [discussionId]);
  if (!discussion) return res.status(404).json({ message: 'Discussion not found' });
  if (discussion.course_id == null) {
    if (!['student', 'instructor'].includes(req.auth.role)) {
      return res.status(403).json({ message: 'This discussion is for students and instructors' });
    }
  } else if (!await canAccessDiscussionCourse(req.auth, discussion.course_id)) {
    return res.status(403).json({ message: 'You do not have access to this course' });
  }
  await pool.query(
    'INSERT INTO discussion_replies (discussion_id, user_id, content) VALUES (?, ?, ?)',
    [discussionId, req.auth.id, content],
  );
  res.status(201).json({ message: 'Reply created' });
});

app.get('/api/student/profile', requireAuth, async (req, res) => {
  const [rows] = await pool.query(`SELECT ${userFields} FROM users WHERE id = ?`, [req.auth.id]);
  if (!rows[0]) return res.status(404).json({ message: 'User not found' });
  res.json(rows[0]);
});

app.put('/api/student/profile', requireAuth, async (req, res) => {
  const { name, phone, institution } = req.body || {};
  if (!name) return res.status(400).json({ message: 'Name is required' });
  try {
    await pool.query(
      'UPDATE users SET name = ?, phone = ?, institution = ? WHERE id = ?',
      [name, phone || null, institution || null, req.auth.id],
    );
    const [rows] = await pool.query(`SELECT ${userFields} FROM users WHERE id = ?`, [req.auth.id]);
    res.json({ message: 'Profile updated', user: rows[0] });
  } catch (error) {
    res.status(error.code === 'ER_DUP_ENTRY' ? 409 : 500).json({
      message: error.code === 'ER_DUP_ENTRY' ? 'Phone number already registered' : 'Unable to update profile',
    });
  }
});

app.post('/api/student/report-bug', requireAuth, async (req, res) => {
  const { title, description } = req.body || {};
  if (!title || !description) return res.status(400).json({ message: 'Title and description are required' });
  await pool.query(
    'INSERT INTO reports (user_id, title, description) VALUES (?, ?, ?)',
    [req.auth.id, title, description],
  );
  res.status(201).json({ message: 'Bug report submitted' });
});

app.get('/api/packages', requireAuth, async (_req, res) => {
  const [packages] = await pool.query(
    'SELECT id, title, subtitle, price, period, features FROM packages ORDER BY id',
  );
  res.json({ packages: packages.map((item) => ({
    ...item,
    features: typeof item.features === 'string' ? JSON.parse(item.features) : item.features,
  })) });
});

app.get('/api/student/courses/:id', requireAuth, async (req, res) => {
  const [[course]] = await pool.query(
    `SELECT c.id, c.title, c.description, c.instructor_id, c.created_at,
      (SELECT ROUND(AVG(cr.rating), 1) FROM course_ratings cr
       WHERE cr.course_id = c.id) AS rating,
      (SELECT COUNT(*) FROM course_ratings cr WHERE cr.course_id = c.id) AS rating_count,
      (SELECT cr.rating FROM course_ratings cr
       WHERE cr.course_id = c.id AND cr.student_id = ?) AS my_rating
     FROM courses c JOIN course_enrollments e ON e.course_id = c.id
     WHERE c.id = ? AND e.student_id = ?`,
    [req.auth.id, req.params.id, req.auth.id],
  );
  if (!course) return res.status(404).json({ message: 'Course not found' });
  const [courseContent] = await pool.query(
    `SELECT id, title, type, url, description, created_at
     FROM course_content WHERE course_id = ? ORDER BY created_at DESC`,
    [req.params.id],
  );
  res.json({
    ...course,
    rating: course.rating == null ? null : Number(course.rating),
    rating_count: Number(course.rating_count),
    my_rating: course.my_rating == null ? null : Number(course.my_rating),
    content: courseContent,
  });
});

app.post('/api/student/courses/:id/rating', requireAuth, async (req, res) => {
  if (req.auth.role !== 'student') {
    return res.status(403).json({ message: 'Student access required' });
  }
  const rating = req.body?.rating;
  if (!Number.isInteger(rating) || rating < 1 || rating > 5) {
    return res.status(400).json({ message: 'Rating must be an integer from 1 to 5' });
  }
  const [[enrollment]] = await pool.query(
    'SELECT 1 FROM course_enrollments WHERE course_id = ? AND student_id = ?',
    [req.params.id, req.auth.id],
  );
  if (!enrollment) return res.status(404).json({ message: 'Course not found' });
  try {
    await pool.query(
      'INSERT INTO course_ratings (course_id, student_id, rating) VALUES (?, ?, ?)',
      [req.params.id, req.auth.id, rating],
    );
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ message: 'You have already rated this course' });
    }
    throw error;
  }
  res.json({ message: 'Rating saved', rating });
});

app.get('/api/instructor/dashboard', requireAuth, requireInstructor, async (req, res) => {
  const [[courseStats]] = await pool.query(
    'SELECT COUNT(*) AS total_courses FROM courses WHERE instructor_id = ?',
    [req.auth.id],
  );
  const [[studentStats]] = await pool.query(
    `SELECT COUNT(DISTINCT e.student_id) AS total_students
     FROM course_enrollments e JOIN courses c ON c.id = e.course_id
     WHERE c.instructor_id = ?`,
    [req.auth.id],
  );
  const [[examStats]] = await pool.query(
    'SELECT COUNT(*) AS total_exams FROM tests t JOIN courses c ON c.id = t.course_id WHERE c.instructor_id = ?',
    [req.auth.id],
  );
  const [[ratingStats]] = await pool.query(`
    SELECT ROUND(AVG(cr.rating), 1) AS avg_rating
    FROM course_ratings cr JOIN courses c ON c.id = cr.course_id
    WHERE c.instructor_id = ?
  `, [req.auth.id]);
  res.json({
    total_courses: Number(courseStats.total_courses),
    total_students: Number(studentStats.total_students),
    total_exams: Number(examStats.total_exams),
    avg_rating: ratingStats.avg_rating == null ? null : Number(ratingStats.avg_rating),
  });
});

app.get('/api/instructor/courses', requireAuth, requireInstructor, async (req, res) => {
  const [courses] = await pool.query(
    `SELECT c.id, c.title, c.description, NULL AS category, NULL AS thumbnail,
      c.instructor_id, 0 AS total_lessons,
      (SELECT COUNT(*) FROM course_enrollments e WHERE e.course_id = c.id) AS enrolled_count,
      (SELECT ROUND(AVG(cr.rating), 1) FROM course_ratings cr
       WHERE cr.course_id = c.id) AS rating,
      FALSE AS is_premium, c.created_at
     FROM courses c WHERE c.instructor_id = ? ORDER BY c.created_at DESC`,
    [req.auth.id],
  );
  res.json({ courses: courses.map((course) => ({
    ...course,
    rating: course.rating == null ? null : Number(course.rating),
  })) });
});

app.get('/api/instructor/courses/:id/content', requireAuth, requireInstructor, async (req, res) => {
  const [[course]] = await pool.query(
    'SELECT id FROM courses WHERE id = ? AND instructor_id = ?',
    [req.params.id, req.auth.id],
  );
  if (!course) return res.status(404).json({ message: 'Course not found' });
  const [courseContent] = await pool.query(
    `SELECT id, title, type, url, description, created_at
     FROM course_content WHERE course_id = ? ORDER BY created_at DESC`,
    [req.params.id],
  );
  res.json({ content: courseContent });
});

app.post('/api/instructor/courses/:id/content', requireAuth, requireInstructor, async (req, res) => {
  const { title, type, url, description } = req.body || {};
  if (!title || !['pdf', 'video', 'exam', 'live'].includes(type) || !url || !description) {
    return res.status(400).json({ message: 'Title, type, URL and description are required' });
  }
  const [[course]] = await pool.query(
    'SELECT id FROM courses WHERE id = ? AND instructor_id = ?',
    [req.params.id, req.auth.id],
  );
  if (!course) return res.status(404).json({ message: 'Course not found' });
  const [result] = await pool.query(
    `INSERT INTO course_content
      (course_id, instructor_id, title, type, url, description)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [req.params.id, req.auth.id, title, type, url, description || null],
  );
  res.status(201).json({ message: 'Course content added', id: result.insertId });
});

app.delete('/api/instructor/courses/:courseId/content/:contentId', requireAuth, requireInstructor, async (req, res) => {
  const [result] = await pool.query(
    `DELETE FROM course_content
     WHERE id = ? AND course_id = ? AND instructor_id = ?`,
    [req.params.contentId, req.params.courseId, req.auth.id],
  );
  if (result.affectedRows === 0) return res.status(404).json({ message: 'Content not found' });
  res.json({ message: 'Course content deleted' });
});

app.get('/api/instructor/students', requireAuth, requireInstructor, async (req, res) => {
  const [students] = await pool.query(
    `SELECT u.id, u.name, u.email, enrolled.enrolled_courses,
      COALESCE(results.tests_completed, 0) AS tests_completed,
      results.average_score
     FROM (
       SELECT e.student_id, COUNT(*) AS enrolled_courses
       FROM course_enrollments e JOIN courses c ON c.id = e.course_id
       WHERE c.instructor_id = ? GROUP BY e.student_id
     ) enrolled
     JOIN users u ON u.id = enrolled.student_id
     LEFT JOIN (
       SELECT r.user_id, COUNT(*) AS tests_completed,
         ROUND(AVG(r.score), 1) AS average_score
       FROM test_results r JOIN tests t ON t.id = r.test_id
         JOIN courses c ON c.id = t.course_id
         JOIN course_enrollments e ON e.course_id = t.course_id AND e.student_id = r.user_id
       WHERE c.instructor_id = ? GROUP BY r.user_id
     ) results ON results.user_id = u.id
     WHERE u.role = 'student' ORDER BY u.name, u.id`,
    [req.auth.id, req.auth.id],
  );
  res.json({ students });
});

app.get('/api/instructor/students/:id/results', requireAuth, requireInstructor, async (req, res) => {
  const [[student]] = await pool.query(
    `SELECT u.id FROM users u JOIN course_enrollments e ON e.student_id = u.id
       JOIN courses c ON c.id = e.course_id
     WHERE u.id = ? AND u.role = 'student' AND c.instructor_id = ? LIMIT 1`,
    [req.params.id, req.auth.id],
  );
  if (!student) return res.status(404).json({ message: 'Student not found in your courses' });
  const [results] = await pool.query(
    `SELECT r.id, c.title AS course_title, t.title AS exam_title,
       r.score, r.correct_answers, r.total_questions, r.completed_at
     FROM test_results r JOIN tests t ON t.id = r.test_id
       JOIN courses c ON c.id = t.course_id
       JOIN course_enrollments e ON e.course_id = t.course_id AND e.student_id = r.user_id
     WHERE r.user_id = ? AND c.instructor_id = ?
     ORDER BY r.completed_at DESC, r.id DESC`,
    [req.params.id, req.auth.id],
  );
  res.json({ results });
});

app.get('/api/instructor/profile', requireAuth, requireInstructor, async (req, res) => {
  const [rows] = await pool.query(`SELECT ${userFields} FROM users WHERE id = ?`, [req.auth.id]);
  if (!rows[0]) return res.status(404).json({ message: 'User not found' });
  res.json(rows[0]);
});

app.post('/api/instructor/report-bug', requireAuth, async (req, res) => {
  const { title, description } = req.body || {};
  if (!title || !description) return res.status(400).json({ message: 'Title and description are required' });
  await pool.query(
    'INSERT INTO reports (user_id, title, description) VALUES (?, ?, ?)',
    [req.auth.id, title, description],
  );
  res.status(201).json({ message: 'Bug report submitted' });
});

app.get('/api/admin/dashboard', requireAuth, requireAdmin, async (_req, res) => {
  const [[totals]] = await pool.query(`
    SELECT
      COUNT(*) AS total_users,
      SUM(role = 'student') AS total_students,
      SUM(role = 'instructor') AS total_instructors
    FROM users
  `);
  const [[courses]] = await pool.query('SELECT COUNT(*) AS total_courses FROM courses');
  const [[exams]] = await pool.query('SELECT COUNT(id) AS total_exams_created FROM tests');
  res.json({
    total_users: Number(totals.total_users),
    total_students: Number(totals.total_students),
    total_instructors: Number(totals.total_instructors),
    total_courses: Number(courses.total_courses),
    total_exams_created: Number(exams.total_exams_created),
  });
});

app.post('/api/admin/courses', requireAuth, requireAdmin, async (req, res) => {
  const { title, description, instructor_id: instructorId } = req.body || {};
  if (typeof title !== 'string' || !title.trim()) {
    return res.status(400).json({ message: 'Course title is required' });
  }
  if (instructorId != null && (!Number.isInteger(instructorId) || instructorId <= 0)) {
    return res.status(400).json({ message: 'A valid instructor is required' });
  }
  if (instructorId != null) {
    const [[instructor]] = await pool.query(
      "SELECT id FROM users WHERE id = ? AND role = 'instructor'",
      [instructorId],
    );
    if (!instructor) return res.status(400).json({ message: 'Instructor not found' });
  }
  const [result] = await pool.query(
    'INSERT INTO courses (title, description, instructor_id) VALUES (?, ?, ?)',
    [title.trim(), typeof description === 'string' ? description.trim() : null,
      instructorId ?? null],
  );
  res.status(201).json({ message: 'Course created', id: result.insertId });
});

app.get('/api/admin/courses', requireAuth, requireAdmin, async (_req, res) => {
  const [courses] = await pool.query(
    `SELECT c.id, c.title, c.description, c.instructor_id,
      u.name AS instructor_name, c.created_at,
      (SELECT COUNT(*) FROM course_enrollments e WHERE e.course_id = c.id) AS enrolled_count
     FROM courses c LEFT JOIN users u ON u.id = c.instructor_id
     ORDER BY c.created_at DESC, c.id DESC`,
  );
  res.json({ courses });
});

app.put('/api/admin/courses/:id', requireAuth, requireAdmin, async (req, res) => {
  const { title, description, instructor_id: instructorId } = req.body || {};
  if (typeof title !== 'string' || !title.trim()) {
    return res.status(400).json({ message: 'Course title is required' });
  }
  if (instructorId != null && (!Number.isInteger(instructorId) || instructorId <= 0)) {
    return res.status(400).json({ message: 'A valid instructor is required' });
  }
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    if (instructorId != null) {
      const [[instructor]] = await connection.query(
        "SELECT id FROM users WHERE id = ? AND role = 'instructor'",
        [instructorId],
      );
      if (!instructor) {
        await connection.rollback();
        return res.status(400).json({ message: 'Instructor not found' });
      }
    }
    const [result] = await connection.query(
      'UPDATE courses SET title = ?, description = ?, instructor_id = ? WHERE id = ?',
      [title.trim(), typeof description === 'string' ? description.trim() : null,
        instructorId ?? null, req.params.id],
    );
    if (result.affectedRows === 0) {
      await connection.rollback();
      return res.status(404).json({ message: 'Course not found' });
    }
    if (instructorId != null) {
      await connection.query(
        'UPDATE course_content SET instructor_id = ? WHERE course_id = ?',
        [instructorId, req.params.id],
      );
    }
    await connection.commit();
    res.json({ message: 'Course updated' });
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
});

app.delete('/api/admin/courses/:id', requireAuth, requireAdmin, async (req, res) => {
  const [result] = await pool.query('DELETE FROM courses WHERE id = ?', [req.params.id]);
  if (result.affectedRows === 0) return res.status(404).json({ message: 'Course not found' });
  res.json({ message: 'Course deleted' });
});

app.get('/api/admin/courses/:id/students', requireAuth, requireAdmin, async (req, res) => {
  const [[course]] = await pool.query('SELECT id FROM courses WHERE id = ?', [req.params.id]);
  if (!course) return res.status(404).json({ message: 'Course not found' });
  const [students] = await pool.query(
    `SELECT u.id, u.name, u.email,
      IF(e.student_id IS NULL, 0, 1) AS is_enrolled
     FROM users u LEFT JOIN course_enrollments e
       ON e.student_id = u.id AND e.course_id = ?
     WHERE u.role = 'student'
     ORDER BY is_enrolled DESC, u.name`,
    [req.params.id],
  );
  res.json({ students });
});

app.post('/api/admin/courses/:id/students', requireAuth, requireAdmin, async (req, res) => {
  const studentId = req.body?.student_id;
  if (!Number.isInteger(studentId) || studentId <= 0) {
    return res.status(400).json({ message: 'A valid student is required' });
  }
  const [[course]] = await pool.query('SELECT id FROM courses WHERE id = ?', [req.params.id]);
  if (!course) return res.status(404).json({ message: 'Course not found' });
  const [[student]] = await pool.query(
    "SELECT id FROM users WHERE id = ? AND role = 'student'",
    [studentId],
  );
  if (!student) return res.status(400).json({ message: 'Student not found' });
  const [result] = await pool.query(
    'INSERT IGNORE INTO course_enrollments (course_id, student_id) VALUES (?, ?)',
    [req.params.id, studentId],
  );
  res.status(result.affectedRows === 1 ? 201 : 200).json({ message: 'Student added to course' });
});

app.delete('/api/admin/courses/:id/students/:studentId', requireAuth, requireAdmin, async (req, res) => {
  const [result] = await pool.query(
    'DELETE FROM course_enrollments WHERE course_id = ? AND student_id = ?',
    [req.params.id, req.params.studentId],
  );
  if (result.affectedRows === 0) return res.status(404).json({ message: 'Enrollment not found' });
  res.json({ message: 'Student removed from course' });
});

function validateExam(body) {
  const title = String(body?.title ?? '').trim();
  const subject = String(body?.subject ?? '').trim();
  const description = String(body?.description ?? '').trim();
  const duration = Number(body?.duration);
  const perMcqMark = Number(body?.per_mcq_mark);
  const negativeMarking = Number(body?.negative_marking ?? 0);
  const shuffleMode = body?.shuffle_mode ?? 'none';
  const questions = body?.questions;
  if (!title || !subject || title.length > 180 || subject.length > 120) return null;
  if (!Number.isInteger(duration) || duration < 5 || duration > 60) return null;
  if (!Number.isFinite(perMcqMark) || perMcqMark <= 0 || perMcqMark > 100) return null;
  if (!Number.isFinite(negativeMarking) || negativeMarking < 0 || negativeMarking >= perMcqMark) return null;
  if (!['none', 'questions', 'questions_and_options'].includes(shuffleMode)) return null;
  if (!Array.isArray(questions) || questions.length < 1 || questions.length > 100) return null;
  const cleanQuestions = questions.map(cleanQuestion);
  if (cleanQuestions.some((q) => !q)) return null;
  return { title, subject, description, duration, perMcqMark, negativeMarking,
    shuffleMode, questions: cleanQuestions };
}

app.get('/api/instructor/courses/:id/exams', requireAuth, requireTeacher, async (req, res) => {
  const [[course]] = await pool.query(
    'SELECT id FROM courses WHERE id = ? AND instructor_id = ?',
    [req.params.id, req.auth.id],
  );
  if (!course) return res.status(404).json({ message: 'Course not found' });
  const [exams] = await pool.query(`
    SELECT t.*, COUNT(DISTINCT q.id) AS total_questions,
      COUNT(DISTINCT r.id) AS attempt_count
    FROM tests t LEFT JOIN questions q ON q.test_id = t.id
      LEFT JOIN test_results r ON r.test_id = t.id
    WHERE t.course_id = ? GROUP BY t.id ORDER BY t.created_at DESC, t.id DESC
  `, [req.params.id]);
  res.json({ exams });
});

app.post('/api/instructor/courses/:id/exams', requireAuth, requireTeacher, async (req, res) => {
  const courseId = Number(req.params.id);
  const exam = validateExam(req.body);
  if (!Number.isInteger(courseId) || courseId <= 0 || !exam) {
    return res.status(400).json({ message: 'Provide a course, title, subject, duration (5–60 minutes), marking, and at least one complete MCQ or fill-in-the-blank question' });
  }
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const [[course]] = await connection.query(
      'SELECT id FROM courses WHERE id = ? AND instructor_id = ?',
      [courseId, req.auth.id],
    );
    if (!course) {
      await connection.rollback();
      return res.status(404).json({ message: 'Course not found' });
    }
    const [result] = await connection.query(`
      INSERT INTO tests (course_id, title, description, subject, duration,
        per_mcq_mark, negative_marking, shuffle_mode, published)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, TRUE)
    `, [courseId, exam.title, exam.description, exam.subject, exam.duration,
      exam.perMcqMark, exam.negativeMarking, exam.shuffleMode]);
    for (const question of exam.questions) {
      await connection.query(`
        INSERT INTO questions (test_id, question_text, options, correct_option, subject, question_type, correct_answer)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `, [result.insertId, question.question_text, JSON.stringify(question.options),
        question.correct_option, exam.subject, question.question_type, question.correct_answer]);
    }
    await connection.commit();
    res.status(201).json({ message: 'Exam published', id: result.insertId });
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
});

app.get('/api/instructor/exams/:id', requireAuth, requireTeacher, async (req, res) => {
  const [[exam]] = await pool.query(
    `SELECT t.* FROM tests t JOIN courses c ON c.id = t.course_id
     WHERE t.id = ? AND c.instructor_id = ?`,
    [req.params.id, req.auth.id],
  );
  if (!exam) return res.status(404).json({ message: 'Exam not found' });
  const [questions] = await pool.query(
    'SELECT id, question_text, options, correct_option, question_type, correct_answer FROM questions WHERE test_id = ? ORDER BY id',
    [req.params.id],
  );
  res.json({ exam: { ...exam, questions: questions.map((q) => ({
    ...q, options: typeof q.options === 'string' ? JSON.parse(q.options) : q.options,
  })) } });
});

app.put('/api/instructor/exams/:id', requireAuth, requireTeacher, async (req, res) => {
  const exam = validateExam(req.body);
  if (!exam) return res.status(400).json({ message: 'Complete all exam fields and questions' });
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const [[existing]] = await connection.query(
      `SELECT t.id FROM tests t JOIN courses c ON c.id = t.course_id
       WHERE t.id = ? AND c.instructor_id = ? FOR UPDATE`,
      [req.params.id, req.auth.id],
    );
    if (!existing) {
      await connection.rollback();
      return res.status(404).json({ message: 'Exam not found' });
    }
    const [[attempts]] = await connection.query('SELECT COUNT(*) AS count FROM test_results WHERE test_id = ?', [req.params.id]);
    if (Number(attempts.count) > 0) {
      await connection.rollback();
      return res.status(409).json({ message: 'An exam with student attempts cannot be edited' });
    }
    await connection.query(`
      UPDATE tests SET title = ?, description = ?, subject = ?, duration = ?,
        per_mcq_mark = ?, negative_marking = ?, shuffle_mode = ? WHERE id = ?
    `, [exam.title, exam.description, exam.subject, exam.duration, exam.perMcqMark,
      exam.negativeMarking, exam.shuffleMode, req.params.id]);
    await connection.query('DELETE FROM questions WHERE test_id = ?', [req.params.id]);
    for (const question of exam.questions) {
      await connection.query(`
        INSERT INTO questions (test_id, question_text, options, correct_option, subject, question_type, correct_answer)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `, [req.params.id, question.question_text, JSON.stringify(question.options),
        question.correct_option, exam.subject, question.question_type, question.correct_answer]);
    }
    await connection.commit();
    res.json({ message: 'Exam updated' });
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
});

app.patch('/api/instructor/exams/:id/publish', requireAuth, requireTeacher, async (req, res) => {
  if (typeof req.body?.published !== 'boolean') {
    return res.status(400).json({ message: 'Published must be true or false' });
  }
  const [result] = await pool.query(
    `UPDATE tests t JOIN courses c ON c.id = t.course_id
     SET t.published = ? WHERE t.id = ? AND c.instructor_id = ?`,
    [req.body.published, req.params.id, req.auth.id]);
  if (!result.affectedRows) return res.status(404).json({ message: 'Exam not found' });
  res.json({ message: req.body.published ? 'Exam published' : 'Exam hidden' });
});

app.delete('/api/instructor/exams/:id', requireAuth, requireTeacher, async (req, res) => {
  const [[owned]] = await pool.query(
    `SELECT t.id FROM tests t JOIN courses c ON c.id = t.course_id
     WHERE t.id = ? AND c.instructor_id = ?`,
    [req.params.id, req.auth.id],
  );
  if (!owned) return res.status(404).json({ message: 'Exam not found' });
  const [[attempts]] = await pool.query('SELECT COUNT(*) AS count FROM test_results WHERE test_id = ?', [req.params.id]);
  if (Number(attempts.count) > 0) {
    return res.status(409).json({ message: 'An exam with student attempts cannot be deleted' });
  }
  const [result] = await pool.query(
    `DELETE t FROM tests t JOIN courses c ON c.id = t.course_id
     WHERE t.id = ? AND c.instructor_id = ?`,
    [req.params.id, req.auth.id],
  );
  if (!result.affectedRows) return res.status(404).json({ message: 'Exam not found' });
  res.json({ message: 'Exam deleted' });
});

app.get('/api/admin/users', requireAuth, requireAdmin, async (_req, res) => {
  const [users] = await pool.query(`SELECT ${userFields} FROM users ORDER BY created_at DESC`);
  res.json({ users });
});

app.post('/api/admin/users', requireAuth, requireAdmin, async (req, res) => {
  const { name, email, password, role, phone, institution } = req.body || {};
  if (!name || !email || !password || !role) {
    return res.status(400).json({
      message: 'Name, email, password, and role are required',
    });
  }
  if (!['student', 'instructor', 'admin'].includes(role)) {
    return res.status(400).json({ message: 'Invalid role' });
  }
  try {
    const passwordHash = await bcrypt.hash(password, 10);
    const [result] = await pool.query(
      `INSERT INTO users
        (name, email, password_hash, role, phone, institution)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [name, email, passwordHash, role, phone || null, institution || null],
    );
    const [rows] = await pool.query(
      `SELECT ${userFields} FROM users WHERE id = ?`,
      [result.insertId],
    );
    res.status(201).json({ user: rows[0], message: 'User created' });
  } catch (error) {
    const duplicate = error.code === 'ER_DUP_ENTRY';
    res.status(duplicate ? 409 : 500).json({
      message: duplicate
          ? 'Email or phone number already registered'
          : 'Unable to create user',
    });
  }
});

app.put('/api/admin/users/:id', requireAuth, requireAdmin, async (req, res) => {
  const { role } = req.body || {};
  if (!['student', 'instructor', 'admin'].includes(role)) return res.status(400).json({ message: 'Invalid role' });
  if (Number(req.params.id) === req.auth.id && role !== 'admin') {
    return res.status(400).json({ message: 'You cannot remove your own admin access' });
  }
  const [result] = await pool.query('UPDATE users SET role = ? WHERE id = ?', [role, req.params.id]);
  if (result.affectedRows === 0) return res.status(404).json({ message: 'User not found' });
  res.json({ message: 'User updated' });
});

app.patch('/api/admin/users/:id/freeze', requireAuth, requireAdmin, async (req, res) => {
  const isFrozen = req.body?.is_frozen;
  if (typeof isFrozen !== 'boolean') {
    return res.status(400).json({ message: 'is_frozen must be true or false' });
  }
  if (Number(req.params.id) === req.auth.id && isFrozen) {
    return res.status(400).json({ message: 'You cannot freeze your own account' });
  }
  const [result] = await pool.query(
    'UPDATE users SET is_frozen = ? WHERE id = ?',
    [isFrozen, req.params.id],
  );
  if (!result.affectedRows) return res.status(404).json({ message: 'User not found' });
  res.json({ message: isFrozen ? 'User frozen' : 'User unfrozen', is_frozen: isFrozen });
});

app.delete('/api/admin/users/:id', requireAuth, requireAdmin, async (req, res) => {
  if (Number(req.params.id) === req.auth.id) {
    return res.status(400).json({ message: 'You cannot remove your own account' });
  }
  const [result] = await pool.query('DELETE FROM users WHERE id = ?', [req.params.id]);
  if (result.affectedRows === 0) {
    return res.status(404).json({ message: 'User not found' });
  }
  res.json({ message: 'User deleted' });
});

app.get('/api/reports', requireAuth, requireAdmin, async (_req, res) => {
  const [[summary]] = await pool.query(`
    SELECT COUNT(*) AS total_reports,
      SUM(status = 'open') AS open_reports,
      SUM(status = 'resolved') AS resolved_reports
    FROM reports
  `);
  const [[examSummary]] = await pool.query(
    'SELECT COUNT(id) AS total_exams_created FROM tests',
  );
  const [[registrationSummary]] = await pool.query(
    'SELECT COUNT(id) AS total_registrations FROM users',
  );
  const [[testSummary]] = await pool.query(
    'SELECT COUNT(id) AS total_tests_completed FROM test_results',
  );
  const [bugReports] = await pool.query(`
    SELECT r.id, r.title, r.description, r.status, r.created_at,
      r.user_id, u.name AS reporter_name, u.email AS reporter_email,
      u.role AS reporter_role
    FROM reports r LEFT JOIN users u ON u.id = r.user_id
    ORDER BY r.created_at DESC
  `);
  res.json({
    total_reports: Number(summary.total_reports),
    open_reports: Number(summary.open_reports),
    resolved_reports: Number(summary.resolved_reports),
    total_registrations: Number(registrationSummary.total_registrations),
    total_tests_completed: Number(testSummary.total_tests_completed),
    total_exams_created: Number(examSummary.total_exams_created),
    total_bug_reports: Number(summary.total_reports),
    bug_reports: bugReports,
  });
});

app.put('/api/reports/:id/status', requireAuth, requireAdmin, async (req, res) => {
  const { status } = req.body || {};
  if (!['open', 'in_progress', 'resolved'].includes(status)) {
    return res.status(400).json({ message: 'Invalid report status' });
  }
  const [result] = await pool.query(
    'UPDATE reports SET status = ? WHERE id = ?',
    [status, req.params.id],
  );
  if (result.affectedRows === 0) {
    return res.status(404).json({ message: 'Bug report not found' });
  }
  res.json({ message: 'Bug report status updated', status });
});

app.get('/api/reports/mine', requireAuth, async (req, res) => {
  const [reports] = await pool.query(
    `SELECT id, title, description, status, created_at
     FROM reports WHERE user_id = ? ORDER BY created_at DESC`,
    [req.auth.id],
  );
  res.json({ reports });
});

app.get('/api/admin/content', requireAuth, requireAdmin, async (_req, res) => {
  const [content] = await pool.query('SELECT id, title, type, description FROM content ORDER BY created_at DESC');
  res.json({ content });
});

app.delete('/api/admin/content/:id', requireAuth, requireAdmin, async (req, res) => {
  await pool.query('DELETE FROM content WHERE id = ?', [req.params.id]);
  res.json({ message: 'Content deleted' });
});

app.post('/api/admin/packages', requireAuth, requireAdmin, async (req, res) => {
  const { title, subtitle, price, period, features = [] } = req.body || {};
  if (!title || !price || !Array.isArray(features)) {
    return res.status(400).json({ message: 'Title, price and features are required' });
  }
  const [result] = await pool.query(
    'INSERT INTO packages (title, subtitle, price, period, features) VALUES (?, ?, ?, ?, ?)',
    [title, subtitle || null, price, period || null, JSON.stringify(features)],
  );
  res.status(201).json({ message: 'Package created', id: result.insertId });
});

app.put('/api/admin/packages/:id', requireAuth, requireAdmin, async (req, res) => {
  const { title, subtitle, price, period, features = [] } = req.body || {};
  if (!title || !price || !Array.isArray(features)) {
    return res.status(400).json({ message: 'Title, price and features are required' });
  }
  const [result] = await pool.query(
    'UPDATE packages SET title = ?, subtitle = ?, price = ?, period = ?, features = ? WHERE id = ?',
    [title, subtitle || null, price, period || null, JSON.stringify(features), req.params.id],
  );
  if (result.affectedRows === 0) return res.status(404).json({ message: 'Package not found' });
  res.json({ message: 'Package updated' });
});

app.delete('/api/admin/packages/:id', requireAuth, requireAdmin, async (req, res) => {
  await pool.query('DELETE FROM packages WHERE id = ?', [req.params.id]);
  res.json({ message: 'Package deleted' });
});

app.use((error, _req, res, _next) => {
  console.error(error);
  res.status(500).json({ message: 'Internal server error' });
});

initializeDatabase()
  .then(() => {
    app.listen(port, '0.0.0.0', () => {
      console.log(`EduMate API listening on http://0.0.0.0:${port}`);
    });
  })
  .catch((error) => {
    console.error(
      `Database startup failed: ${error.message}\n` +
        'Start MySQL and check DB_HOST, DB_PORT, DB_USER, and DB_PASSWORD in backend/.env.',
    );
    process.exit(1);
  });
