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
| Beranda | Total natrium hari ini vs 2.000 mg, badge status, daftar konsumsi hari ini, tombol `Pindai Barcode` dan `Input Manual` |
| Pindai Barcode | Preview kamera, indikator loading, tombol `Input Manual` |
| Detail Produk | Nama, merek, takaran saji, natrium, field porsi/berat, tombol `Simpan Konsumsi` |
| Input Manual | Form nama produk dan natrium (mg), tombol `Simpan Konsumsi` |
| Riwayat | Daftar konsumsi per tanggal, beserta total dan status per tanggal |

**Profile tidak termasuk.** Aplikasi tidak punya akun atau autentikasi, jadi halaman profil tidak diperlukan.

Beberapa aturan UI juga sudah ditetapkan dan sebaiknya langsung tercermin di prototype:

- Semua label dalam Bahasa Indonesia.
- Memakai kartu, badge, form, dan empty state.
- Ada state loading, kosong, dan error.
- Warna badge: Aman hijau, Mendekati Batas oranye, Bahaya merah.
- Tidak ada chart di versi pertama.

Belum ada file Figma di repo. Jika nanti ada, desain Figma menjadi acuan tampilan, sedangkan `Architecture.md` tetap menjadi acuan fungsi.

## 2. Project Structure

**[Ditetapkan]** Struktur dari `Architecture.md`:

```text
lib/
  core/
  data/
    datasources/
      local/
      remote/
    models/
    repositories/
  domain/
    entities/
    repositories/
    usecases/
  presentation/
    providers/
    screens/
    widgets/
  main.dart
```

| Folder | Tanggung jawab di SodiScan |
|---|---|
| `core/` | Hal lintas layer: konstanta (batas 2.000 mg, ambang 1.500 mg, URL API, timeout 10 detik), tipe error/failure, dan utilitas kecil seperti format tanggal |
| `data/datasources/remote/` | Komunikasi HTTP dengan Open Food Facts (package `http`) |
| `data/datasources/local/` | Baca/tulis Hive box `consumptions` |
| `data/models/` | Bentuk data untuk JSON API dan penyimpanan Hive |
| `data/repositories/` | Implementasi repository: memanggil data source dan mengubah model menjadi entity |
| `domain/entities/` | Konsep bisnis murni: `Product`, `FoodConsumption`, `DailyNutrition` |
| `domain/repositories/` | Kontrak (abstract class) repository |
| `domain/usecases/` | Satu aksi bisnis per class |
| `presentation/providers/` | State management (Provider) yang memanggil use case |
| `presentation/screens/` | Halaman |
| `presentation/widgets/` | Komponen UI yang dipakai berulang |

Alasan pemisahannya, sesuai aturan di `Architecture.md`:

- Domain tidak boleh bergantung pada Flutter, Hive, atau `http`. Aturan risiko dan perhitungan natrium jadi bisa di-unit-test tanpa emulator, dan unit test ini memang termasuk deliverable.
- Presentation tidak boleh mengimpor model data, JSON, atau Hive. Kalau sumber data berubah, UI tidak perlu ikut diubah.

Struktur ini sudah cukup untuk lima halaman dan empat use case. Tidak perlu menambah layer lain.

## 3. Main Entry Point

**`lib/main.dart` [Ditetapkan sebagai satu-satunya file di root `lib/`]**

Alur kerja `main.dart` secara konseptual:

```text
main()
 ↓
WidgetsFlutterBinding.ensureInitialized()
 ↓
Hive.initFlutter() + register adapter + buka box "consumptions"
 ↓
Rakit dependency: DataSource → RepositoryImpl → UseCase
 ↓
runApp( MultiProvider( providers: [...], child: MaterialApp(...) ) )
```

**`lib/app.dart` [Rekomendasi struktur, opsional]**

`Architecture.md` tidak mencantumkan `app.dart`, jadi file ini tidak wajib. File ini baru berguna kalau `main.dart` mulai terlalu panjang. Isinya nanti:

- widget root (`MaterialApp`);
- theme, termasuk warna status;
- konfigurasi route;
- `MultiProvider`.

Dengan begitu `main.dart` hanya berisi inisialisasi. Kalau `main.dart` masih ringkas, cukup satu file saja.

## 4. Screens / Pages

Screen adalah widget setingkat halaman yang dibuka lewat navigasi. Screen hanya menampilkan state dari Provider dan meneruskan aksi pengguna ke Provider. Screen tidak boleh melakukan HTTP request atau mengakses Hive.

**[Ditetapkan]** Lima halaman. **[Rekomendasi struktur]** Susunan folder:

```text
presentation/screens/
  home/            home_screen.dart
  scanner/         scanner_screen.dart
  product_detail/  product_detail_screen.dart
  manual_input/    manual_input_screen.dart
  history/         history_screen.dart
```

| Screen | Tujuan | Informasi yang ditampilkan | Input / aksi | State yang dipakai | Navigasi |
|---|---|---|---|---|---|
| **Beranda** | Ringkasan hari ini | Total natrium, batas 2.000 mg, badge status, daftar konsumsi hari ini | Tap `Pindai Barcode` atau `Input Manual`, buka Riwayat | Ringkasan harian (loading, kosong, data) dari data lokal saja, tanpa API | → Pindai, → Input Manual, → Riwayat |
| **Pindai Barcode** | Membaca barcode dengan `mobile_scanner` | Preview kamera, loading saat mencari | Arahkan kamera; tap `Input Manual` | Status pencarian (idle, loading, error); deteksi dihentikan selama pencarian | Berhasil → Detail Produk; gagal → pesan lalu tawaran Input Manual |
| **Detail Produk** | Konfirmasi produk dan hitung natrium | Nama, merek, takaran saji, natrium per saji / per 100 g, hasil hitung | Isi jumlah porsi (atau gram jika hanya ada data per 100 g); `Simpan Konsumsi` | Produk terpilih, hasil hitung, status simpan | Setelah simpan → kembali ke Beranda |
| **Input Manual** | Fallback saat produk tidak ada, data natrium kosong, offline, atau API gagal | Form | Nama produk, natrium (mg, harus > 0); `Simpan Konsumsi` | Validasi form, status simpan | Setelah simpan → kembali ke Beranda |
| **Riwayat** | Melihat konsumsi lampau | Daftar per tanggal, total dan status per tanggal | Scroll | Riwayat (loading, kosong, data) dari Hive | ← kembali |

Halaman "Detail Konsumsi" dari Riwayat tidak ada di spesifikasi, jadi tidak perlu dibuat.

## 5. Reusable Widgets / Components

Reusable widget adalah komponen UI yang muncul di lebih dari satu tempat, sehingga tampilan dan perilakunya cukup ditulis sekali.

**[Rekomendasi struktur]** Kandidat yang benar-benar muncul berulang di SodiScan:

```text
presentation/widgets/
  risk_status_badge.dart     Beranda + Riwayat (per tanggal)
  sodium_summary_card.dart   Beranda + header grup tanggal di Riwayat
  consumption_tile.dart      daftar konsumsi di Beranda + Riwayat
  primary_button.dart        "Simpan Konsumsi", "Pindai Barcode", "Input Manual"
  empty_state.dart           Beranda kosong, Riwayat kosong
  error_state.dart           error pencarian produk, gagal memuat data
```

Catatan:

- `RiskStatusBadge` paling penting dibuat reusable karena warna hijau/oranye/merah harus konsisten di semua tempat. Widget ini hanya menampilkan status. Penentuan statusnya ada di domain.
- `ProductCard` tidak perlu dijadikan reusable. Informasi produk hanya tampil di Detail Produk.
- `AppTextField` baru layak dibuat kalau styling field di Input Manual dan Detail Produk memang sama. Kalau berbeda, pakai `TextFormField` langsung.
- Untuk loading, `CircularProgressIndicator` bawaan biasanya cukup. Wrapper khusus tidak diperlukan.

## 6. Routing

Routing mengatur perpindahan antar-screen.

**[Ditetapkan]** `Architecture.md` tidak mencantumkan package routing (misalnya `go_router`). Karena itu gunakan **`Navigator` bawaan Flutter** dan jangan menambah package routing.

Alur utama:

```text
Beranda
 ├─→ Pindai Barcode ─(produk ditemukan)→ Detail Produk ─(Simpan)→ Beranda
 │         └─(tidak ditemukan / offline / error)→ Input Manual ─(Simpan)→ Beranda
 ├─→ Input Manual ─(Simpan)→ Beranda
 └─→ Riwayat
```

**[Rekomendasi struktur]** Pilih salah satu cara:

- `Navigator.push(MaterialPageRoute(...))` langsung. Ini paling sederhana dan cukup untuk lima halaman. Data `Product` dikirim ke Detail Produk lewat constructor.
- Named routes di `MaterialApp(routes: ...)`, dengan konstanta nama route di `core/constants/`. Pilih cara ini kalau ingin daftar route terpusat. Folder `lib/routes/` tidak perlu dibuat karena tidak ada di struktur yang ditetapkan.

Setelah simpan, kembali ke Beranda dengan `Navigator.popUntil(context, (r) => r.isFirst)`. Beranda lalu memuat ulang ringkasan dari Provider.

## 7. Models

**Entity [Ditetapkan]** di `domain/entities/`, didefinisikan sekali saja:

| Entity | Field |
|---|---|
| `Product` | barcode, name, brand, servingSize, sodiumPer100gMg, sodiumPerServingMg |
| `FoodConsumption` | id, barcode, productName, sodiumMg, source, consumedAt |
| `DailyNutrition` | date, totalSodiumMg, dailyLimitMg, riskStatus |

`riskStatus` memiliki tiga nilai: `safe`, `nearLimit`, `danger`. **[Rekomendasi struktur]** Nilai ini dijadikan enum `RiskStatus` di domain. `source` (hasil scan atau manual) juga sebaiknya berupa enum. Nama enum-nya belum ditetapkan.

**Model [Rekomendasi nama file]** di `data/models/`:

```text
data/models/
  product_model.dart            parsing JSON Open Food Facts → Product
  food_consumption_model.dart   bentuk data di Hive ↔ FoodConsumption
```

Perbedaannya:

- **Model** mengurus bentuk data teknis: `fromJson`, konversi natrium gram × 1.000 → mg, dan adapter/serialisasi Hive. Model hanya dipakai di layer data.
- **Entity** mewakili konsep bisnis tanpa `import` Flutter, Hive, atau `http`. Entity dipakai di domain dan presentation.

**Tidak ada `daily_nutrition_model.dart`.** Menurut aturan yang ditetapkan, `DailyNutrition` tidak disimpan. Nilainya dihitung dari `FoodConsumption` pada tanggal yang sama, jadi entity-nya saja sudah cukup.

## 8. Services / Data Sources

SodiScan tidak memakai folder `services/` generik. Tidak ada `auth_service.dart` karena tidak ada autentikasi. Peran "service" dijalankan oleh data source.

**[Rekomendasi nama file]**

```text
data/datasources/
  remote/open_food_facts_remote_data_source.dart
  local/consumption_local_data_source.dart
```

**Remote data source [perilaku Ditetapkan]**

- Memanggil Open Food Facts API v2 berdasarkan barcode dengan package `http`.
- Batas waktu request 10 detik.
- Mengembalikan `ProductModel`, atau melempar error yang jelas: produk tidak ditemukan, data natrium kosong, tidak ada internet, atau API gagal. Tipe error sebaiknya ada di `core/errors/`.
- Hanya membaca dari API. Data konsumsi pengguna tidak pernah dikirim.

**Local data source [perilaku Ditetapkan]**

- Satu-satunya tempat yang menyentuh Hive box `consumptions`.
- Operasinya: simpan konsumsi, ambil konsumsi per tanggal, ambil semua konsumsi untuk riwayat.
- Menyimpan `productName` dan `sodiumMg` langsung, supaya riwayat tetap tampil saat offline.

UI dan Provider tidak boleh memanggil kedua data source ini secara langsung.

## 9. Repository

Repository menjadi perantara antara domain dan data. Domain hanya mengenal kontraknya dan tidak tahu datanya berasal dari HTTP atau Hive.

**[Rekomendasi nama file]**

```text
domain/repositories/
  product_repository.dart          contoh: getProductByBarcode(barcode)
  consumption_repository.dart      contoh: save, getByDate, getAll

data/repositories/
  product_repository_impl.dart     → remote data source
  consumption_repository_impl.dart → local data source
```

Alurnya:

```text
Provider → Use Case → Repository (interface, domain)
                         ↓ diimplementasikan oleh
                     RepositoryImpl (data) → Remote / Local Data Source
```

**[Ditetapkan]** Repository mengubah model menjadi entity sebelum mengembalikannya ke use case. Repository juga bisa menerjemahkan exception teknis (misalnya `SocketException` atau `TimeoutException`) menjadi failure dari `core/errors/` yang dimengerti domain dan UI.

## 10. Use Cases

**[Ditetapkan]** Hanya empat use case yang dibutuhkan:

```text
domain/usecases/
  get_product_by_barcode.dart     GetProductByBarcode
  record_consumption.dart         RecordConsumption
  get_daily_summary.dart          GetDailySummary
  get_consumption_history.dart    GetConsumptionHistory
```

Nama class ditetapkan. Nama file mengikuti konvensi snake_case dan termasuk **Rekomendasi struktur**.

| Use case | Tanggung jawab |
|---|---|
| `GetProductByBarcode` | Validasi barcode, lalu minta `Product` dari `ProductRepository` |
| `RecordConsumption` | Validasi natrium > 0, lalu simpan `FoodConsumption`. Hasil scan dan input manual lewat use case yang sama |
| `GetDailySummary` | Ambil konsumsi untuk satu tanggal, jumlahkan, lalu hasilkan `DailyNutrition` beserta `riskStatus` |
| `GetConsumptionHistory` | Ambil konsumsi dan kelompokkan per tanggal, lengkap dengan total dan status |

Beberapa use case yang tidak perlu dibuat:

- **`scan_product`**: memindai adalah urusan kamera dan UI (`mobile_scanner`). Hasil scan cukup diteruskan ke `GetProductByBarcode`.
- **`calculate_risk_status`** sebagai use case terpisah: aturan ambangnya (≤ 1.500 aman, ≤ 2.000 mendekati batas, > 2.000 bahaya) memang wajib ada di domain. **[Rekomendasi struktur]** Letakkan sebagai fungsi atau logika murni di domain, misalnya di `DailyNutrition` atau helper domain, lalu pakai di `GetDailySummary` dan `GetConsumptionHistory`. Hal yang sama berlaku untuk perhitungan natrium dari porsi/gram. Keduanya menjadi sasaran unit test.

Alur mencatat konsumsi:

```text
RecordConsumption
  ↓ validasi sodiumMg > 0
  ↓ ConsumptionRepository.save()  → Hive
Provider lalu memanggil GetDailySummary
  ↓ total dihitung ulang dari data hari ini
  ↓ riskStatus ditentukan oleh aturan domain
```

"Update daily total" tidak berarti menyimpan total ke Hive. Total selalu dihitung ulang.

## 11. State Management

**[Ditetapkan]** Menggunakan **Provider**.

```text
Screen ──(context.watch / read)──→ Provider (ChangeNotifier)
                                        ↓
                                    Use Case → Repository → Data Source
```

**[Rekomendasi struktur]** Cukup tiga provider yang dibagi per kebutuhan halaman:

```text
presentation/providers/
  product_lookup_provider.dart   pencarian produk untuk halaman scan: idle, loading, found, error
  daily_summary_provider.dart    DailyNutrition + konsumsi hari ini, serta aksi simpan konsumsi
  history_provider.dart          riwayat per tanggal: loading, empty, data, error
```

State yang ditangani meliputi loading, success/data, empty, error (dengan pesan Bahasa Indonesia), produk hasil scan, ringkasan natrium harian, dan riwayat.

Provider hanya boleh memanggil use case. Provider tidak mengimpor `http`, Hive, atau model data.

## 12. API Flow

```text
Pindai Barcode (mobile_scanner mendeteksi kode)
 ↓ hentikan deteksi berikutnya
ProductLookupProvider → state loading
 ↓
GetProductByBarcode → validasi barcode
 ↓
ProductRepository (interface) → ProductRepositoryImpl
 ↓
Remote Data Source → HTTP GET Open Food Facts API v2 (timeout 10 detik)
 ↓
JSON → ProductModel (natrium g × 1.000 = mg)
 ↓
Product (entity)
 ↓
Provider → state found → Navigator ke Detail Produk
```

Jalur gagal: produk tidak ditemukan, natrium kosong, offline, timeout, atau API error. Repository mengembalikan failure, Provider mengubahnya menjadi pesan yang jelas, lalu UI menawarkan tombol **Input Manual**.

## 13. Local Data Flow

**Menyimpan** (dari Detail Produk maupun Input Manual):

```text
Pengguna tap "Simpan Konsumsi"
 ↓
DailySummaryProvider
 ↓
RecordConsumption (validasi natrium > 0)
 ↓
ConsumptionRepository → ConsumptionRepositoryImpl
 ↓
FoodConsumption → FoodConsumptionModel
 ↓
Local Data Source → Hive box "consumptions"
```

**Menampilkan kembali** (Beranda dan Riwayat, juga saat offline atau setelah aplikasi dibuka ulang):

```text
Hive box "consumptions"
 ↓
Local Data Source → FoodConsumptionModel
 ↓
Repository → FoodConsumption (entity)
 ↓
GetDailySummary / GetConsumptionHistory (hitung total + riskStatus)
 ↓
DailySummaryProvider / HistoryProvider
 ↓
Beranda / Riwayat
```

## 14. Relation Between Prototype and Implementation

```text
Prototype (wireframe / Figma / UI dummy)
   ↓ menentukan isi dan alur 5 halaman
Flutter Screens            (presentation/screens)
   ↓ elemen yang berulang diekstrak
Reusable Widgets           (presentation/widgets)
   ↓ data dummy diganti state
Provider                   (presentation/providers)
   ↓
Use Case + Entity          (domain)   ← aturan natrium dan status risiko
   ↓
Repository + Data Source   (data)     ← Open Food Facts API dan Hive
```

Prototype bukan arsitektur. Prototype menjawab pertanyaan *apa yang dilihat dan dilakukan pengguna*. Struktur project menjawab *di mana kode yang mewujudkannya ditulis*.

Contoh: badge "Mendekati Batas" berwarna oranye di prototype.

- Warna dan bentuknya diwujudkan oleh `RiskStatusBadge` di presentation.
- Keputusan kapan statusnya "Mendekati Batas" (> 1.500 mg dan ≤ 2.000 mg) ada di domain, bukan di widget.

## 15. Recommended SodiScan Structure

**[Rekomendasi struktur]** Susunan ini mengikuti kerangka folder yang **[Ditetapkan]** di `Architecture.md`. Nama file di dalamnya adalah usulan, kecuali nama class use case dan entity.

```text
lib/
├── main.dart                         init Hive, rakit dependency, runApp
├── app.dart                          (opsional) MaterialApp, theme, routes, MultiProvider
│
├── core/
│   ├── constants/                    batas 2.000 mg, ambang 1.500 mg, URL API, timeout, warna status
│   ├── errors/                       failure: not found, natrium kosong, offline, server
│   └── utils/                        format tanggal/angka
│
├── data/
│   ├── datasources/
│   │   ├── remote/                   open_food_facts_remote_data_source.dart
│   │   └── local/                    consumption_local_data_source.dart (box "consumptions")
│   ├── models/                       product_model.dart, food_consumption_model.dart
│   └── repositories/                 product_repository_impl.dart, consumption_repository_impl.dart
│
├── domain/
│   ├── entities/                     product.dart, food_consumption.dart, daily_nutrition.dart (+ enum RiskStatus)
│   ├── repositories/                 product_repository.dart, consumption_repository.dart
│   └── usecases/                     get_product_by_barcode.dart, record_consumption.dart,
│                                     get_daily_summary.dart, get_consumption_history.dart
│
└── presentation/
    ├── providers/                    product_lookup_provider.dart, daily_summary_provider.dart, history_provider.dart
    ├── screens/                      home/, scanner/, product_detail/, manual_input/, history/
    └── widgets/                      risk_status_badge.dart, sodium_summary_card.dart, consumption_tile.dart,
                                      primary_button.dart, empty_state.dart, error_state.dart

test/
└── domain/                           unit test perhitungan natrium dan status risiko (deliverable)
```

Batasan yang tetap berlaku: tanpa backend, autentikasi, Firebase, cloud database, cloud sync, atau package routing tambahan. UI dan Provider juga tidak boleh mengakses API atau Hive secara langsung.