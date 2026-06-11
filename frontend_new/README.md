# 💰 SmartSpend - Intelligent Finance Tracker

SmartSpend is a cross-platform personal finance app built with **Flutter** and **Django REST Framework**.

## ✨ Features

- Email/password + Google Sign-In with server-side token verification
- Session restore, biometric unlock, secure logout with token blacklist
- Account deletion (password or DELETE confirmation for OAuth users)
- Offline transaction queue with automatic sync on reconnect
- Offline category queue (create/update/delete) synced on reconnect
- Dashboard charts (income vs expense bar chart, spending pie chart via fl_chart)
- English/French localization with in-app language picker
- Recurring transactions: create, edit, delete + backend processing command
- Budget alerts, local notifications, CSV/PDF export
- AI assistant with persisted chat history, local rules + Hugging Face fallback

## 🛠️ Tech Stack

| Layer | Stack |
|-------|-------|
| Mobile/Web | Flutter, Provider, Hive, fl_chart, connectivity_plus, logger |
| Backend | Django 5, DRF, SimpleJWT (+ blacklist), MySQL (SQLite for tests) |
| CI | GitHub Actions (backend tests + Flutter analyze/test) |

## 🚀 Getting Started

### Backend

```bash
cd backend
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
python manage.py migrate
python manage.py runserver
```

### Frontend

```bash
cd frontend_new
flutter pub get
flutter run
```

### Recurring transactions (daily cron)

```bash
python manage.py process_recurring_transactions
```

### Tests

```bash
cd backend && python manage.py test
cd frontend_new && flutter test
```

## 🔑 Environment Variables

See `backend/.env.example` for all options. Key variables:

| Variable | Role |
|----------|------|
| `SECRET_KEY` | Django cryptographic signing |
| `GOOGLE_CLIENT_ID` | Validates Google ID tokens (required in production) |
| `HUGGINGFACE_API_KEY` | Enables Hugging Face AI fallback |
| `DB_*` | MySQL connection settings |

## 📄 License

MIT License
