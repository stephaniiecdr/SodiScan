# Pertemuan 9 — Test dan Refactor (Hindari Duplikasi Kode)

Tujuan: menghapus kode yang ditulis berulang dan memisahkan tanggung jawab menjadi fungsi-fungsi kecil yang fokus pada satu pekerjaan. Perilaku aplikasi **tidak berubah**: semua test lama tetap lulus.

## Pemisahan Tanggung Jawab

Pola di instruksi (`ProfileForm` / `validation` / `profileRepository`) diterapkan di SodiScan seperti ini:

| Lapisan | Tanggung jawab | Lokasi di SodiScan |
|---|---|---|
| **Form** | Input dan status UI saja (field, fokus, tombol loading, pesan error, feedback) | [consumption_form.dart](../lib/presentation/screens/add_consumption/consumption_form.dart), [portion_form.dart](../lib/presentation/screens/product_lookup/portion_form.dart), [barcode_search_form.dart](../lib/presentation/screens/product_lookup/barcode_search_form.dart) |
| **Validation** | Aturan input: wajib diisi, harus angka, harus > 0, batas maksimal, format barcode | [lib/domain/validation/](../lib/domain/validation/) — `input_rules.dart`, `consumption_rules.dart`, `product_rules.dart` |
| **Notifier** | Status proses (loading, sukses, error) dan pemanggilan use case | [lib/presentation/providers/](../lib/presentation/providers/) + `base_notifier.dart` |
| **Repository** | Request API / penyimpanan lokal dan pengubahan error menjadi `Failure` | [lib/data/repositories/](../lib/data/repositories/) + `repository_guard.dart` |

## Alur Kerja

Setiap bagian dikerjakan dengan alur dari instruksi: **1 Tes awal lulus → 2 Pindahkan satu bagian → 3 Tes ulang → 4 Commit**. Di akhir, seluruh langkah digabung menjadi satu commit `refactor(p9)`.

| # | Bagian yang dipindahkan | Duplikasi sebelumnya | Hasil | Tes ulang |
|---|---|---|---|---|
| 0 | — (tes awal) | — | — | 164 lulus |
| 1 | Aturan input → `lib/domain/validation/` | Pesan & cek "wajib diisi / harus angka / harus > 0" ditulis di 2 file validator form **dan** di use case `RecordConsumption`. Pola barcode ada di use case dan validator | Satu sumber aturan, dipakai form, scanner, dan use case. `validatePositiveNumber` dipakai untuk sodium dan porsi | 164 lulus |
| 2 | Widget form → `widgets/form_feedback.dart` | Tombol simpan + spinner "Menyimpan..." ditulis 2×, spinner kecil 4×, teks error 2×, getar + SnackBar sukses 2× | `SubmitButton`, `ButtonSpinner`, `FormErrorText`, `showSuccessFeedback`. `_submit` di `ConsumptionForm` dipecah menjadi `_save` dan `_onSaved` | 164 lulus |
| 3 | Dasar notifier → `providers/base_notifier.dart` | `_isDisposed` + `_emit` + `dispose()` diulang di **6 notifier**. Penanganan `ValidationFailure`/`Exception` saat simpan diulang di 2 notifier | `StateNotifier<T>`, mixin `SafeNotifier`, fungsi `runSubmit`. Hasil pencarian produk dipisah ke `_resultFor` | 164 lulus |
| 4 | Penanganan error repository → `repositories/repository_guard.dart` | `try/catch` → `StorageFailure` diulang **5×** di `ConsumptionRepositoryImpl`, plus salinan sendiri di repository sync, produk, dan pengaturan | `guardStorage` dan `guardRemote`. Repository hanya berisi request-nya | 164 lulus |
| 5 | Test untuk modul bersama yang baru | — | 16 test baru | **180 lulus** |

## Sebelum dan Sesudah

**Repository** — sebelum, setiap method punya `try/catch` sendiri:

```dart
Future<void> saveConsumption(FoodConsumption consumption) async {
  try {
    await _localDataSource.save(FoodConsumptionModel.fromEntity(consumption));
  } catch (error) {
    throw StorageFailure('Gagal menyimpan data konsumsi: $error');
  }
}
// ...diulang untuk read, readAll, update, delete
```

Sesudah, repository hanya menjelaskan aksinya:

```dart
Future<void> saveConsumption(FoodConsumption consumption) {
  return guardStorage('menyimpan data konsumsi', () => _write(consumption));
}
```

**Notifier**: sebelumnya 6 notifier menyalin blok yang sama:

```dart
bool _isDisposed = false;
void _emit(State s) { if (_isDisposed) return; _state = s; notifyListeners(); }
@override void dispose() { _isDisposed = true; super.dispose(); }
```

Sesudahnya cukup `class HistoryNotifier extends StateNotifier<HistoryState>`, lalu panggil `emit(...)`.

**Form**: sebelumnya tombol simpan ditulis 15 baris di tiap form. Sesudahnya:

```dart
SubmitButton(
  buttonKey: const Key('submitButton'),
  label: 'Simpan Konsumsi',
  isSubmitting: isSubmitting,
  onPressed: _submit,
)
```

## Test Baru

| Test | Isi |
|---|---|
| [consumption_rules_test.dart](../test/domain/validation/consumption_rules_test.dart) | (dipindah dari `test/presentation/validators/`) batas sodium, kosong, bukan angka, nama kosong |
| [product_rules_test.dart](../test/domain/validation/product_rules_test.dart) | `parseDecimal` (koma desimal), `validatePositiveNumber`, barcode 8–13 digit, label porsi/berat, use case memakai pesan yang sama dengan form |
| [base_notifier_test.dart](../test/presentation/providers/base_notifier_test.dart) | `emit` memberi tahu listener, `emit` setelah dispose aman, `runSubmit` sukses / validasi / error lain |
| [repository_guard_test.dart](../test/data/repository_guard_test.dart) | Error lokal → `StorageFailure`, `Failure` spesifik tidak dibungkus ulang, JSON rusak → `DataFormatFailure`, timeout/offline → `NetworkFailure` |

Output test: [test-output.txt](screenshots/pertemuan9/test-output.txt)

Total `flutter test`: **180 test lulus** (164 sebelum refactor + 16 baru). `flutter analyze`: tidak ada masalah.

## Cara Cek (Reviewer)

```bash
git show --stat HEAD
```

```bash
flutter test
```
