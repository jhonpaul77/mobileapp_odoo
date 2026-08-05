# ⚡ Quick Start: Signing Release Build

**Untuk setup signing keystore hanya 3 langkah cepat:**

---

## 1️⃣ Generate Keystore (SEKALI SAJA)

```bash
cd android
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10950 -alias upload
```

**Isi data yang diminta:**
- Keystore Password: `your_password`
- Key Password: `your_password` (sama dengan keystore)
- Names: Nama perusahaan/pribadi
- Organization: PT Pintarx Indonesia
- City: Jakarta
- Country: ID

✅ Selesai, file `upload-keystore.jks` sudah terbuat

---

## 2️⃣ Update key.properties

File: `android/key.properties`

```properties
storePassword=your_password
keyPassword=your_password
keyAlias=upload
storeFile=../upload-keystore.jks
```

**Ganti `your_password` dengan password dari step 1**

---

## 3️⃣ Build & Upload

### Build release AAB (untuk Play Console):
```bash
flutter build appbundle --release
```

Hasilnya: `build/app/outputs/bundle/release/app-release.aab`

### Upload ke Play Console:
1. [https://play.google.com/console](https://play.google.com/console)
2. Create app baru
3. Release → Production
4. Upload `.aab` file
5. Review & Publish

---

## ⚠️ PENTING!

- **JANGAN COMMIT** file `key.properties` dan `upload-keystore.jks` ke Git! (sudah di `.gitignore`)
- **BACKUP** file `upload-keystore.jks` - dipakai selamanya untuk updates!
- **INCREMENT** `versionCode` di `pubspec.yaml` untuk setiap release baru

---

## 📚 Lebih Detail?

Lihat `RELEASE_SIGNING_GUIDE.md` untuk panduan lengkap, troubleshooting, dan FAQ.

---

**Status:** ✅ Setup file sudah ready di `android/app/build.gradle.kts`

Tinggal eksekusi 3 langkah di atas dan siap publish ke Play Store! 🚀
