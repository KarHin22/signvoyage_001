# 👋 SignVoyage 

**SignVoyage** is a cross-platform mobile application designed to bridge communication gaps and promote inclusivity through sign language integration. Developed as a major group project for the **2026A PROG2033 Mobile Application Development** course.

This application is built with a direct focus on **Sustainable Development Goal 10 (SDG 10) - Reduced Inequalities**, aiming to empower the deaf and hard-of-hearing community and make global travel and daily interactions more accessible to everyone.

---

## 🌟 Key Features

* 📖 **Travel Dictionary (Offline Support):** A deeply integrated offline dictionary system featuring real-time search, category filtering (Basics, Transport, Needs, Support), and multi-video playback demonstrations of common functional sign language phases.
* 🗣️ **Voice Chat & Communication:** Integration with Speech-to-Text (`speech_to_text`) allowing fluid communication bridges between verbal and visual individuals.
* 📹 **Sign Translator:** (In-development) Real-time parsing or demonstrations of sign languages.
* 🚑 **Emergency Module:** Quick-access tools specifically designed for user safety and barrier-free functional communication.

## 🛠️ Tech Stack & Architecture

This project is built using modern Flutter development standards:
* **Framework:** Flutter (`^3.11.1`)
* **State Management:** Riverpod (`flutter_riverpod`)
* **Local Storage & DB:** SQLite (`sqflite`, `sqflite_common_ffi` for desktop testing support)
* **Media Rendering:** Video Player (`video_player` with dynamic modal scaling)

## 📁 Project Structure

The codebase is highly modular and strictly follows feature-first organization rules:

```text
lib/
├── features/
│   ├── dictionary/      # Offline SQLite vocab DB, Search & Video Modals
│   ├── emergency/       # Emergency contact and functional features
│   ├── sign_translator/ # Translator UI & logic
│   └── voice_chat/      # Speech-to-text integration 
├── main.dart            # Application Entry Point
```

*Static assets like the database seed videos (`.mp4` files) are housed in `assets/videos/` and are tightly coupled at runtime.*

## 🚀 Getting Started

If you are cloning this repository to run it locally, please follow these steps:

### Prerequisites
* Flutter SDK (3.11+) installed on your machine.
* Android Studio / Xcode configured for emulation.
* (Optional) **Desktop Support:** Developer Mode enabled for Windows environments (Required to test sqflite locally).

### Installation
1. Clone the repository and navigate to the project directory:
   ```bash
   git clone <repository_url>
   cd signvoyage_001
   ```
2. Fetch the latest packages and dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application!
   ```bash
   flutter run
   ```

*Note: For the Dictionary module to work, ensure the demonstration `.mp4` files are actively populated inside your `assets/videos/` directory path.*

---

## 👥 Contributors

This mobile application is actively developed by:
* **Ivan**
* **Joel** 
* **Kar Hin** 
* **Sei Jie**

> *"Bridging the world, one sign at a time."*
