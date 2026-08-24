# DevSpace Application Architecture & Core Logic Summary

This document details the core logic and workflow implementations across every major section of the **DevSpace** Flutter application.

---

## 1. 🎯 Practice Mode & Gamification (`PracticeProvider` & `PracticeLevelData`)

* **Section & Difficulty Levels**:
  * Divided into 4 progressive sections: **Noob (1)**, **Easy (2)**, **Medium (3)**, and **Hard (4)**.
  * Completing Question 20 of a level unlocks the next difficulty section.
* **Tech Stack Filtering**:
  * Filters questions dynamically by technology area: **All Stacks**, **Frontend**, **Backend**, **Mobile**, **DevOps & Tools**, and **DSA & Logic**.
* **Scoring & Answer Evaluation**:
  * **Right Answer**: Awards **+5 Aura Points**, marks the question as completed, unlocks the next question in sequence, highlights the option green, and reveals the explanation.
  * **Wrong Answer**: Awards **+0 Aura Points**, highlights **only** the selected option in red, **does not reveal the correct answer**, shows a `+0 Aura Points` notice, and allows the user to tap **"Try Again"**.
* **Persistence & Sync**:
  * Stores completed question IDs locally via `SharedPreferences`.
  * Syncs newly earned Aura points to the user's Supabase backend profile.

---

## 2. 🔐 Authentication & Profile (`AuthProvider` & `SupabaseService`)

* **Session Management**:
  * Handles student authentication via Supabase Auth.
  * Bootstraps local profile state on startup and caches credentials for offline access.
* **Student Identity**:
  * Manages user metadata including display name, username, college name, tech stack tags, and total Aura score.

---

## 3. 🏆 Monthly Aura & Arena Reset (`MonthlyAuraService`)

* **Season Tracking**:
  * Tracks monthly competition seasons (e.g., *"August 2026 Season"*).
* **Automated Monthly Reset**:
  * Compares the current month key (`YYYY-MM`) against `SharedPreferences`.
  * On the first launch of a new calendar month, automatically executes `resetAllUsersMonthlyAura()` in Supabase to reset monthly Aura rankings while preserving lifetime stats.

---

## 4. 📰 Feed & Community Doubts (`PostProvider` & `FeedScreen`)

* **Posting & Doubts**:
  * Allows student builders to share project updates and ask technical doubts.
* **Interactions**:
  * Supports upvotes/likes, comments, media attachments, and tech tag filters.
* **Feed Ranking**:
  * Sorts feed posts by timestamp (Recent) or community engagement (Trending).

---

## 5. 🥇 Leaderboards & Arena (`LeaderboardScreen`)

* **Ranking Logic**:
  * Ranks students based on total accumulated Aura points.
  * Displays tier badges (e.g., *Bronze, Silver, Gold, Diamond, Legend*) based on ranking thresholds.
* **Filters**:
  * View overall global rankings, monthly season rankings, or college-specific leaderboards.
