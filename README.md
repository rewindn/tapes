# Tapes - Record Your Day

Aplikasi journaling harian sederhana untuk mencatat 1 masalah yang kamu selesaikan setiap hari.

## Features

- 📅 **Home Page** - Kalender dengan visualisasi tanggal yang sudah ada note
- ✍️ **Add Note** - Form untuk menulis catatan harian
- 📋 **List Tapes** - Daftar semua catatan yang sudah dibuat
- 📊 **Progress Tracker** - Persentase hari yang sudah diisi dalam bulan ini

## Tech Stack

- **Flutter** - UI Framework
- **Hive** - Local Database
- **intl** - Date Formatting

## Color Legend

| Warna | Arti |
|-------|------|
| 🟢 Hijau | Tanggal sudah ada note |
| 🟠 Orange | Hari ini, belum ada note |
| ⚪ Abu-abu | Tidak ada note |

## Project Structure

```
lib/
├── main.dart       # Entry point, Hive setup
├── index.dart      # Navigation (3 tabs)
├── home.dart       # Home page dengan kalender
├── content.dart    # Form input note
├── listtape.dart   # List semua notes
├── listcard.dart   # Card component
├── note.dart       # Model Note (Hive)
├── note.g.dart     # Generated Hive adapter
└── box.dart        # Hive box reference
```

## Getting Started

```bash
# Install dependencies
flutter pub get

# Generate Hive adapter (jika perlu)
flutter pub run build_runner build

# Run app
flutter run
```

## Data Storage

Data disimpan secara lokal menggunakan Hive di device. 

⚠️ **Perhatian:** Jika app di-uninstall, data akan hilang.

## Screenshots

![Home Page](desain%20yang%20harus%20di%20tiru%20sama%20persis.png)
