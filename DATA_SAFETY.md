# SparkQuest — Google Play Data Safety Form Guide

Use the exact answers below when filling out the **Data safety** section in Google Play Console (`App content &rarr; Data safety`).

---

## 1. Overview Questions

| Question | Answer | Notes |
| :--- | :---: | :--- |
| **Does your app collect or share any of the required user data types?** | **Yes** | Profile, location, photos, audio, and messages are processed. |
| **Is all of the user data collected by your app encrypted in transit?** | **Yes** | All network traffic uses TLS 1.3 / HTTPS and WSS (Supabase Cloud). |
| **Do you provide a way for users to request that their data be deleted?** | **Yes** | Both within the app and via the external web deletion URL. |
| **Provide a link that users can use to request their account and data be deleted** | `https://dreke20.github.io/SparkQuest/delete-account.html` | Public web portal complying with Google Play's Account Deletion Policy. |

---

## 2. Data Types Collected & Declared

### 📍 Location
* **Approximate location**:
  * **Collected?**: Yes
  * **Shared?**: No
  * **Processed ephemerally?**: No
  * **Required or Optional?**: Required (for neighborhood Safe Haven venue recommendations and 500m privacy blur)
  * **Purposes**: App functionality, Fraud prevention / security
* **Precise location**:
  * **Collected?**: Yes
  * **Shared?**: No
  * **Processed ephemerally?**: No
  * **Required or Optional?**: Optional (user can disable or stay in 500m privacy blur mode)
  * **Purposes**: App functionality (Live CartoDB Dark Matter map, proximity beacons, ember drop discovery)

### 👤 Personal Info
* **Name / Display Name**:
  * **Collected?**: Yes | **Shared?**: No | **Purpose**: Account management, App functionality
* **Email address**:
  * **Collected?**: Yes | **Shared?**: No | **Purpose**: Account management, security
* **User IDs**:
  * **Collected?**: Yes | **Shared?**: No | **Purpose**: Account management
* **Sexual orientation / Dating Preferences**:
  * **Collected?**: Yes | **Shared?**: No | **Purpose**: Matchmaking & app functionality
* **Other info (Age, Bio, Prompts)**:
  * **Collected?**: Yes | **Shared?**: No | **Purpose**: App functionality (Matchmaking)

### 💳 Financial Info
* **User payment info (Credit Cards)**:
  * **Collected?**: **No** (Processed strictly by Google Play Billing; SparkQuest does not handle payment card numbers)
* **Purchase history**:
  * **Collected?**: Yes | **Shared?**: No | **Purpose**: Google Play Billing entitlements (Embers, Gold VIP subscription, Spotlight boosts)

### 📷 Photos and Videos
* **Photos**:
  * **Collected?**: Yes | **Shared?**: No | **Purpose**: Profile pictures, 3D Anti-Catfish liveness selfie verification

### 🎙️ Audio Files
* **Voice or sound recordings**:
  * **Collected?**: Yes
  * **Processed ephemerally?**: **Yes** (Real-time WebRTC audio streams for drop-in Voice Lounges; streams are not saved to disk)
  * **Purposes**: App functionality

### 💬 Messages
* **Other in-app messages**:
  * **Collected?**: Yes | **Shared?**: No | **Purpose**: Real-time chat messages between mutual matches

### 📱 Device or Other Identifiers
* **Device or other IDs**:
  * **Collected?**: Yes | **Shared?**: No | **Purpose**: Anti-fraud, session tokens, push notifications

---

## 3. Content Rating Questionnaire (18+ Dating Category)

In Google Play Console (`App content &rarr; Content rating`):
1. **Category**: Select **"Social or Communication"** or **"Utility, Productivity, Communication, or Other"**.
2. **Violence**: None.
3. **Sexuality / Nudity**: Does the app contain nudity? **No**. Does the app facilitate dating? **Yes**.
4. **Language**: None in official app content.
5. **Controlled Substances**: No.
6. **Age Restriction Declaration**: Check the box indicating the app is restricted to **Adults (18+)**.
   * *Google Play Dating Policy*: All dating apps must set target audience to **18+ only**. Do not select any age bracket under 18.
7. **Child Safety Standards Policy URL**:
   * Google Play requires social and dating apps to publish a public webpage declaring zero tolerance for CSAM/CSAE and underage use.
   * Enter Public URL: `https://dreke20.github.io/SparkQuest/child-safety.html`
   * Confirm users can report child safety concerns in-app (Implemented: *"Child Safety / Underage Concern"* option).

---

## 4. Closed Testing Requirements (Personal Developer Account)

Since your Google Play developer account is a **Personal account** (created after November 13, 2023), Google Play enforces the **Closed Testing Policy**:
1. **Requirement**: At least **12 testers** must opt in to your Closed Test track for at least **14 consecutive days**.
2. **Setup in Play Console**:
   * Create a **Closed Testing Track** (e.g. `Alpha` or `Closed Beta`).
   * Create an **Email List** of at least 12 friends, colleagues, or beta testers (with their Google Play Google account emails).
   * Upload the signed `app-release.aab`.
   * Share the opt-in link (`https://play.google.com/apps/testing/com.sparkquest.sparkquest`) with your testers.
   * Ensure testers keep the app installed and actively test for 14 days before submitting the "Apply for Production" questionnaire in Play Console.

