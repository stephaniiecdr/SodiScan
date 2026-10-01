# Flutter Project Structure & Implementation Guide

Dokumen ini menjelaskan bagaimana konsep Flutter (prototype, struktur proyek, routing, reusable widget, model, service/API) diterapkan pada SodiScan.

Saat dokumen ini ditulis, repository belum berisi source code Flutter. Acuannya adalah [`Architecture.md`](Architecture.md) dan [`README.md`](README.md). Setiap bagian diberi label:

- **[Ditetapkan]**: tertulis di `Architecture.md` atau `README.md`.
- **[Rekomendasi struktur]**: belum ditetapkan dan belum diimplementasikan. Ini usulan, termasuk semua nama file yang tidak disebut di spesifikasi.

Setelah source code dibuat, dokumen ini perlu diperbarui agar nama file dan class sesuai dengan implementasi aktual.

## Pemetaan dengan Contoh Struktur Umum

Contoh struktur Flutter yang umum (`screens/`, `widgets/`, `models/`, `services/`, `routes/`, dengan halaman Login dan Profile) bersifat generik. Tabel berikut menunjukkan padanannya di SodiScan.

| Konsep | Contoh umum | Padanan di SodiScan |
|---|---|---|
| Prototype | Login, Dashboard, Detail, Profile | Beranda, Pindai Barcode, Detail Produk, Input Manual, Riwayat ([bagian 1](#1-prototype)) |
| Struktur proyek | Folder datar `screens/`, `widgets/`, dst. | Dikelompokkan per layer; `screens/` dan `widgets/` berada di `presentation/` ([bagian 2](#2-project-structure)) |
| Routing | `routes/app_routes.dart` | `Navigator` bawaan, opsional named routes ([bagian 6](#6-routing)) |
| Reusable widget | `primary_button.dart`, `app_text_field.dart` | `primary_button.dart`, `risk_status_badge.dart`, `sodium_summary_card.dart`, dst. ([bagian 5](#5-reusable-widgets--components)) |
| Model | `models/user_model.dart` | `data/models/` dan `domain/entities/` ([bagian 7](#7-models)) |
| Service/API | `services/auth_service.dart` | `data/datasources/remote` dan `local`, ditambah repository ([bagian 8](#8-services--data-sources) dan [9](#9-repository)) |

Bagian yang sengaja tidak dipakai:

- **Login, Profile, dan `auth_service`**: SodiScan berjalan tanpa akun dan autentikasi (lihat README, *Fitur yang Tidak Dikerjakan*).
- **Folder `services/`**: perannya digantikan oleh data source dan repository sesuai Clean Architecture di `Architecture.md`.
- **Folder `routes/`**: tidak ada di struktur yang ditetapkan. Jika ingin route terpusat, konstanta nama route diletakkan di `core/constants/`.

## 1. Prototype

Prototype adalah rancangan awal UI/UX SodiScan. Tujuannya menguji tata letak, isi layar, dan alur pengguna sebelum logika aplikasi selesai dibuat. Prototype bisa berupa:

- **Wireframe**: sketsa kotak-kotak tanpa warna, cukup untuk menyepakati isi tiap halaman.
- **Figma / mock UI**: tampilan lengkap dengan warna, tipografi, dan alur klik antar-halaman.
- **Prototype UI Flutter**: screen Flutter dengan data dummy, tanpa Provider, API, atau Hive.

**[Ditetapkan]** Halaman yang perlu diprototipekan hanya lima halaman berikut (`Architecture.md` → *Halaman aplikasi*):

| Halaman | Isi utama di prototype |
|---|---|
