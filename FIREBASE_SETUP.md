# Firebase Setup Guide for DevSpace 🔥

Follow these steps exactly — takes about 20 minutes.

---

## Step 1 — Create a Firebase Project

1. Go to https://console.firebase.google.com
2. Click **Add project** → name it `devspace`
3. Disable Google Analytics (optional) → **Create project**

---

## Step 2 — Add Android App

1. In Firebase Console → click the **Android icon**
2. Android package name: `com.yourname.devspace`
   - Must match `applicationId` in `android/app/build.gradle`
3. Download `google-services.json`
4. Place it in: `android/app/google-services.json`

### Update android/build.gradle (project level)
```gradle
buildscript {
  dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
  }
}
```

### Update android/app/build.gradle (app level)
```gradle
// At the top:
apply plugin: 'com.google.gms.google-services'

android {
  defaultConfig {
    applicationId "com.yourname.devspace"
    minSdkVersion 21       // Firebase requires min 21
    targetSdkVersion 34
  }
}
```

---

## Step 3 — Add iOS App

1. In Firebase Console → click the **iOS icon**
2. iOS bundle ID: `com.yourname.devspace`
3. Download `GoogleService-Info.plist`
4. In Xcode: drag it into `Runner/` folder (check "Copy if needed")

---

## Step 4 — Enable Authentication

1. Firebase Console → **Authentication** → **Get started**
2. **Sign-in method** tab → enable **Google**
3. Add your support email
4. Save

### Add SHA-1 fingerprint (Android Google Sign-In)
```bash
cd android
./gradlew signingReport
```
Copy the SHA-1 from `debug` variant → paste in Firebase Console → Project Settings → Your Android App → Add fingerprint

---

## Step 5 — Create Firestore Database

1. Firebase Console → **Firestore Database** → **Create database**
2. Choose **production mode** (we'll set rules next)
3. Pick a region close to India (e.g. `asia-south1`)

### Firestore Security Rules
Go to Firestore → **Rules** tab → paste:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users: anyone authenticated can read, only owner can write
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;

      // Sub-collections
      match /following/{fid}  { allow read, write: if request.auth != null; }
      match /followers/{fid}  { allow read, write: if request.auth != null; }
      match /bookmarks/{bid}  { allow read, write: if request.auth.uid == userId; }
    }

    // Posts: anyone authenticated can read, owner can create/delete
    match /posts/{postId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.userId;

      match /likes/{uid}    { allow read, write: if request.auth != null; }
      match /comments/{cid} { allow read, write: if request.auth != null; }
    }

    // Notifications: only recipient can read
    match /notifications/{nid} {
      allow read: if request.auth.uid == resource.data.toUid;
      allow create: if request.auth != null;
      allow update: if request.auth.uid == resource.data.toUid;
    }
  }
}
```

---

## Step 6 — Firebase Storage

1. Firebase Console → **Storage** → **Get started**
2. Start in production mode

### Storage Security Rules
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    match /profile_photos/{uid}.jpg {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == uid
                   && request.resource.size < 5 * 1024 * 1024
                   && request.resource.contentType.matches('image/.*');
    }

    match /post_images/{postId}.jpg {
      allow read: if request.auth != null;
      allow write: if request.auth != null
                   && request.resource.size < 10 * 1024 * 1024
                   && request.resource.contentType.matches('image/.*');
    }
  }
}
```

---

## Step 7 — FCM Push Notifications (Android)

FCM works automatically for Android once `google-services.json` is placed.

For iOS:
1. You need an Apple Developer account
2. Upload APNs certificate or key in Firebase Console → Project Settings → Cloud Messaging

---

## Step 8 — Change College Email Domain

Open `lib/services/auth_service.dart` and change:
```dart
static const String _collegeDomain = 'mnit.ac.in';
```
to your actual college domain, e.g. `iitd.ac.in`, `bits-pilani.ac.in`, etc.

---

## Step 9 — Run the App

```bash
flutter pub get
flutter run -d android
```

---

## Firestore Collections Structure

```
users/
  {uid}/
    name, handle, aura, role, year, building, stack,
    followers, following, bio, college, photoUrl,
    githubHandle, fcmToken, createdAt
    following/{uid} → { uid, followedAt }
    followers/{uid} → { uid, followedAt }
    bookmarks/{postId} → { postId }

posts/
  {postId}/
    userId, content, tags, imageUrl, likes, comments, reposts, createdAt
    likes/{uid}    → { uid }
    comments/{cid} → { uid, text, createdAt }

notifications/
  {nid}/
    toUid, fromUid, type, postId, message, read, createdAt
```

---

## Common Issues

| Problem | Fix |
|---------|-----|
| `google-services.json` not found | Make sure it's in `android/app/`, not `android/` |
| SHA-1 mismatch | Run `./gradlew signingReport` and paste correct SHA-1 |
| Google Sign-In crashes | Enable Google auth in Firebase Console |
| Storage permission denied | Check security rules and file size |
| iOS build fails | Add `GoogleService-Info.plist` via Xcode, not file explorer |
