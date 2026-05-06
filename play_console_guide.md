# Mita - Google Play Console Release Guide

Use this guide to fill in all fields when releasing on Google Play Console.

---

## 1. App Information

### Basic Details
| Field | Value |
|-------|-------|
| **App Name** | Mita |
| **Default Language** | English (en) |
| **Title** | Mita |
| **Short Description** (30 chars max) | Mita - 3 tasks • 1 day |
| **Full Description** | Mita is a minimalist task manager that helps you focus on what matters. Add up to 3 tasks per day, complete them, and build your streak. Simple, focused, effective. |

### Category & Tag
| Field | Value |
|-------|-------|
| **Category** | Productivity |
| **Tagline** | Focus on what matters |

---

## 2. Store Listing

### Graphics

#### App Icon (REQUIRED)
- **File:** 512x512 PNG
- **Background:** Solid #0D0D0D (no transparency)
- **Design:** ⊙ symbol or "M" in white with #E94560 accent

#### Feature Graphic (REQUIRED for TV Banner)
- **File:** 1920x1080 PNG or JPEG
- **Max Size:** 1024KB

#### Phone Screenshots (REQUIRED - 2+ each)
Minimum 2 screenshots per type, 16:9 aspect ratio recommended

| Device Type | Dimensions | Quantity |
|------------|-----------|----------|
| Phone 5.5" | 1080x1920 | 2-8 |
| Phone 6.0" | 1080x2340 | 2-8 |
| 10" Tablet | 2560x1800 | 2-8 |

**Screenshot Ideas to Capture:**
1. Home screen with tasks (filled + empty slots)
2. Perfect day state (3/3 complete)
3. Stats screen with streak + heatmap
4. History screen with past days
5. Menu sheet open
6. Settings screen

#### 7" Tablet Screenshots (Optional)
- 2048x1536 or 2560x1800

---

## 3. Store Text

### Short Description (30 chars max)
```
Mita - 3 tasks • 1 day
```

### Full Description (500-4000 chars)
Copy and paste:

```
Mita — Focus on what matters

Three tasks. One day. That's all you need to stay productive.

Mita is a minimalist task manager designed to help you focus on what truly matters. With a simple 3-task daily limit, you can concentrate on completing your most important tasks every day.

KEY FEATURES:
• Add up to 3 tasks per day
• Build your streak by completing all tasks daily
• Track your progress with weekly/monthly stats
• View your history and see how far you've come
• Streak heatmap to visualize your consistency

WHY MITA:
• No overwhelming to-do lists
• Focus on quality over quantity
• Build productive habits one day at a time
• Track your productivity journey

PERFECT FOR:
• Daily priorities
• Habit building
• Focus management
• Minimalist productivity

Download Mita today and start focusing on what matters.

---
Privacy Policy: https://sai-vardhan-portfolio.vercel.app/mita-privacy.html
Contact: ddvardhan2@gmail.com
```

### What's New (Optional)
```
• Initial release
• 3 tasks per day focus
• Streak tracking
• Stats & heatmap
• History view
• AdMob integrated (optional ads)
```

---

## 4. Content Rating

### Content Rating Questionnaire

| Question | Answer |
|----------|--------|
| **Does your app contain any content for children?** | No |
| **Does your app primarily teach children about a topic?** | N/A |
| **Does your app depict criminal activities?** | No |
| **Does your app depict illegal drug use?** | No |
| **Does your app depict self-harm or suicide?** | No |
| **Does your app contain offensive language?** | No |
| **Does your app contain sexual content?** | No |
| **Does your app contain gore?** | No |
| **Does your app contain gambling?** | No |
| **Does your app promote tobacco/alcohol use?** | No |

**Result:** Rating will be: **Everyone**

---

## 5. Privacy Policy

### Required URL
```
https://sai-vardhan-portfolio.vercel.app/mita-privacy.html
```

### Disclosure Requirements
Since app uses AdMob, check these boxes in Play Console:
- [x] AdMob (or other ad SDK) present in app
- [x] App shows ads from Google AdMob
- [x] Ads may include personalized ads
- [x] Users can opt out of personalized ads

### Privacy Policy Must Include:
1. What data you collect (none personally identifiable)
2. How you use data (local storage only)
3. Third-party data sharing (AdMob only)
4. User control/deletion options
5. Contact email: ddvardhan2@gmail.com

---

## 6. Ad Policy (AdMob)

### Ad SDK Disclosure
```dart
// AdMob is integrated in this app
// Test IDs used:
// - Interstitial: ca-app-pub-3940256099942544/1033173712
// - Rewarded: ca-app-pub-3940256099942544/5228744914
// Replace with real IDs before release
```

### Ad Disclosure in App
- Interstitial ads show on Stats/History navigation (max 3/session)
- Rewarded ads are OPTIONAL (user-initiated only)
- Never interrupts task interactions

---

## 7. Build & Release

### Version Info
| Current | Value |
|---------|-------|
| **Version** | 1.0.0 |
| **Version Code** | 1 |
| **Min SDK** | 21 (Android 5.0) |
| **Target SDK** | 34 |
| **Compile SDK** | 34 |

### Build Commands
```bash
# Debug build (testing)
flutter build apk --debug

# Release build (Play Store)
flutter build apk --release
```

### Signing (Important!)
1. Create signing key:
   ```bash
   keytool -genkeypair -v -storetype PKCS12 -keystore mita-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias mita
   ```

2. Configure in `android/app/build.gradle.kts`:
   ```kotlin
   signingConfigs {
       create("release") {
           storeFile = file("mita-release.jks")
           storePassword = "yourpassword"
           keyAlias = "mita"
           keyPassword = "yourpassword"
       }
   }
   ```

3. Build release APK:
   ```bash
   flutter build apk --release
   ```

---

## 8. Release Management

### Release Tracks

| Track | Use | Notes |
|-------|-----|-------|
| **Internal Testing** | Initial test | Only visible to you |
| **Closed Testing** | Beta testers | Invite email list |
| **Open Testing** | Public beta | Anyone can join |
| **Production** | Full release | Everyone |

### Recommended Release Flow
1. Upload to **Internal Testing** first
2. Test for 1-2 days
3. Move to **Closed Testing** (if needed)
4. Move to **Production**

---

## 9. Pre-Release Checklist

- [ ] App icon created (512x512 PNG)
- [ ] Feature graphic created (1920x1080)
- [ ] 2+ phone screenshots captured
- [ ] All store text filled
- [ ] Privacy policy URL added
- [ ] Privacy questionnaire completed
- [ ] Content rating obtained
- [ ] AdMob disclosure done
- [ ] Build signed (release key)
- [ ] Tested on real device
- [ ] Version incremented (if updating)

---

## 10. Important Links

| Resource | URL |
|----------|-----|
| **App Page** | https://play.google.com/store/apps/details?id=com.dreamstarx.mita |
| **Privacy Policy** | https://sai-vardhan-portfolio.vercel.app/mita-privacy.html |
| **Developer Contact** | ddvardhan2@gmail.com |

---

## Summary - Quick Copy Paste

**App Name:** Mita
**Package:** com.dreamstarx.mita
**Version:** 1.0.0
**Privacy:** https://sai-vardhan-portfolio.vercel.app/mita-privacy.html
**Email:** ddvardhan2@gmail.com

**AdMob Test IDs:**
- Interstitial: ca-app-pub-3940256099942544/1033173712
- Rewarded: ca-app-pub-3940256099942544/5228744914

---

*Last Updated: April 22, 2026*