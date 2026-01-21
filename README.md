# 💰 SmartSpend - Intelligent Finance Tracker

SmartSpend is a modern, cross-platform (Mobile & Web) application designed to help users track expenses, manage budgets, and analyze financial habits. Built with **Flutter** for a beautiful UI and **Django** for a robust, secure backend.

![SmartSpend Banner](https://via.placeholder.com/1200x400.png?text=SmartSpend+Dashboard+Preview)
*(Note: Replace this link with an actual screenshot of your app later)*

## ✨ Features

- **📱 Cross-Platform:** Works seamlessly on Android, iOS, and Web.
- **🔐 Secure Authentication:** Email/Password login & **Google Sign-In**.
- **💸 Transaction Management:** Track Income and Expenses efficiently.
- **🔄 Recurring Transactions:** Set up automatic monthly bills or subscriptions.
- **📊 Interactive Dashboard:** Visual breakdown of spending by category.
- **📅 Budgeting:** Set monthly limits and get alerts.
- **📂 Export Data:** Generate PDF and CSV reports of your financial history.
- **🎨 Modern UI:** A sleek Purple & Gold theme with Dark Mode support.

## 🛠️ Tech Stack

### Frontend (Mobile & Web)
- **Framework:** Flutter (Dart)
- **State Management:** Provider
- **Networking:** HTTP & Dio
- **Auth:** Google Sign-In
- **Charts:** Fl_Chart

### Backend (API)
- **Framework:** Django (Python)
- **API:** Django REST Framework (DRF)
- **Database:** SQLite (Dev) / PostgreSQL (Prod)
- **Auth:** JWT (JSON Web Tokens) & OAuth2
- **Documentation:** Swagger / Redoc

---

## 🚀 Getting Started

Follow these instructions to set up the project locally.

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) installed.
- [Python 3.10+](https://www.python.org/downloads/) installed.
- Git.

### 1. Backend Setup (Django)

Navigate to the backend folder:
```bash
cd Backend

# Windows
python -m venv venv
.\venv\Scripts\activate

# Mac/Linux
python3 -m venv venv
source venv/bin/activate

pip install -r requirements.txt

python manage.py migrate
python manage.py runserver

The API will run at http://127.0.0.1:8000/

2. Frontend Setup (Flutter)
Open a new terminal and navigate to the frontend folder:

Bash

cd frontend_new
Install dependencies:

Bash

flutter pub get
Configure API URL:
Check lib/core/config/api_config.dart and ensure baseUrl matches your environment:

Android Emulator: http://10.0.2.2:8000
Web/iOS: http://127.0.0.1:8000 or http://localhost:8000
Run the app:

Bash

# For Android
flutter run

# For Web (Chrome)
flutter run -d chrome --web-port=5000
🔑 Environment Variables
To run the backend securely, create a .env file in the Backend/ folder:

ini

SECRET_KEY=your_django_secret_key
DEBUG=True
ALLOWED_HOSTS=127.0.0.1,localhost,10.0.2.2
HUGGINGFACE_API_KEY=your_hugging_face_token
📸 Screenshots
Dashboard	Transactions	Profile
Dashboard	Transactions	Profile
🤝 Contributing
Contributions are welcome! Please fork the repository and submit a pull request.

📄 License
This project is open-source and available under the MIT License.

text


---

### Part 2: Preparing `.gitignore` (Crucial)

Before you upload, you **MUST** ensure you aren't uploading temporary files, virtual environments, or secrets.

1.  **Root `.gitignore`**: Create a `.gitignore` file in your main folder.
2.  **Paste this content**:

```gitignore
# --- Django ---
Backend/venv/
Backend/__pycache__/
Backend/*.sqlite3
Backend/.env
Backend/media/
*.pyc

# --- Flutter ---
frontend_new/build/
frontend_new/.dart_tool/
frontend_new/.flutter-plugins
frontend_new/.flutter-plugins-dependencies
frontend_new/.idea/
frontend_new/android/.gradle
frontend_new/ios/.symlinks/
frontend_new/ios/Pods/

# --- IDEs ---
.vscode/
.idea/
*.DS_Store
