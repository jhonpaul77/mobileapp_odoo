lib/
├── config/
│   ├── theme.dart              ✅ SUDAH ADA
│   └── api_config.dart         ✅ SUDAH ADA
│
├── models/
│   └── auth/
│       ├── user.dart           ✅ SUDAH ADA
│       └── auth_response.dart  ✅ SUDAH ADA
│
├── services/
│   ├── api_service.dart        ✅ SUDAH ADA
│   ├── auth_service.dart       ✅ SUDAH ADA
│   ├── secure_storage_service.dart  ✅ SUDAH ADA
│   └── biometric_service.dart  ✅ SUDAH ADA
│
├── widgets/
│   └── common/                 📦 BUAT FOLDER INI
│       ├── app_header.dart     ⬇️ PINDAHKAN DARI Modules/
│       ├── app_bottom_nav.dart ⬇️ PINDAHKAN DARI Modules/
│       └── section_header.dart ⬇️ PINDAHKAN DARI Modules/
│
├── pages/
│   ├── auth/
│   │   ├── intro_page.dart         ✅ SUDAH ADA
│   │   ├── login_page.dart         ✅ SUDAH ADA
│   │   ├── setup_pin_page.dart     ✅ SUDAH ADA
│   │   └── lock_screen_page.dart   ✅ SUDAH ADA
│   │
│   ├── home/
│   │   ├── home_page.dart          🆕 BARU (Kerangka)
│   │   └── widgets/                📦 BUAT FOLDER INI (untuk dashboard widgets)
│   │       ├── kpi_cards.dart              ⏳ ISI NANTI (Step 1)
│   │       ├── menu_utama.dart             ⏳ ISI NANTI (Step 2)
│   │       ├── penjualan_terbaru.dart      ⏳ ISI NANTI (Step 3)
│   │       ├── stok_peringatan.dart        ⏳ ISI NANTI (Step 4)
│   │       ├── progress_produksi.dart      ⏳ ISI NANTI (Step 5)
│   │       └── pengeluaran_terkini.dart    ⏳ ISI NANTI (Step 6)
│   │
│   ├── profile/
│   │   └── profile_page.dart       🆕 BARU
│   │
│   └── settings/
│       └── setting_page.dart       🆕 BARU
│
└── main.dart                   ✅ SUDAH ADA