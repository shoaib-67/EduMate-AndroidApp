# EduMate

EduMate is a Flutter client backed by the Node.js API in `backend/` and a MySQL database.

## Features

EduMate is an admission-preparation and learning platform with separate experiences for students, instructors, and administrators. Its main features include course-based learning, timed practice exams, performance tracking, discussions, bug reporting, and role-specific dashboards.

### Students

- Personalized dashboard with course summaries, learning progress, and quick access to important activities
- Browse available courses, view course details, and access instructor-provided learning materials
- Study using multiple content types, including PDFs, videos, live classes, and exams
- Take timed practice tests, submit answers, and receive performance results
- Review test history and analyze scores to identify areas for improvement
- Create discussion topics and reply to other learners in the community
- Submit bug reports or other issues directly from the application
- Manage personal information, including name, phone number, and institution
- Browse learning packages and compare the available package features

### Instructors

- Instructor dashboard with course totals, student statistics, and exam summaries
- Create, update, and delete instructor-owned courses
- Add, view, and remove course materials such as PDFs, videos, live classes, and exams
- Create practice exams for student assessment
- View enrolled students and review student performance results
- Review bug reports submitted by students and instructors
- Update instructor profile information

### Administrators

- Dashboard with platform-wide totals for users, students, instructors, courses, exams, and bug reports
- View, create, and delete user accounts
- Manage user roles and control access to student, instructor, and administrator features
- Review bug reports, update their statuses, and monitor issue summaries
- Manage courses, course content, and learning packages across the platform
- Update administrator profile information

### Platform

- Registration, login, logout, and persistent user sessions
- Role-based access for students, instructors, and administrators
- Secure authenticated API requests with role-based authorization
- REST API built with Node.js and Express
- MySQL database with automatic table and relationship initialization
- Shared profile management and issue-reporting workflows
- Course content support for PDFs, videos, live classes, and exams
- Responsive Flutter interface for web and Android

## Run the app

Install and start MySQL locally first. The API uses the default local settings unless you create `backend/.env`.

### One-time setup

```powershell
cd backend
npm.cmd install
```

### Terminal 1: API

```powershell
cd backend
npm.cmd start
```

### Terminal 2: Flutter Chrome

From the project root:

```powershell
flutter run -d chrome
```

<<<<<<< HEAD

=======
The API creates the `edumate` database and tables automatically on startup. 
>>>>>>> 581d47f74aebc1a1a96ccc8c55629dc907e69746
Check the database connection at `http://localhost:5000/api/health`.

The Chrome app connects automatically to `http://127.0.0.1:5000`. Android emulators use `http://10.0.2.2:5000`.



##In development
