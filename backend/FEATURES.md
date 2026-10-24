# EduMate backend behavior

## Accounts

Signup creates a student account and signs the user in immediately. Login uses the account email and password. No email sender or verification link is required. On its next start, the backend makes existing unverified accounts usable and removes the old email-verification data.

## Exams

Teachers can mix MCQs and fill-in-the-blank questions. Each blank question has one text answer; comparison ignores letter case, leading/trailing whitespace and repeated whitespace. Both types use the exam's marks per question and penalty for an incorrect answered question. Blank/unanswered questions get zero marks without a penalty.

Leaving an active exam (tab/window focus loss, app switch, Home, screen lock, or back navigation) locks answers and submits them. Results appear when the app is visible again. A network failure shows a locked retry screen. Retries reuse a submission ID and cannot create duplicate attempts. This is a classroom demo safeguard: browsers and phones cannot guarantee a callback or network delivery when a process is forcibly killed or a device loses power. System interruptions such as a phone call can also end an exam.

## Integration check

Run `node --test test/*.test.js` from this folder. The integration check uses a temporary database and does not email real recipients or alter the demo database.
