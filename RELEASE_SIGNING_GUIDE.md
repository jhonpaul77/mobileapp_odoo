# 🔐 Release Signing Setup Guide untuk Play Console

Panduan lengkap untuk setup signing keystore agar bisa upload ke Play Console.

## Prerequisite
- Keytool sudah tersedia (biasanya bawaan Java JDK)
- Android SDK sudah terinstall

---

## 📋 STEP 1: Generate Keystore

Jalankan command di bawah untuk membuat keystore baru. **Lakukan ini SEKALI saja dan simpan baik-baik!**

```bash
# Windows (PowerShell)
cd d:\Yoga\Project\odoo Client\pintarx_mobile\android

# Atau jika menggunakan CMD
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10950 -alias upload

# Akan diminta untuk mengisi data:
# - Keystore Password: ******* (ingat baik-baik!)
# - Key Password: ******* (bisa sama dengan keystore password)
# - First and Last Name: Masukkan nama perusahaan/Anda
# - Organizational Unit: Departemen (contoh: Development)
# - Organization Name: Nama organisasi (contoh: PT Pintarx)
# - City or Locality: Kota
# - State or Province: Provinsi
# - Country Code: ID (untuk Indonesia)
# - Konfirmasi: yes
```

### Contoh Output:
```
Generating 2,048 bit RSA key pair and self-signed certificate (SHA256withRSA) with a validity of 10,950 days
	for: CN=PT Pintarx, OU=Development, O=Pintarx Indonesia, L=Jakarta, ST=Jakarta, C=ID
Enter key password for <upload>
	(RETURN if same as keystore password):
```

---

## 🔑 STEP 2: Konfigurasi key.properties

Setelah keystore berhasil dibuat, update file `android/key.properties`:

### File: `android/key.properties`
```properties
storePassword=your_keystore_password_here
keyPassword=your_key_password_here
keyAlias=upload
storeFile=../upload-keystore.jks
```

**Ganti dengan password yang Anda gunakan saat membuat keystore!**

### Contoh:
```properties
storePassword=P1nT@rx2024
keyPassword=P1nT@rx2024
keyAlias=upload
storeFile=../upload-keystore.jks
```

---

## ⚠️ STEP 3: Security - Jangan Commit ke Git!

File `key.properties` dan `upload-keystore.jks` berisi sensitive data. **Jangan commit ke repository!**

### Check `.gitignore`:
```
# Sudah ditambahkan di .gitignore untuk keamanan
android/key.properties
android/*.jks
android/*-keystore.jks
```

Pastikan file sudah diabaikan oleh Git:
```bash
# Check status
git status

# Jika sudah di-commit sebelumnya, remove dari tracking:
git rm --cached android/key.properties
git rm --cached android/upload-keystore.jks
git commit -m "Remove sensitive signing files from git"
```

---

## 🚀 STEP 4: Build Release APK/AAB

Setelah konfigurasi signing selesai, build release build:

### Build APK (untuk testing)
```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Build App Bundle (untuk Play Console - RECOMMENDED)
```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

---

## 📤 STEP 5: Upload ke Play Console

### Untuk pertama kali (Initial Release):
1. Login ke [Google Play Console](https://play.google.com/console)
2. Buat aplikasi baru
3. Isi App information (nama, icon, etc)
4. Go to **Release** → **Production**
5. Upload file `.aab` (App Bundle)
6. Isi deskripsi release dan notes
7. **Review** data sebelum submit
8. Klik **Publish** untuk live di Play Store

### Untuk update selanjutnya:
- Naikkan `versionCode` dan `versionName` di `pubspec.yaml`
- Build APK/AAB baru
- Upload ke Play Console
- Ikuti review process

---

## 📝 Checklist Sebelum Upload

- [ ] Keystore sudah dibuat (`upload-keystore.jks` ada)
- [ ] `key.properties` sudah diisi dengan password yang benar
- [ ] `key.properties` & `*.jks` sudah di `.gitignore`
- [ ] Tidak ada `key.properties` di git history
- [ ] `pubspec.yaml` sudah update version code/name
- [ ] Release build berhasil dicompile
- [ ] APK/AAB sudah tested di device
- [ ] App icon & splash screen sudah final
- [ ] Deskripsi app & changelog sudah siap
- [ ] Privacy policy URL sudah ditambahkan

---

## 🔧 Troubleshooting

### Error: "keytool: command not found"
**Solusi:** Keytool ada di `JAVA_HOME/bin`
```bash
# Windows
"C:\Program Files\Java\jdk-11\bin\keytool" -genkey -v -keystore ...

# atau tambahkan ke PATH system environment variable
```

### Error: "Keystore file not found"
**Solusi:** Pastikan file `upload-keystore.jks` ada di `android/` folder

### Error: "Signing config not found"
**Solusi:** 
- Pastikan `key.properties` ada dan berisi data lengkap
- Restart Android Studio/rebuild gradle

### Error: "Invalid keystore format"
**Solusi:** Keystore mungkin corrupt. Generate ulang:
```bash
del android/upload-keystore.jks
keytool -genkey -v -keystore upload-keystore.jks ...
```

### Error: "Play Console rejected upload"
**Kemungkinan:**
- Signing config tidak lengkap → Check `key.properties`
- Version code sudah dipakai → Naikkan di `pubspec.yaml`
- APK/AAB sudah signed dengan keystore lain → Gunakan keystore yang sama

---

## 🎯 Info Penting

### Keystore Retention
- **JANGAN HILANGKAN** file `upload-keystore.jks`!
- Semua future updates harus signed dengan keystore yang sama
- Jika hilang, tidak bisa update app di Play Console
- Backup file ini di tempat aman (external drive, cloud)

### Version Management
- Setiap release harus increment `versionCode`
- `versionCode` = int yang selalu naik (1, 2, 3, ...)
- `versionName` = semantic version (1.0.0, 1.0.1, 1.1.0, ...)

### File Locations
```
android/
├── upload-keystore.jks          ← Keystore file (JANGAN COMMIT!)
├── key.properties               ← Config signing (JANGAN COMMIT!)
├── app/
│   └── build.gradle.kts         ← Sudah dikonfigurasi signing
└── build/
    └── app/outputs/
        ├── flutter-apk/
        │   └── app-release.apk  ← APK output
        └── bundle/
            └── release/
                └── app-release.aab ← AAB output (preferred)
```

---

## 📚 References
- [Flutter Release Signing Documentation](https://docs.flutter.dev/deployment/android#signing-the-app)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [Android App Signing Documentation](https://developer.android.com/studio/publish/app-signing)

---

## ✅ Setup Complete!

Setelah follow semua step ini, Anda siap untuk:
1. Build signed release APK/AAB
2. Upload ke Google Play Console
3. Publish aplikasi ke Play Store 🎉

**Good luck! 🚀**
