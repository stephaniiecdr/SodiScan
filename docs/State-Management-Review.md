# Panduan Reviewer: State Management SodiScan

SodiScan menerapkan state management dengan **Provider** (`ChangeNotifier`), sesuai `Architecture.md`, pada dua feature:

1. **Tambah Konsumsi** — detail di [`Add-Consumption-Feature.md`](Add-Consumption-Feature.md)
2. **Cari Produk via Barcode** — detail di [`Product-Lookup-Feature.md`](Product-Lookup-Feature.md)

## Posisi Kode State Management

| Bagian | Feature 1: Tambah Konsumsi | Feature 2: Cari Produk |
|---|---|---|
| State (immutable) | `lib/presentation/providers/add_consumption_state.dart` | `lib/presentation/providers/product_lookup_state.dart` |
| Notifier | `lib/presentation/providers/add_consumption_notifier.dart` | `lib/presentation/providers/product_lookup_notifier.dart` |
| Provider didaftarkan | `lib/app.dart` (`ChangeNotifierProvider` di `MultiProvider`) | `ProductLookupScreen.route()` di `product_lookup_screen.dart` (dibuat baru setiap layar dibuka) |
| Widget yang membaca state | `lib/presentation/screens/add_consumption/` | `lib/presentation/screens/product_lookup/` |
| Use case | `get_daily_summary.dart`, `record_consumption.dart` | `get_product_by_barcode.dart`, `record_consumption.dart` |
| Repository | `consumption_repository.dart` → `consumption_repository_impl.dart` (Hive) | `product_repository.dart` → `product_repository_impl.dart` (Open Food Facts) |
| Widget test | `test/presentation/screens/add_consumption/` | `test/presentation/screens/product_lookup/` |

## Alur Proses

```text
Widget ──context.watch──▶ Notifier.state       (UI dibangun ulang saat notifyListeners)
Widget ──context.read───▶ Notifier.load/search/retry/submit
Notifier ──▶ Use Case ──▶ Repository (kontrak domain) ──▶ RepositoryImpl ──▶ Hive / Open Food Facts
```

1. Widget hanya membaca state dan memanggil method notifier. Widget tidak memanggil repository, Hive, atau HTTP.
2. Notifier mengubah state (loading → success/empty/error, `isSubmitting`) lalu memanggil `notifyListeners()`.
3. Use case berisi aturan bisnis: validasi barcode, natrium > 0, total harian dan status risiko.
4. Repository menyembunyikan sumber data dan mengubah error teknis menjadi `Failure`.

## Enam Kondisi UI per Feature

| Kondisi | Tambah Konsumsi | Cari Produk |
|---|---|---|
| Initial loading | Memuat konsumsi hari ini dari Hive | Mencari produk ke Open Food Facts |
| Data berhasil dimuat | Total harian, badge risiko, daftar konsumsi | Kartu produk + form porsi |
| Empty state | `Belum Ada Data` | `Produk Tidak Ditemukan` / `Data Natrium Tidak Tersedia` |
| Error + retry | `Terjadi Kesalahan` + `Coba Lagi` → `retry()` | `Terjadi Kesalahan` + `Coba Lagi` → `retry()` |
| Validasi form | Nama makanan, jumlah sodium | Kode barcode, jumlah porsi/berat |
| Loading submit | `Menyimpan...`, tombol nonaktif | `Menyimpan...`, tombol simpan dan cari nonaktif |

## Pencegahan Double Tap

Ada dua lapis di kedua feature:

- **UI:** tombol memakai `onPressed: isSubmitting ? null : _submit`.
- **Notifier:** `submit()` langsung keluar jika `isSubmitting` sudah `true`.

Ini dibuktikan oleh widget test: submit kedua saat submit pertama masih berjalan tidak menambah jumlah penyimpanan (`saveCalls == 1`). Jika guard di notifier dihapus, test tersebut gagal.

## Cara Menjalankan

```bash
flutter pub get
flutter test
flutter run
```
