# Offline Voice Typing (فارسی + English)

اپلیکیشن تایپ صوتی **کاملاً آفلاین** برای افراد بینا و نابینا.

## ویژگی‌ها
- تشخیص گفتار آفلاین با Vosk (پشتیبانی فارسی و انگلیسی)
- طراحی دسترسی‌پذیر (TalkBack / VoiceOver، دکمه‌های بزرگ، کنتراست بالا)
- UI مدرن و جذاب برای افراد بینا
- سوئیچ آسان زبان
- بازخورد صوتی (TTS)
- آماده برای گسترش به کیبورد سیستم (IME)

## پیش‌نیازها برای بیلد
- Flutter 3.22+ 
- Android Studio / SDK (برای APK)
- حداقل 4GB فضای خالی (برای مدل‌ها)

## نصب و اجرا

```bash
git clone https://github.com/r82146777-art/offline-voice-typing-fa-en.git
cd offline-voice-typing-fa-en
flutter pub get
```

### دانلود مدل‌های Vosk (ضروری)

مدل‌ها را از اینجا دانلود کنید و داخل پوشه `assets/models/` قرار دهید:

- فارسی (کوچک): https://alphacephei.com/vosk/models/vosk-model-small-fa-0.42.zip
- انگلیسی (کوچک): https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip

بعد از دانلود، فایل‌های zip را از حالت فشرده خارج کنید تا ساختار زیر ساخته شود:

```
assets/models/
├── fa/
│   └── (محتوای vosk-model-small-fa-0.42)
└── en/
    └── (محتوای vosk-model-small-en-us-0.15)
```

سپس در `pubspec.yaml` مسیر assets را چک کنید.

### اجرا روی دستگاه
```bash
flutter run
```

### ساخت APK
```bash
flutter build apk --release
```
فایل APK در مسیر زیر ساخته می‌شود:
`build/app/outputs/flutter-apk/app-release.apk`

## وضعیت فعلی
- [x] ساختار پروژه Flutter
- [x] UI دسترسی‌پذیر + تم زیبا
- [x] سرویس STT با Vosk (آماده اتصال مدل)
- [x] پشتیبانی دو زبانه
- [ ] دانلود خودکار مدل داخل اپ (نسخه بعدی)
- [ ] پیاده‌سازی کامل Input Method (کیبورد سیستم)
- [ ] ویجت صفحه اصلی

## مشارکت
هرگونه ایراد، پیشنهاد یا بهبود را در Issues گزارش دهید.

---
ساخته‌شده با تمرکز روی دسترس‌پذیری و حریم خصوصی (هیچ صدایی به سرور ارسال نمی‌شود).
