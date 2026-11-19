# Pertemuan 10 — Release Candidate

Tujuan: menyiapkan SodiScan sebagai **release candidate** (`1.0.0-rc.1`), yaitu versi yang sudah siap diuji di HP sungguhan:

1. **Sistem log saat aplikasi berjalan**, agar masalah di mode release bisa ditelusuri.
2. **File APK release** yang bisa langsung dipasang.
3. **Persiapan rilis ke Play Store**: signing, App Bundle (`.aab`), dan langkah unggah.

---

## 1. Sistem Log

### Arsitektur

```text
 Kode aplikasi ── AppLog.i / w / e ──┬──► Konsol (debugPrint)  → flutter logs / adb logcat
                                     └──► LogStore
                                           ├── HiveLogStore     (aplikasi: tersimpan di HP, maks. 500 baris)
                                           └── InMemoryLogStore (test)
                                                  │
                                    Pengaturan ► Log Aplikasi (lihat, filter, salin, hapus)
```

| File | Tanggung jawab |
|---|---|
| [core/logging/log_entry.dart](../lib/core/logging/log_entry.dart) | Model `LogEntry` (waktu, level, tag, pesan, error, stack trace), konversi ke/dari Map, format satu baris |
| [core/logging/log_store.dart](../lib/core/logging/log_store.dart) | Interface `LogStore` + `InMemoryLogStore` (batas jumlah baris) |
| [core/logging/app_log.dart](../lib/core/logging/app_log.dart) | Logger `AppLog` dengan level `DEBUG < INFO < WARN < ERROR`. Di **release** hanya `INFO` ke atas yang dicatat. Logging tidak pernah membuat aplikasi crash |
| [core/logging/error_reporting.dart](../lib/core/logging/error_reporting.dart) | Menangkap error yang tidak tertangani: `FlutterError.onError` (error widget/framework) dan `PlatformDispatcher.onError` (error async) |
| [core/logging/log_observers.dart](../lib/core/logging/log_observers.dart) | `LogNavigatorObserver` (halaman yang dibuka/ditutup) dan listener siklus hidup aplikasi (`resumed`, `paused`, …) |
| [data/datasources/local/hive_log_store.dart](../lib/data/datasources/local/hive_log_store.dart) | Menyimpan log ke Hive box `app_logs`, jadi log **tetap ada setelah aplikasi ditutup atau crash** |
| [data/services/logging_http_client.dart](../lib/data/services/logging_http_client.dart) | Membungkus `http.Client`: mencatat method, URL, status, dan durasi setiap request. **Isi body tidak dicatat** |
| [presentation/screens/logs/log_screen.dart](../lib/presentation/screens/logs/log_screen.dart) | Layar **Log Aplikasi**: daftar log terbaru di atas, filter level, salin ke clipboard, hapus dengan konfirmasi, empty state |

### Apa saja yang dicatat

| Tag | Contoh log | Sumber |
|---|---|---|
| `App` | `SodiScan dimulai (mode: release, platform: android, API: http://10.0.2.2:8080)` | [main.dart](../lib/main.dart) |
| `Lifecycle` | `resumed`, `inactive`, `paused` | `createLifecycleLogger()` |
| `Navigasi` | `buka /settings (dari /)`, `tutup /scanner (kembali ke /)` | `LogNavigatorObserver` + nama route di setiap layar |
| `HTTP` | `GET https://world.openfoodfacts.org/... -> 200 (412 ms)`, `PUT .../api/consumptions/x gagal (10003 ms)` | `LoggingHttpClient` |
| `Repository` | `ERROR Gagal menyimpan data konsumsi (penyimpanan lokal)`, `WARN Gagal memuat data dari server (jaringan)` | [repository_guard.dart](../lib/data/repositories/repository_guard.dart) |
| `Konsumsi` | `Simpan berhasil`, `Hapus konsumsi abc gagal`, `Notifikasi natrium dikirim (danger)` | `AddConsumptionNotifier` |
| `Produk` | `Cari barcode 089686010947`, `Hasil barcode 089686010947: empty` | `ProductLookupNotifier` |
| `Sinkronisasi` | `Mulai upload`, `upload selesai: 3 catatan dikirim ke server.` | `ServerSyncNotifier` |
| `KunciAplikasi` | `Hasil autentikasi: cancelled` | `AppLockNotifier` |
| `FlutterError` / `Uncaught` | error tak tertangani + stack trace | `installErrorReporting()` |

Privasi: log hanya berisi aksi, ID, status, dan pesan error. Nama makanan dan isi body request tidak dicatat.

### Cara membaca log saat aplikasi berjalan

**a. Di HP (tanpa kabel):** buka **Pengaturan → Log Aplikasi**. Pilih filter `≥ WARN` atau `≥ ERROR` untuk melihat masalah saja, lalu tekan ikon **Salin** untuk mengirim log ke pengembang.

**b. Dari komputer (HP terhubung USB / emulator):**

```bash
flutter logs
```

atau, untuk APK release:

```bash
adb logcat -s flutter
```

Setiap baris diawali `[SodiScan]`, contohnya:

```text
I/flutter: [SodiScan] 2026-11-20T09:15:02.114 [INFO] Navigasi: buka /product-lookup (dari /)
I/flutter: [SodiScan] 2026-11-20T09:15:02.530 [INFO] HTTP: GET https://world.openfoodfacts.org/api/v2/product/089686010947.json -> 200 (402 ms)
I/flutter: [SodiScan] 2026-11-20T09:15:09.871 [WARN] HTTP: PUT http://10.0.2.2:8080/api/consumptions/abc gagal (10004 ms) | TimeoutException after 0:00:10.000000
I/flutter: [SodiScan] 2026-11-20T09:15:09.872 [WARN] Repository: Gagal menyimpan data ke server (jaringan) | TimeoutException ...
```

---

## 2. Menyiapkan APK

### Konfigurasi release

| Perubahan | File |
|---|---|
| Versi `1.0.0-rc.1+2` (versionName `1.0.0-rc.1`, versionCode `2`) | [pubspec.yaml](../pubspec.yaml) |
| Nama aplikasi di launcher menjadi `SodiScan` | [AndroidManifest.xml](../android/app/src/main/AndroidManifest.xml) |
| Signing release dari `android/key.properties`. Kalau file itu belum ada, build tetap jalan memakai kunci debug (untuk uji coba) | [build.gradle.kts](../android/app/build.gradle.kts) |
| R8 aktif (`isMinifyEnabled`, `isShrinkResources`) agar APK lebih kecil | [build.gradle.kts](../android/app/build.gradle.kts), [proguard-rules.pro](../android/app/proguard-rules.pro) |

`key.properties`, `*.jks`, dan `*.keystore` sudah ada di [android/.gitignore](../android/.gitignore), jadi kunci rilis tidak ikut ter-commit.

### Build APK

```bash
flutter build apk --release
```

Hasil: `build/app/outputs/flutter-apk/app-release.apk`. Pasang ke HP lewat `adb install build/app/outputs/flutter-apk/app-release.apk` atau salin file APK ke HP.

Untuk APK yang lebih kecil per arsitektur HP:

```bash
flutter build apk --release --split-per-abi
```

**Alamat server sinkronisasi.** Bawaannya `http://10.0.2.2:8080`, yang hanya bisa diakses dari emulator. Untuk HP sungguhan, isi IP komputer yang menjalankan `server/`:

```bash
flutter build apk --release --dart-define=API_BASE_URL=http://192.168.1.10:8080
```

Fitur utama (scan, catat, riwayat, notifikasi, kunci aplikasi) tetap berjalan tanpa server.

### Membuat kunci rilis (sekali saja)

Kunci ini wajib dipakai untuk Play Store dan **tidak boleh hilang**, karena update aplikasi harus ditandatangani dengan kunci yang sama.

```bash
keytool -genkey -v -keystore %USERPROFILE%\sodiscan-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Buat `android/key.properties`:

```properties
storePassword=<password keystore>
keyPassword=<password key>
keyAlias=upload
storeFile=C:\\Users\\<nama>\\sodiscan-upload.jks
```

Setelah itu `flutter build apk --release` otomatis memakai kunci rilis.

### Masalah build: `Unable to establish loopback connection`

Di beberapa PC Windows, Gradle (JDK 21) gagal dengan error ini karena socket internal JDK tidak bisa dibuat di folder temp. Solusinya, arahkan folder socket ke path **tanpa spasi** sebelum build:

```powershell
$env:JAVA_TOOL_OPTIONS = "-Djdk.net.unixdomain.tmpdir=$env:USERPROFILE\.gradle\uds"
```

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.gradle\uds"
```

---

## 3. Rilis ke Play Store

1. Buat kunci rilis dan `key.properties` (lihat di atas).
2. Ganti `applicationId` di [build.gradle.kts](../android/app/build.gradle.kts) jika perlu. ID ini **tidak bisa diubah** setelah aplikasi terbit.
3. Build App Bundle, format yang diminta Play Store:
   ```bash
   flutter build appbundle --release --dart-define=API_BASE_URL=https://<server-publik>
   ```
   Hasil: `build/app/outputs/bundle/release/app-release.aab`.
4. Di [Google Play Console](https://play.google.com/console): **Create app** → isi nama, bahasa, gratis/berbayar.
5. Lengkapi **App content**: kebijakan privasi (SodiScan menyimpan data konsumsi di perangkat dan, jika pengguna memilih, mengirimnya ke server), Data safety, rating konten, target usia.
6. Siapkan **Store listing**: ikon 512×512, feature graphic 1024×500, minimal 2 screenshot (bisa dari `docs/screenshots/`), deskripsi singkat dan lengkap.
7. **Testing → Internal testing** → buat rilis → unggah `app-release.aab` → tambahkan email penguji → **Review release** → **Start rollout**.
8. Setelah lolos uji internal/tertutup, promosikan ke **Production**.

Catatan untuk produksi: server SodiScan harus memakai HTTPS di alamat publik. `android:usesCleartextTraffic="true"` saat ini dipakai untuk server lokal (`http://`) dan sebaiknya dimatikan ketika server sudah HTTPS.

---

## Test Baru

| Test | Isi |
|---|---|
| [app_log_test.dart](../test/core/logging/app_log_test.dart) | Log masuk ke store dan konsol, filter `minLevel` (mode release), error dan stack trace tersimpan, store rusak tidak membuat crash, batas jumlah log, `LogEntry` toMap/tryFromMap, data rusak → `null` |
| [hive_log_store_test.dart](../test/data/hive_log_store_test.dart) | Log **tetap ada setelah aplikasi ditutup dan dibuka lagi**, hanya log terbaru yang disimpan, baris rusak dilewati, hapus semua |
| [logging_http_client_test.dart](../test/data/logging_http_client_test.dart) | Request sukses → `INFO`, status ≥ 400 → `WARN`, error koneksi dicatat lalu diteruskan, isi body tidak dicatat |
| [repository_guard_test.dart](../test/data/repository_guard_test.dart) | (ditambah) error lokal dicatat `ERROR`, error jaringan `WARN`, operasi sukses tidak menghasilkan log |
| [log_screen_test.dart](../test/presentation/screens/logs/log_screen_test.dart) | Empty state, urutan terbaru di atas, filter level, salin ke clipboard + feedback, hapus dengan konfirmasi, batal hapus |

Total `flutter test`: **204 test lulus** (180 sebelumnya + 24 baru). `flutter analyze`: tidak ada masalah. Output test: [test-output.txt](screenshots/pertemuan10/test-output.txt)

## Cara Cek (Reviewer)

```bash
flutter test
```

```bash
flutter build apk --release
```

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

```bash
adb logcat -s flutter
```

Lalu buka aplikasi, lakukan beberapa aksi (cari barcode, simpan, sinkronisasi saat server mati), dan cek **Pengaturan → Log Aplikasi**.
