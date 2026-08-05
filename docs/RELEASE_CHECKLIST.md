# ✅ Release Signing Setup Checklist

Gunakan checklist ini untuk memastikan semua konfigurasi signing sudah benar sebelum upload ke Play Console.

---

## 📋 Pre-Setup Check

- [ ] Java JDK sudah terinstall dan `keytool` accessible
- [ ] Flutter SDK sudah updated (`flutter upgrade`)
- [ ] Android SDK tools sudah updated
- [ ] Project folder: `d:\Yoga\Project\odoo Client\pintarx_mobile\android\`

---

## 🔑 Keystore Generation

- [ ] Navigasi ke folder `android/`
- [ ] Jalankan command: `keytool -genkey -v -keystore upload-keystore.jks ...`
- [ ] File `upload-keystore.jks` berhasil dibuat (size > 0)
- [ ] Password sudah aman dicatat (JANGAN LUPA!)
- [ ] Key alias sesuai: `upload`

**Command Reference:**
```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10950 -alias upload
```

---

## 📝 Configuration Files

### File: `android/key.properties`
- [ ] File ada di lokasi `android/key.properties`
- [ ] `storePassword` diisi dengan password keystore
- [ ] `keyPassword` diisi dengan key password
- [ ] `keyAlias` adalah `upload`
- [ ] `storeFile` adalah `../upload-keystore.jks`
- [ ] **JANGAN COMMIT ke Git!**

**Expected content:**
```
storePassword=your_actual_password
keyPassword=your_actual_password
keyAlias=upload
storeFile=../upload-keystore.jks
```

### File: `android/app/build.gradle.kts`
- [ ] Signing configuration sudah ditambahkan (lihat top of file)
- [ ] `signingConfigs { create("release") { ... } }` ada
- [ ] Release buildType punya `signingConfig = signingConfigs.getByName("release")`
- [ ] Tidak ada syntax error di file ini

---

## 🔒 Git Security

### .gitignore Check
- [ ] File `android/.gitignore` include:
  ```
  key.properties
  **/*.keystore
  **/*.jks
  ```
- [ ] Jalankan `git status` - pastikan `key.properties` & `*.jks` tidak muncul

### Cleanup (jika pernah ter-commit sebelumnya)
```bash
# Lihat apakah file sudah ter-commit
git log --all --full-history -- "android/key.properties"
git log --all --full-history -- "android/upload-keystore.jks"

# Jika ada, remove dari git history
git filter-branch --tree-filter 'rm -f android/key.properties android/upload-keystore.jks' HEAD
git push origin --force --all
```

- [ ] Pastikan tidak ada sensitive data di git history

---

## 🧪 Build & Test

### Test Build
- [ ] Debug build masih bisa dijalankan: `flutter run`
- [ ] Test release build:
  ```bash
  flutter build apk --release
  ```
- [ ] Tidak ada error saat compile
- [ ] File `build/app/outputs/flutter-apk/app-release.apk` terbuat

### Test AAB Build (Play Console format)
- [ ] Jalankan: `flutter build appbundle --release`
- [ ] Tidak ada error saat compile
- [ ] File `build/app/outputs/bundle/release/app-release.aab` terbuat (size > 10MB)

### Optional: Test APK Install
- [ ] Install APK di Android device/emulator: `adb install build/app/outputs/flutter-apk/app-release.apk`
- [ ] App bisa dibuka dan berfungsi normal
- [ ] Tidak ada crash atau error

---

## 📱 pubspec.yaml Preparation

- [ ] `version: X.Y.Z+N` sudah diupdate
  - Contoh: `version: 1.0.0+1`
  - X.Y.Z = semantic version (user lihat di Play Store)
  - N = build/version code (harus naik setiap release)

**Untuk setiap release update:**
```yaml
# Sebelum
version: 1.0.0+1

# Sesudah update pertama
version: 1.0.1+2

# Sesudah update kedua
version: 1.0.2+3
```

---

## 🚀 Build Release

### Siap Publish?
- [ ] Semua checklist di atas ✅
- [ ] Code sudah final dan tested
- [ ] App icon sudah final
- [ ] Splash screen sudah final
- [ ] Release notes sudah siap

### Build Commands

**Option 1: Build APK (untuk testing)**
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

**Option 2: Build AAB (untuk Play Console - RECOMMENDED)**
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

- [ ] Build berhasil tanpa error
- [ ] Output file ada dan size wajar
- [ ] Build artifacts tidak di-commit ke git

---

## 📤 Play Console Upload

### Pre-Upload
- [ ] Google Play Console account sudah terbuat
- [ ] App listing sudah dibuat (jika pertama kali)
- [ ] App name, description, privacy policy sudah diisi
- [ ] App icon, screenshots, promo graphics sudah uploaded
- [ ] Content rating questionnaire sudah diisi
- [ ] Pricing & distribution sudah dikonfigurasi

### Upload Steps
1. [ ] Login ke [https://play.google.com/console](https://play.google.com/console)
2. [ ] Pilih app yang akan di-release
3. [ ] Go to **Release** → **Production**
4. [ ] Klik **Create new release**
5. [ ] Upload file AAB/APK
6. [ ] Review release notes
7. [ ] Isi **Release notes** bahasa Indonesia
8. [ ] Review semua info sekali lagi
9. [ ] Klik **Review release**
10. [ ] Klik **Start rollout to Production**
11. [ ] Tunggu review process (biasanya 30 min - 24 jam)

- [ ] Upload berhasil (tidak ada error)
- [ ] App status: "Pending review" atau "Live"

---

## ⚠️ Post-Release Important

- [ ] **BACKUP** file `upload-keystore.jks` ke external storage
- [ ] **JANGAN HAPUS** file `upload-keystore.jks` - dipakai selamanya!
- [ ] **SIMPAN** password di tempat aman (password manager/vault)
- [ ] **DOKUMENTASI** keystore details:
  - [ ] File location: `android/upload-keystore.jks`
  - [ ] Key alias: `upload`
  - [ ] Created date: ___________
  - [ ] Used for Play Store ID: `id.pintarbisnis.pintarx`

---

## 🆘 Troubleshooting Checklist

### Build Error: "Signing config not found"
- [ ] `key.properties` file ada
- [ ] `key.properties` tidak kosong
- [ ] Syntax di `key.properties` benar
- [ ] Sudah save dan close file
- [ ] Jalankan: `flutter clean && flutter pub get`

### Build Error: "Keystore file not found"
- [ ] `upload-keystore.jks` ada di `android/` folder
- [ ] Path di `key.properties` benar: `../upload-keystore.jks`
- [ ] File tidak corrupt (bisa buka dengan keytool)

### Build Error: "Invalid password"
- [ ] Password di `key.properties` match dengan saat membuat keystore
- [ ] Tidak ada extra space di password
- [ ] Password di-quote jika ada special character

### Play Console Error: "Already signed with different key"
- [ ] Pastikan `upload-keystore.jks` adalah file yang sama
- [ ] Jangan buat keystore baru!
- [ ] Contact Play Store support jika perlu migrate keystore

---

## 📊 Release Tracking

Track setiap release untuk reference:

| Version | Code | Build Date | Status | Notes |
|---------|------|-----------|--------|-------|
| 1.0.0 | 1 | - | - | First release (akan di-publish) |
| 1.0.1 | 2 | - | - | Bug fixes |
| 1.1.0 | 3 | - | - | New features |

---

## ✅ Final Sign-Off

- [ ] Semua items di checklist sudah ✅
- [ ] Sudah test di device/emulator
- [ ] Sudah review code sekali lagi
- [ ] Siap untuk publish ke Play Store! 🎉

**Status:** READY FOR PRODUCTION ✅

---

**Last Updated:** 2026-08-01  
**Release Guide:** Lihat `RELEASE_SIGNING_GUIDE.md` untuk detail lengkap
