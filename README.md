<div align="center">

# 🌍 Smart Trip Planner

### Plan, Collaborate, and Manage Your Trips Seamlessly

[![Python](https://img.shields.io/badge/Python-3.11+-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-336791?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)

[![Build Status](https://img.shields.io/github/actions/workflow/status/AdiCoder33/Smart-Trip-Planner/main.yml?style=flat-square&logo=github&label=CI/CD)](https://github.com/AdiCoder33/Smart-Trip-Planner/actions)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](CONTRIBUTING.md)

</div>

---

## ✨ Features

<table>
  <tr>
    <td width="50%">
      
### 📅 Trip Management
- 🎯 **Drag-and-Drop Itinerary** - Reorder your plans effortlessly
- 📍 **Smart Scheduling** - Organize activities by date and time
- 📤 **Calendar Export** - Export to ICS format

### 💰 Expense Tracking
- 💳 **Expense Splitting** - Fair bill division
- 👥 **Per-Member Summaries** - Track who owes what
- 📊 **Real-time Updates** - See expenses as they happen

    </td>
    <td width="50%">
      
### 🗳️ Collaborative Polls
- ✅ **Group Voting** - Make decisions together
- 👤 **Per-User Tracking** - See who voted for what
- 📈 **Live Results** - Real-time vote counting

### 🚀 Advanced Features
- 💬 **Real-time Chat** - WebSocket-powered messaging
- 🔒 **Encrypted Payloads** - Secure communications
- 📴 **Offline-First** - Work without internet
- 🔄 **Auto-Sync** - Background synchronization
- 📧 **Email Invites** - Token-based collaboration

    </td>
  </tr>
</table>

---

## 🏗️ Tech Stack

<div align="center">

### Backend
![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-336791?style=for-the-badge&logo=postgresql&logoColor=white)
![SQLAlchemy](https://img.shields.io/badge/SQLAlchemy-D71F00?style=for-the-badge&logo=sqlalchemy&logoColor=white)

### Frontend
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![JavaScript](https://img.shields.io/badge/JavaScript-F7DF1E?style=for-the-badge&logo=javascript&logoColor=black)
![CSS3](https://img.shields.io/badge/CSS3-1572B6?style=for-the-badge&logo=css3&logoColor=white)

### Infrastructure & DevOps
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=github-actions&logoColor=white)
![Render](https://img.shields.io/badge/Render-46E3B7?style=for-the-badge&logo=render&logoColor=white)
![WebSocket](https://img.shields.io/badge/WebSocket-010101?style=for-the-badge&logo=socketdotio&logoColor=white)

</div>

---

## 🚀 Quick Start

### 📋 Prerequisites

- 🐳 Docker & Docker Compose
- 📱 Flutter SDK (3.0+)
- 🐍 Python 3.11+ (for local testing)

### 🔧 Backend Setup

```bash
# Navigate to backend directory
cd backend

# Copy environment variables
cp .env.example .env

# Start services with Docker
docker compose up --build
```

> 🌐 **API Documentation**: Visit `http://localhost:8000/api/docs` after startup

### 📱 Frontend Setup

```bash
# Navigate to frontend directory
cd frontend

# Install dependencies
flutter pub get

# Run the app
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

#### 📍 Platform-Specific URLs

| Platform | Base URL |
|----------|----------|
| 🍎 **iOS Simulator** | `http://localhost:8000` |
| 🤖 **Android Emulator** | `http://10.0.2.2:8000` |
| 💻 **Physical Device** | `http://<your-local-ip>:8000` |

> ⚠️ **Android Users**: Add `10.0.2.2` to `ALLOWED_HOSTS` in `backend/. env`

---

## 🧪 Testing

### 🐍 Backend Tests

```bash
cd backend
pip install -e .[dev]
python -m pytest
```

**For local testing** (outside Docker):
```bash
DATABASE_URL=postgres://smart_trip_planner:smart_trip_planner@localhost: 5432/smart_trip_planner python -m pytest
```

### 📱 Frontend Tests

```bash
cd frontend
flutter test
```

---

## 🎨 Code Quality

### Backend Linting

```bash
cd backend

# Check code style
ruff check .

# Format code
black . 
```

### Frontend Linting

```bash
cd frontend

# Analyze code
flutter analyze
```

---

## 💬 WebSocket Chat

Connect to real-time chat using: 

```
ws://localhost:8000/ws/trips/<trip_id>/chat/? token=<JWT_ACCESS>
```

**Features:**
- 🔐 JWT-based authentication
- 🔒 Encrypted message payloads
- ⚡ Real-time message delivery
- 👥 Multi-user support

---

## 📧 Collaboration

### Sample Invite Email

```
Subject: 🌍 You're invited to a trip!

You've been invited to collaborate on a trip. 

Trip:  Paris Weekend ✈️
Role: editor 📝
Token: <paste-this-token>

Use this token in the app to accept the invite. 

Happy planning! 🎉
```

**Invite Flow:**
1. 📤 Organizer sends email invite
2. 🔑 Recipient receives unique token
3. 📱 Token entered in app
4. ✅ Collaboration activated

---

## 🔄 CI/CD Pipeline

### GitHub Actions Workflows

#### 🔧 Backend Pipeline
- ✅ Linting (Ruff + Black)
- 🧪 Test suite execution
- 🐳 Docker image build
- 🚀 Render deployment trigger

#### 📱 Frontend Pipeline
- ✅ Flutter analyze
- 🧪 Widget/unit tests
- 📦 Release APK build

### Required Secrets

Add these to your GitHub repository settings:

| Secret Name | Description |
|-------------|-------------|
| `RENDER_DEPLOY_HOOK` | Render deploy hook URL for backend auto-deployment |

---

## 📚 Environment Variables

Create a `.env` file in the `backend` directory:

```env
# Database
DATABASE_URL=postgres://smart_trip_planner:smart_trip_planner@db:5432/smart_trip_planner

# Security
SECRET_KEY=your-secret-key-here
ALLOWED_HOSTS=localhost,127.0.0.1,10.0.2.2

# Email (optional)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
```

---

## 📖 API Documentation

Once the backend is running, explore the interactive API docs:

- 📘 **Swagger UI**:  `http://localhost:8000/api/docs`
- 📗 **ReDoc**: `http://localhost:8000/api/redoc`

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. 🍴 Fork the repository
2. 🌿 Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. ✅ Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. 📤 Push to the branch (`git push origin feature/AmazingFeature`)
5. 🔀 Open a Pull Request

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Built with ❤️ using FastAPI and Flutter
- Inspired by modern collaborative travel planning needs
- Special thanks to all contributors

---

<div align="center">

### ⭐ Star this repo if you find it helpful! 

Made with ❤️ by [AdiCoder33](https://github.com/AdiCoder33)

</div>
