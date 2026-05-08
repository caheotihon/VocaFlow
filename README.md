# LingoPro 🎓

> **Premium English Vocabulary Learning App**  
> Flutter + Node.js + Express + MongoDB

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)
![Node.js](https://img.shields.io/badge/Node.js-20.x-green?logo=node.js)
![MongoDB](https://img.shields.io/badge/MongoDB-Local-brightgreen?logo=mongodb)

---

## 📁 Project Structure

```
VocaFlow/
├── vocaflow-api/          ← Node.js + Express Backend
│   ├── src/
│   │   ├── config/        ← DB config
│   │   ├── controllers/   ← auth, word, learn, favorite, stats
│   │   ├── middlewares/   ← JWT auth middleware
│   │   ├── models/        ← User, Word, Progress, Session, Favorite
│   │   ├── routes/        ← Express route files
│   │   ├── seed/          ← 60-word vocabulary seed data
│   │   └── utils/         ← helpers (JWT, XP calc)
│   ├── .env
│   └── package.json
│
└── vocaflow_flutter/      ← Flutter Mobile Frontend
    └── lib/
        ├── core/constants/    ← AppColors, AppSpacing, AppTextStyles
        ├── models/            ← WordModel, UserModel, SessionModel
        ├── providers/         ← Auth, Word, Learn, Stats, Favorite
        ├── services/          ← ApiService (Dio)
        └── screens/
            ├── splash_screen.dart
            ├── login_screen.dart
            ├── main_shell.dart        ← bottom nav
            ├── home_screen.dart
            ├── learn_screen.dart      ← choose source + level
            ├── select_topic_screen.dart
            ├── choose_mode_screen.dart
            ├── result_screen.dart
            ├── statistics_screen.dart
            ├── favorites_screen.dart
            ├── profile_screen.dart
            └── practice/
                ├── flashcard_screen.dart
                ├── typing_screen.dart
                ├── listening_screen.dart
                ├── reverse_recall_screen.dart
                ├── fill_blank_screen.dart
                └── mixed_challenge_screen.dart
```

---

## 🚀 Getting Started

### Prerequisites

| Tool | Version |
|------|---------|
| Node.js | 18+ |
| MongoDB | Running locally on port 27017 |
| Flutter | 3.4+ |
| Dart | 3.4+ |

---

## 🔧 Backend Setup

### 1. Install dependencies
```bash
cd vocaflow-api
npm install
```

### 2. Configure environment
Edit `.env` (already created):
```env
PORT=3000
MONGODB_URI=mongodb://127.0.0.1:27017/lingopro
JWT_SECRET=lingopro_super_secret_jwt_key_2024
JWT_EXPIRES_IN=7d
```

### 3. Seed the database
Make sure MongoDB is running, then:
```bash
npm run seed
```
This imports **60 vocabulary words** across:
- Oxford 5000 · Oxford 3000 · Cambridge B1/B2 · IELTS Core · TOEIC Core
- Topics: Daily Life · Travel · Business · Food · Technology · Education
- Levels: A1 · A2 · B1 · B2 · C1

### 4. Start the server
```bash
npm run dev       # development (nodemon)
npm start         # production
```

Server runs at: **http://localhost:3000**  
Health check: **http://localhost:3000/health**

---

## 📱 Flutter Setup

### 1. Install packages
```bash
cd vocaflow_flutter
flutter pub get
```

### 2. Configure API URL

Edit `lib/services/api_service.dart`:

```dart
// Android Emulator (default):
static const String _baseUrl = 'http://10.0.2.2:3000/api';

// Physical device — use your machine's local IP:
static const String _baseUrl = 'http://192.168.1.x:3000/api';

// iOS Simulator:
static const String _baseUrl = 'http://localhost:3000/api';
```

### 3. Run the app
```bash
flutter run
```

---

## 🌐 API Endpoints

### Auth
| Method | Route | Description |
|--------|-------|-------------|
| POST | `/api/auth/register` | Register new user |
| POST | `/api/auth/login` | Login with email + password |
| POST | `/api/auth/google` | Google OAuth (idToken) |
| GET  | `/api/auth/me` | Get current user |
| PUT  | `/api/auth/profile` | Update profile |

### Words
| Method | Route | Description |
|--------|-------|-------------|
| GET | `/api/words` | Paginated word list |
| GET | `/api/words/random` | Random word |
| GET | `/api/words/search?q=` | Search words |
| GET | `/api/words/:id` | Word by ID |
| GET | `/api/words/source/:source` | Filter by source |
| GET | `/api/words/topic/:topic` | Filter by topic |
| GET | `/api/words/level/:level` | Filter by level |
| GET | `/api/words/sources/list` | All sources with progress |
| GET | `/api/words/topics/list` | All topics with progress |

### Learning
| Method | Route | Description |
|--------|-------|-------------|
| POST | `/api/learn/start` | Start a session |
| POST | `/api/learn/result` | Submit word answer |
| POST | `/api/learn/complete` | Complete session + earn XP |
| GET  | `/api/learn/progress` | User progress summary |
| GET  | `/api/learn/review-today` | Words due for review |

### Favorites & Stats
| Method | Route | Description |
|--------|-------|-------------|
| GET    | `/api/favorite` | Get all favorites |
| POST   | `/api/favorite/:wordId` | Add favorite |
| DELETE | `/api/favorite/:wordId` | Remove favorite |
| GET    | `/api/stats/dashboard` | Full stats dashboard |

---

## 🧠 Learning Logic

### Spaced Repetition (SM-2 inspired)
Each word tracks:
- `times_seen` / `times_correct` / `times_wrong`
- `ease_factor` — adjusts review interval dynamically
- `interval_days` — days until next review
- `next_review` — scheduled review date
- `status` — `new` → `learning` → `reviewing` → `mastered`

### XP System
- **+10 XP** per correct answer
- **+50 XP bonus** if session accuracy ≥ 90%

### Streak
- Increments daily when user logs in or completes a session
- Resets to 1 if a day is skipped

---

## 🎨 Design System

| Token | Value |
|-------|-------|
| Primary | `#4F46E5` (Indigo) |
| Secondary | `#7C3AED` (Violet) |
| Background | `#F5F5FF` (Light Lavender) |
| Success | `#10B981` (Emerald) |
| Error | `#EF4444` (Red) |
| Font | Inter (via google_fonts) |

---

## 📚 Practice Modes

| Mode | Description |
|------|-------------|
| 🃏 Flashcards | 3D flip card — reveal meaning, mark know/don't know |
| ⌨️ Typing | Type the word from its definition |
| 🎧 Listening | Reveal the word, select its meaning |
| 🔄 Reverse Recall | See meaning, choose the word from 4 options |
| ✏️ Fill in Blank | Complete the example sentence |
| 🔀 Mixed Challenge | Random mode per word for deep learning |

---

## ✅ Quick Start Checklist

```bash
# Terminal 1 — Start MongoDB
mongod

# Terminal 2 — Backend
cd vocaflow-api
npm install
npm run seed     # one-time only
npm run dev

# Terminal 3 — Flutter
cd vocaflow_flutter
flutter pub get
flutter run
```
