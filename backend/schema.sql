CREATE DATABASE IF NOT EXISTS edumate CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE edumate;

CREATE TABLE IF NOT EXISTS users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(120) NOT NULL,
  email VARCHAR(190) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('student', 'instructor', 'admin') NOT NULL DEFAULT 'student',
  phone VARCHAR(40) UNIQUE,
  institution VARCHAR(180),
  avatar TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Keeps one-time demo-account seeding from recreating accounts removed by an admin.
CREATE TABLE IF NOT EXISTS system_seed_users (
  email VARCHAR(190) PRIMARY KEY,
  seeded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS courses (
  id INT PRIMARY KEY AUTO_INCREMENT,
  title VARCHAR(180) NOT NULL,
  description TEXT,
  instructor_id INT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (instructor_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS course_enrollments (
  course_id INT NOT NULL,
  student_id INT NOT NULL,
  enrolled_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (course_id, student_id),
  FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE,
  FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS reports (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT,
  title VARCHAR(180) NOT NULL,
  description TEXT NOT NULL,
  status ENUM('open', 'in_progress', 'resolved') NOT NULL DEFAULT 'open',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS content (
  id INT PRIMARY KEY AUTO_INCREMENT,
  title VARCHAR(180) NOT NULL,
  type VARCHAR(50) NOT NULL DEFAULT 'course',
  description TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

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
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_tests_course FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS questions (
  id INT PRIMARY KEY AUTO_INCREMENT,
  test_id INT NOT NULL,
  question_text TEXT NOT NULL,
  options JSON NOT NULL,
  correct_option INT NOT NULL DEFAULT 0,
  explanation TEXT,
  subject VARCHAR(120),
  FOREIGN KEY (test_id) REFERENCES tests(id) ON DELETE CASCADE
);

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
);
