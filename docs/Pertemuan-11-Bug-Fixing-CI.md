# Pertemuan 11: Bug Fixing di `v1.0_dev`, Unit Test, dan CI (Auto Build → Deploy)

## 1. Alur branch

```
main ──► v1.0        (Release OK, dibekukan; hanya hotfix kritis)
           │
           └──► v1.0_dev   (tambah fitur / perbaiki bug, sedang dites)
                   │  push → GitHub Actions: analyze + 300 unit test
                   │        hijau → build APK → deploy pre-release (Live untuk tester)
                   │        merah → build & deploy DI-SKIP
                   ▼
                 v1.1        (rilis berikutnya setelah v1.0_dev stabil)
```

| Branch | Isi | Status |
|---|---|---|
| `v1.0` | Kode Release Candidate Pertemuan 10 (`daedd7e`) | Release OK |
| `v1.0_dev` | Perbaikan issue #1–#5 dan #11–#18 (termasuk 2 fitur baru) | Under testing |
| `v1.1` | Hasil merge `v1.0_dev` setelah semua test hijau | Rilis berikutnya |

## 2. Daftar issue (minimal 10, minimal 5 bug)

| # | Jenis | Judul singkat | Perbaikan (file utama) | Test |
|---|---|---|---|---|
| 1 | Bug | Upload berhenti tanpa laporan record yang gagal | `domain/usecases/sync_consumptions.dart` (`UploadConsumptions` lanjut ke record berikutnya dan mengembalikan `UploadReport`), `server_sync_notifier.dart` (pesan "2 dari 3 dikirim, 1 gagal (Sosis)") | `test/domain/sync_consumptions_test.dart`, `test/p11/p11_bug_fixes_test.dart` |
| 2 | Bug | Restore menimpa perubahan lokal yang lebih baru | Field baru `updatedAt` dan `lastModifiedAt` di `FoodConsumption`. `UpdateConsumption` mengisi `updatedAt`. `RestoreConsumptions` memakai kebijakan **last-modified-wins** dan mengembalikan `RestoreReport` | sama seperti di atas, ditambah `test/data/consumption_api_test.dart` |
| 3 | Bug | Porsi/berat ekstrem menghasilkan Infinity | `product_rules.dart` (maks 20 porsi / 5000 g), `Product.sodiumFor` menolak hasil tak hingga, `sodiumRangeError` memberi pesan "maksimal" untuk Infinity | `p11_bug_fixes_test.dart` |
| 4 | Bug | Hapus gagal tanpa pesan error | `AddConsumptionState.deleteErrorMessage` dan `deletingId`, penjaga double-delete di `AddConsumptionNotifier.delete`, `home_screen.dart` membaca pesan dari state | `p11_bug_fixes_test.dart`, `delete_consumption_test.dart` |
| 5 | Bug | Data server hilang dari ringkasan harian karena zona waktu | `FoodConsumptionModel.fromJson/fromMap` mengubah tanggal ke `toLocal()`, `toJson` mengirim UTC (`Z`), pengelompokan harian memakai waktu lokal | `consumption_api_test.dart`, `p11_bug_fixes_test.dart` |
| 11 | Bug | Satu catatan Hive rusak membuat seluruh riwayat gagal dimuat | `consumption_local_data_source.dart` melewati catatan rusak dan menulis log WARN | `p11_bug_fixes_test.dart` |
| 12 | Bug | Nama makanan tidak dibatasi panjangnya | `consumption_rules.dart` (maks 80 karakter, `clampProductName` untuk hasil scan) | `p11_bug_fixes_test.dart` |
| 13 | Bug | Server menerima nilai di luar batas aplikasi | `server/lib/api.dart` (sodium ≤ 10000, nama ≤ 80, `updatedAt` ISO 8601) | `server/test/api_test.dart` |
| 14 | Bug | Server crash pada file rusak dan lost update saat request bersamaan | `server/lib/consumption_store.dart` (`StoreCorruptedException` dan antrean penulisan), middleware 500 di `api.dart` | `server/test/api_test.dart` |
| 15 | CI/CD | Workflow GitHub Actions belum ada | `.github/workflows/ci.yml` | jalan di GitHub Actions |
| 16 | Fitur | Target natrium harian bisa diatur | `settings_repository.dart` (`dailyLimitMg`), `settings_rules.dart` (1000–3000 mg), `risk_status.dart` dan `daily_nutrition.dart` (batas dinamis, Mendekati Batas di atas 75%), `load_daily_limit.dart`, `settings_screen.dart` dan `daily_limit_dialog.dart` | `test/p11/p11_new_features_test.dart` |
| 17 | Fitur | Catat cepat makanan yang sering dimakan | `get_frequent_foods.dart`, `frequent_food.dart`, `AddConsumptionNotifier.quickAdd`, bagian "Catat Cepat" di `home_screen.dart` | `p11_new_features_test.dart` |
| 18 | Bug | Catatan yang dihapus muncul lagi setelah "Ambil ke HP" | Tombstone di `consumption_local_data_source.dart` (box `deleted_consumptions`), `deleteFromServer` dan `DELETE` di remote data source, `UploadConsumptions` mengirim penghapusan, `RestoreConsumptions` melewati catatan yang sudah dihapus | `p11_new_features_test.dart` |

Total ada 13 issue: 10 bug, 2 fitur, dan 1 CI/CD. Nomor #6–#10 tidak dipakai karena issue itu dibatalkan
(GitHub tidak memakai ulang nomor issue).

## 3. Unit test

| Paket | Sebelum P11 | Sesudah P11 |
|---|---|---|
| Aplikasi (`flutter test`) | 204 | 286 |
| Server (`dart test`, folder `server/`) | 4 | 14 |
| **Total** | 208 | **300** (semua lulus) |

Perintah:

```powershell
flutter analyze
flutter test
cd server; dart test; cd ..
```

## 4. Demo "unit test gagal, apa efeknya?"

File `test/p11/ci_gate_demo_test.dart` lulus dalam kondisi normal. Dengan flag `DEMO_FAIL`, test ini
mensimulasikan regresi (satu catatan tercatat dua kali), sehingga total natrium menjadi 1800, bukan 1050.

Lokal:

```powershell
flutter test --dart-define=DEMO_FAIL=true test/p11/ci_gate_demo_test.dart
```

Hasilnya `Expected: <1050> Actual: <1800.0>` dan `Some tests failed.` (exit code 1).

Di GitHub Actions: buka **Actions → CI → Run workflow**, pilih branch `v1.0_dev`, lalu centang `demo_fail`.

- Job **Analyze & Unit Test** menjadi merah ❌.
- Job **Build APK** dan **Deploy** berstatus *skipped*, karena `needs: test`.
- Efeknya: tidak ada APK baru dan versi "Live" untuk tester tetap build hijau terakhir. Bug tidak bisa lolos ke tester.

Jalankan ulang tanpa centang `demo_fail`. Semua job menjadi hijau ✅, lalu pre-release `v1.0_dev-build-N` berisi APK muncul di **Releases**.