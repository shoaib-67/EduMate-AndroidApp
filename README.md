# EduMate

EduMate is a Flutter client backed by the Node.js API in `backend/` and a MySQL database.

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

The API creates the `edumate` database and tables automatically on startup. It also seeds these demo accounts:

- Student email: `student@edumate.com`
- Teacher email: `teacher@edumate.com`
- Admin emails: `demo@edumate.com`, `admin@edumate.com`
- Password: `demo123`

Check the database connection at `http://localhost:5000/api/health`.

The Chrome app connects automatically to `http://127.0.0.1:5000`. Android emulators use `http://10.0.2.2:5000`.


