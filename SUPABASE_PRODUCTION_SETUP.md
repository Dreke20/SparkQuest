# SparkQuest — Supabase Production Hardening & Auth Setup Guide

This guide details how to apply the production Row Level Security (RLS) migrations and configure the custom branded email authentication templates in your Supabase project.

---

## 1. Apply Production Migration

You can run this migration directly in the **Supabase Dashboard &rarr; SQL Editor**:
1. Open the SQL file: [`supabase/migrations/20261110000000_production_rls_and_security.sql`](file:///c:/Users/dreke/OneDrive/Desktop/SparkQuest/SparkQuest-master/supabase/migrations/20261110000000_production_rls_and_security.sql).
2. Copy the full SQL content.
3. Paste into the **SQL Editor** of your linked Supabase project (`kqvjntbiagzywstijtsz`) and click **Run**.
4. This instantly enables:
   - Anti-abuse mutual block filtering on stories and WebRTC calls.
   - Storage upload security policies on `avatars`, `stories`, and `voice-notes`.
   - Voice Lounges (`voice_lounges` and `voice_lounge_members`) with Realtime sync.

---

## 2. Configure Email Auth Templates in Supabase

In the Supabase Dashboard, navigate to:
**Authentication &rarr; Email Templates**

### A. Confirm signup (Confirmation Email)
* **Subject**: `Verify your SparkQuest account 🔥`
* **Template Body**: Copy from [`supabase/email-templates/confirmation_email.html`](file:///c:/Users/dreke/OneDrive/Desktop/SparkQuest/SparkQuest-master/supabase/email-templates/confirmation_email.html) and click **Save**.

### B. Magic Link
* **Subject**: `Your SparkQuest login code ⚡`
* **Template Body**: Copy from [`supabase/email-templates/magic_link_email.html`](file:///c:/Users/dreke/OneDrive/Desktop/SparkQuest/SparkQuest-master/supabase/email-templates/magic_link_email.html) and click **Save**.

### C. Reset Password
* **Subject**: `Reset your SparkQuest password 🛡️`
* **Template Body**: Copy from [`supabase/email-templates/reset_password_email.html`](file:///c:/Users/dreke/OneDrive/Desktop/SparkQuest/SparkQuest-master/supabase/email-templates/reset_password_email.html) and click **Save**.

---

## 3. Redirect URLs & Deep Linking

Under **Authentication &rarr; URL Configuration**:
* **Site URL**: `https://dreke20.github.io/SparkQuest`
* **Redirect URLs**:
  - `com.sparkquest.sparkquest://auth/callback`
  - `https://dreke20.github.io/SparkQuest/**`
  - `http://localhost:3000/**`

