# V2Ray Client — Flutter

یک کلاینت V2Ray/Xray سبک برای اندروید و iOS ساخته شده با Flutter.

## ویژگی‌ها

- ✅ پشتیبانی از VMess, VLESS, Trojan, Shadowsocks
- ✅ وارد کردن لینک تکی (`vmess://`, `vless://`, `trojan://`, `ss://`)
- ✅ وارد کردن چند لینک به‌صورت bulk
- ✅ مدیریت سابسکریپشن (fetch + auto-parse Base64/plain)
- ✅ نمایش ترافیک آپلود/دانلود
- ✅ UI تاریک با طراحی مدرن
- ✅ ذخیره‌سازی محلی (SharedPreferences)
- ✅ پشتیبانی از TLS, Reality, WebSocket, gRPC, XHTTP/SplitHTTP

---

## پیش‌نیاز نصب

```bash
# Flutter SDK >= 3.10
flutter --version

# وابستگی‌ها
flutter pub get
```

---

## ساخت برای اندروید

```bash
# Debug APK
flutter build apk --debug

# Release APK (نیاز به sign دارد)
flutter build apk --release

# AAB برای Play Store
flutter build appbundle --release
```

### نکته برای release:
فایل `android/key.properties` را بسازید:
```
storePassword=YOUR_PASS
keyPassword=YOUR_PASS
keyAlias=your_alias
storeFile=../keystore.jks
```

---

## ساخت برای iOS

```bash
# نیاز به macOS و Xcode دارید
flutter build ios --release

# سپس در Xcode archive بگیرید
open ios/Runner.xcworkspace
```

### Info.plist — مجوزهای لازم:
```xml
<key>NSLocalNetworkUsageDescription</key>
<string>This app uses VPN to secure your connection.</string>
```

---

## ساختار پروژه

```
lib/
├── main.dart               # Entry point + Theme
├── models/
│   └── v2ray_config.dart   # مدل کانفیگ و سابسکریپشن
├── providers/
│   └── app_provider.dart   # State management + Xray config builder
├── screens/
│   ├── home_screen.dart    # صفحه اصلی
│   ├── configs_screen.dart # لیست و مدیریت کانفیگ‌ها
│   └── subscriptions_screen.dart
├── services/
│   ├── config_parser.dart  # پارس vmess/vless/trojan/ss
│   ├── subscription_service.dart  # Fetch + decode Base64
│   └── storage_service.dart
└── widgets/
    ├── connect_button.dart
    ├── config_card.dart
    └── traffic_info.dart
```

---

## وابستگی‌های اصلی

| Package | نقش |
|---------|-----|
| `flutter_v2ray` | Xray core wrapper (VPN tunnel) |
| `provider` | State management |
| `shared_preferences` | ذخیره محلی |
| `http` | دریافت سابسکریپشن |
| `flutter_animate` | انیمیشن‌ها |
| `uuid` | شناسه یکتا |

---

## مقایسه با Hiddify

اگر می‌خواهید از Hiddify fork بزنید، این پروژه سبک‌تر است و:
- بدون Clash core — فقط Xray
- بدون پنل تنظیمات پیچیده
- مناسب برای embed در اپ‌های دیگر

---

## یادداشت مهم

`flutter_v2ray` روی Xray core بنا شده و برای اندروید از VpnService استفاده می‌کند.  
برای iOS باید Network Extension را در Xcode تنظیم کنید (نیاز به Apple Developer Account با VPN entitlement دارد).

```
Xcode → Signing & Capabilities → + Capability → Network Extensions
```

---

## لایسنس

MIT
