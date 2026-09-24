# Architecture
Bangun sebuah aplikasi mobile sederhana bernama **SodiScan**.
 
## Tujuan
Membantu pengguna memantau konsumsi natrium harian dari makanan kemasan. Pengguna memindai barcode produk, aplikasi mengambil data produk dari Open Food Facts, lalu pengguna mencatat konsumsinya. Aplikasi menjumlahkan natrium harian, membandingkannya dengan batas 2.000 mg/hari, dan menampilkan status risiko. Semua data disimpan secara lokal di perangkat.
 
## Gunakan stack berikut
* Mobile: Flutter + Dart
* State management: Provider
* Penyimpanan lokal: Hive + hive_flutter
* Barcode scanner: mobile_scanner
* HTTP client: http
* Sumber data produk: Open Food Facts REST API (read-only)
* Arsitektur: Clean Architecture + Local-First + Repository Pattern
* Tidak ada backend, cloud database, Firebase, maupun cloud sync
## Aturan kode
* Jangan menambahkan komentar kecuali benar-benar diperlukan.
* Gunakan PascalCase untuk class, entity, model, enum, widget, dan provider.
* Gunakan camelCase untuk variable, function, parameter, dan field class.
* Usahakan panjang baris kode di bawah 150 karakter.
* Gunakan struktur folder yang bersih dan sederhana.
* Widget tidak boleh melakukan HTTP request atau mengakses Hive secara langsung.
* Tidak ada autentikasi. Asumsikan satu pengguna per perangkat.
## Entity utama
1. Product
   * barcode
   * name
   * brand
   * servingSize
   * sodiumPer100gMg
   * sodiumPerServingMg
2. FoodConsumption
   * id
   * barcode
   * productName
   * sodiumMg
   * source
   * consumedAt
3. DailyNutrition
   * date
   * totalSodiumMg
   * dailyLimitMg
   * riskStatus
## Aturan penyimpanan
* Simpan FoodConsumption di Hive box `consumptions`.
* Semua nilai natrium disimpan dalam satuan mg.
* DailyNutrition tidak disimpan, tetapi dihitung dari FoodConsumption pada tanggal yang sama.
* FoodConsumption menyimpan nama produk dan nilai natrium agar riwayat tetap tampil saat offline.
* Data konsumsi tidak pernah dikirim ke server mana pun.
* Hive hanya boleh diakses melalui repository dan local data source.
## Fitur aplikasi
1. Pindai Barcode
   * Pindai barcode produk menggunakan kamera melalui `mobile_scanner`.
   * Validasi barcode sebelum mencari produk.
   * Hentikan deteksi berikutnya selama pencarian produk berjalan.
2. Pencarian Produk
   * Ambil data produk dari Open Food Facts API v2 berdasarkan barcode.
   * Nilai natrium dari Open Food Facts dalam gram, kalikan 1.000 untuk mengubahnya ke mg.
   * Beri batas waktu request 10 detik.
   * Jika produk tidak ditemukan, data natrium kosong, tidak ada internet, atau API gagal, tampilkan pesan yang jelas dan arahkan ke Input Manual.
3. Pencatatan Konsumsi
   * Pengguna mengisi jumlah porsi, atau berat dalam gram jika hanya tersedia data per 100 g.
   * Tampilkan hasil perhitungan natrium sebelum disimpan.
   * Hasil scan dan input manual disimpan melalui use case yang sama.
4. Input Manual
   * Pengguna memasukkan nama produk dan jumlah natrium dalam mg.
   * Natrium harus berupa angka lebih dari 0.
   * Tetap dapat digunakan saat offline.
5. Monitoring Harian
   * Batas natrium harian: 2.000 mg.
   * Status risiko:
     * `safe` (Aman): total ≤ 1.500 mg
     * `nearLimit` (Mendekati Batas): total > 1.500 mg dan ≤ 2.000 mg
     * `danger` (Bahaya): total > 2.000 mg
   * Hitung ulang total dan status setiap kali konsumsi disimpan.
   * Aturan ini berada di domain layer, bukan di UI.
6. Riwayat Konsumsi
   * Tampilkan daftar konsumsi per tanggal beserta natriumnya.
   * Riwayat dibaca dari Hive dan tetap tersedia saat offline.
## Halaman aplikasi
1. Beranda
   * Total natrium hari ini dan batas 2.000 mg.
   * Badge status risiko.
   * Daftar konsumsi hari ini.
   * Tombol: `Pindai Barcode` dan `Input Manual`.
   * Hanya membaca data lokal, tidak memanggil API.
2. Pindai Barcode
   * Preview kamera.
   * Loading saat mencari produk.
   * Tombol: `Input Manual`.
3. Detail Produk
   * Nama produk, merek, takaran saji, dan kandungan natrium.
   * Field jumlah porsi atau berat.
   * Tombol: `Simpan Konsumsi`.
4. Input Manual
   * Form nama produk dan jumlah natrium (mg).
   * Tombol: `Simpan Konsumsi`.
5. Riwayat
   * Daftar konsumsi per tanggal.
   * Total natrium dan status risiko per tanggal.
## Kebutuhan UI
* Gunakan Bahasa Indonesia untuk semua label, tombol, pesan, dan validasi.
* Buat tampilan yang bersih, sederhana, dan responsif.
* Gunakan kartu, badge, form, dan empty state.
* Tampilkan state loading, kosong, dan error.
* Warna badge status:
  * Aman: hijau
  * Mendekati Batas: oranye
  * Bahaya: merah
* Tidak menggunakan chart pada versi pertama.
## Use case yang dibutuhkan
* `GetProductByBarcode`
* `RecordConsumption`
* `GetDailySummary`
* `GetConsumptionHistory`
## Deliverables
* Source code aplikasi Flutter lengkap.
* Konfigurasi izin kamera dan internet untuk Android dan iOS.
* Unit test untuk perhitungan natrium dan status risiko.
* README berisi cara instalasi, menjalankan aplikasi, dan menjalankan test.
* Pastikan aplikasi berhasil di-build dan fitur scan, pencarian produk, input manual, monitoring harian, serta riwayat berjalan dengan baik.
## Struktur project
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
 
## Aturan model
* Entity didefinisikan sekali di `domain/entities/`.
* Domain tidak boleh bergantung pada Flutter, Hive, atau package `http`.
* Model data untuk JSON dan Hive berada di `data/models/`.
* Repository mengubah model data menjadi entity sebelum dikembalikan ke use case.
* Presentation layer tidak boleh mengimpor model data, JSON, atau Hive.
