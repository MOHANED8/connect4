# 3D Connect‑Four in Flutter

![Demo](docs/screenshots/intro.gif)

A fully cross‑platform, feature-rich 3D rendition of the classic Connect Four game, built end-to-end in Flutter. Play locally, challenge smart AI opponents, or battle friends online in real-time.

---

## 🚀 Features

- **Multi‑Mode Gameplay**  
  - Local hot-seat duels (two players on one device)  
  - Bot battles with 3 difficulty levels (Beginner → Professional using Minimax)  
  - Online rooms: create or join games with unique codes, live chat, & spectate  

- **Rich, Animated UX**  
  - Animated intro screen (logo bounce, particle effects, wave backgrounds)  
  - Piece-drop animations, win celebrations with confetti, smooth transitions  
  - Responsive design adapting across mobile (iOS/Android) and web  

- **Real-Time Networking & Persistence**  
  - Sub-100 ms sync powered by Firebase Realtime Database & WebSockets  
  - Game history, rematch, and player stats saved locally via SharedPreferences  

- **Smart AI Opponents**  
  - Randomized moves at beginner level  
  - Minimax-based professional AI for challenging matches  

- **Immersive Audio**  
  - Background music, drop-piece sound effects, timer ticks, victory jingles  

- **Robust & Secure**  
  - Input validation, room-access control, and graceful error handling  
  - Optimized memory and board-state management for smooth performance  

---

## 📥 Getting Started

### Prerequisites

- Flutter ≥ 3.0.0  
- Dart ≥ 2.17.0  
- Firebase account (for Realtime Database usage)  

### Installation

1. **Clone the repository**  
   ```bash
   git clone https://github.com/MOHANED8/YourRepo.git
   cd YourRepo
