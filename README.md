# ⚡ XPulse

> Synchronized Biometrics. Collective Progression. Pure Dopamine.

XPulse is a gamified, cross-platform fitness and lifestyle social network that merges **Clash Royale-style retention mechanics** with a stunning **time-adaptive pixel-art interface**.

Instead of forcing users into toxic, hyper-competitive leaderboards based on raw volume, XPulse normalizes biometric data against **personal baselines**. Whether you are a marathon runner or an engineer optimizing your sleep and deep work, everyone contributes equally to their **Dojo (Clan)** by syncing their smartwatches.

---

# 🎮 Core Gameplay Loop

1. **Sync:** Wear your watch (Apple Watch, Garmin, Whoop, etc.). XPulse silently ingests your biometrics in the background.
2. **Quest:** Complete dynamic daily "Side Quests" tailored to your personal health baseline (e.g., *Log 8h Sleep*, *Hit 20 mins in HR Zone 2*).
3. **Earn:** Filling your daily XP bar earns you **Trophies** to climb through competitive Arenas and unlocks **Gacha Drops (Chests)**.
4. **Pool:** Contribute your daily XP to your Dojo's collective pool to defeat weekly "Boss Fights" programmed by real-life Gym Trainers.

---

# 🎨 Visual Identity & Aesthetic

XPulse features a hybrid **16-Bit Cyberpunk / Synthwave** pixel-art interface built entirely for true dark mode (OLED Black). To prevent the game from feeling too dark or gloomy, the UI implements a **Dynamic Time-of-Day Engine**:

- **🌅 Morning (06:00 - 12:00) — _The Grid Bootup_:**  
  Soft vaporwave sunrises using warm oranges, glowing pinks, and bright cyans to energize your morning.

- **☀️ Afternoon (12:00 - 18:00) — _Active State_:**  
  Crisp electric blues and sharp whites optimized for high-visibility during workouts.

- **🌃 Night (18:00 - 06:00) — _Neo-Tokyo Dark_:**  
  Moody neon magentas and deep purples that reduce eye strain during evening wind-downs and sleep tracking.

> **Design Constraint:**  
> To maintain an ultra-clean, "cool shit" tech aesthetic, the primary XPulse logo is kept to highly reduced dimensions at the top of the viewport with no taglines. All decorative assets (chests, progress bars, avatars) use pixel art, while critical data text uses high-contrast, modern sans-serif typography for maximum readability across all age groups.

---

# 🏗️ Architecture & Data Pipeline

XPulse avoids individual cloud-to-cloud hardware integrations by utilizing a centralized wearable middleware data pipeline.

```text
[Apple Watch / Garmin / Whoop]
            │
            ▼
 (Native Bluetooth Sync)
            │
            ▼
[Apple HealthKit / Android Health Connect]
            │
            ▼
   (XPulse Mobile App SDK)
            │
            ▼
[Unified Wearable API / Middleware]
            │
            ▼
   (Secure HTTPS Post Payload)
            │
            ▼
[XPulse Backend Ingestion Server]
            │
            ▼
[Baseline Normalization Engine]
            │
            ▼
[Dojo Leaderboards & Quest Progression]
```

## ⚖️ Data Normalization (The Fairness Engine)

To allow a 20-year-old athlete and a 60-year-old casual walker to compete fairly in the same Dojo, XPulse translates raw absolute values into **relative baseline percentages**:

\[
\text{Quest Progress (\%)} =
\left(
\frac{\text{Current Daily Value}}
{\text{User's 30-Day Moving Average}}
\right)
\times 100
\]

Hitting **110%** of your *own* baseline triggers a **Critical Strike**, injecting bonus XP into the Dojo's weekly objective.

---

# 🧑‍🏫 Dojo Master Console (Trainer Integration)

Real-life gym trainers and coaches act as the **Dojo Masters** or **Senseis** via a dedicated backend console.

Trainers can:

- **Deploy Bounties:**  
  Manually issue squad-wide physical challenges that yield double XP.

- **Activate Stat Buffs:**  
  If the server detects low collective recovery metrics (e.g., poor HRV or low sleep across the squad), trainers can deploy a *Recovery Aura* that multiplies sleep XP and limits high-intensity workout rewards.

- **Program Boss Fights:**  
  Set massive, collective weekly calorie or movement walls that the Dojo must break down together before Sunday at midnight to unlock premium loot.

---

# 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Frontend** | Flutter / React Native (Expo) |
| **State Management** | Riverpod / Redux |
| **Wearable Pipeline** | HealthKit, Health Connect, Terra API, Rook |
| **Backend** | Node.js / Python (FastAPI) |
| **AI Infrastructure** | MCP (Model Context Protocol) |
| **Database** | PostgreSQL + Redis |

---

# 🚀 Getting Started (Development)

## 1. Prerequisites

- Xcode (for iOS / HealthKit simulation)
- Android Studio (for Health Connect testing)
- Node.js v20+

---

## 2. Installation

```bash
# Clone the repository
git clone https://github.com/your-username/xpulse.git

# Navigate into the project
cd xpulse

# Install mobile dependencies
cd apps/mobile
npm install

# Start development server
npm run dev
```

---

## 3. Environment Configuration

Create a `.env` file in the root directory:

```env
MIDDLEWARE_API_KEY=your_wearable_api_key
BACKEND_URL=https://api.xpulse.local
ENCRYPTION_SECRET=your_phi_secure_key
```

---

# 🔒 Security & Privacy (PHI)

Biometric data is highly sensitive **Personal Health Information (PHI)**. XPulse implements strict security protocols:

- **OAuth 2.0 Explicit Consent**  
  Users explicitly choose which metrics to share during onboarding.

- **Immediate Anonymization**  
  Raw biometric payloads are stripped of personal identifiers at the ingestion gateway and mapped to encrypted Participant IDs.

- **At-Rest Encryption**  
  All database entries tracking health metrics are encrypted using AES-256.

---

# 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

# 🌌 Vision

XPulse is not trying to become another calorie tracker.

It is building a **living social fitness RPG** where biometrics become gameplay, consistency becomes status, and collective progression matters more than individual vanity metrics.

Instead of endless scrolling, XPulse transforms health into:
- **Daily quests**
- **Cooperative progression**
- **Behavioral reinforcement**
- **Competitive camaraderie**
- **Meaningful long-term retention**

The goal is simple:

> Turn self-improvement into the most addictive multiplayer game ever built.
