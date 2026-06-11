# SmartSpend — Intelligent Finance Tracker

Cross-platform personal finance app built with **Flutter** and **Django REST Framework**.

## Features

- Email/password auth + Google Sign-In (server-side token verification)
- Session restore, biometric unlock, secure logout with JWT blacklist
- Account deletion (password or `DELETE` confirmation for OAuth users)
- Offline sync for transactions and categories (auto-sync on reconnect)
- Dashboard charts: income vs expense bar chart + spending pie chart (`fl_chart`)
- English/French UI with in-app language picker
- Recurring transactions (create, edit, delete) + backend cron command
- Budget alerts, local notifications, CSV/PDF export
- AI assistant with persisted chat history (local rules + Hugging Face fallback)

## Tech Stack

| Layer | Stack |
|-------|-------|
| Mobile/Web | Flutter, Provider, Hive, fl_chart, connectivity_plus |
| Backend | Django 5, DRF, SimpleJWT (+ blacklist) |
| Database | SQLite (local dev) or MySQL (production) |
| CI | GitHub Actions |

## Prerequisites

- Flutter SDK 3.x
- Python 3.10+
- Git

## Backend setup

```bash
cd backend
python -m venv venv

# Windows
.\venv\Scripts\activate

# macOS/Linux
source venv/bin/activate

pip install -r requirements.txt
copy .env.example .env   # Windows
# cp .env.example .env   # macOS/Linux

python manage.py migrate
python manage.py runserver
```

API runs at **http://127.0.0.1:8000/**

### Local database (SQLite — recommended for dev)

In `backend/.env`:

```env
USE_SQLITE=True
```

Creates `backend/db.sqlite3`. No MySQL install required.

For production, set `USE_SQLITE=False` and configure `DB_*` variables for MySQL.

## Frontend setup

```bash
cd frontend_new
flutter pub get
```

### Run on Chrome (web)

```bash
flutter run -d chrome --web-port=5000
```

Use a fixed port so Google OAuth origins match Google Cloud settings.

### Run on Android emulator

```bash
flutter run
```

API base URL is configured in `lib/config/api_config.dart`:
- Web / iOS / desktop → `http://localhost:8000`
- Android emulator → `http://10.0.2.2:8000`

### Run on Windows desktop

Enable **Developer Mode** in Windows Settings (required for Flutter plugin symlinks), then:

```bash
flutter run -d windows
```

## Google Sign-In (web)

1. Create an OAuth **Web application** client in [Google Cloud Console](https://console.cloud.google.com/apis/credentials).
2. Add **Authorized JavaScript origins**:
   - `http://localhost:5000`
   - `http://127.0.0.1:5000`
3. Add your Gmail under **OAuth consent screen → Test users**.
4. Set the Web Client ID in:
   - `frontend_new/web/index.html` (`google-signin-client_id` meta tag)
   - `backend/.env` as `GOOGLE_CLIENT_ID`
5. Run Flutter with `--web-port=5000`.

For quick local testing without Google setup, use **email/password register + login**.

## Recurring transactions (cron)

```bash
cd backend
python manage.py process_recurring_transactions
```

## Tests

```bash
# Backend
cd backend
python manage.py test

# Flutter
cd frontend_new
flutter test
```

## Environment variables

See `backend/.env.example`. Key options:

| Variable | Role |
|----------|------|
| `SECRET_KEY` | Django signing key |
| `USE_SQLITE` | `True` for local SQLite, `False` for MySQL |
| `GOOGLE_CLIENT_ID` | Google ID token verification |
| `HUGGINGFACE_API_KEY` | Hugging Face AI fallback |
| `DB_*` | MySQL settings (when `USE_SQLITE=False`) |

**Never commit `backend/.env` or `backend/db.sqlite3`.**

## License

MIT License
