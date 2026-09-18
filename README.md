# SodiScan
**SodiScan** adalah aplikasi *mobile* berbasis Flutter yang dirancang untuk membantu pengguna memantau dan membatasi asupan natrium (garam) harian dari makanan kemasan melalui pemindaian *barcode*.

---

## Deskripsi Masalah

Banyak produk makanan kemasan mengandung kadar natrium (garam) yang tinggi tanpa disadari oleh konsumen karena informasi nilai gizi sering kali sulit dibaca atau dipahami secara cepat saat berbelanja. Konsumsi natrium berlebih secara terus-menerus meningkatkan risiko kesehatan serius, seperti hipertensi dan penyakit ginjal. Saat ini, belum ada alat praktis yang dapat menghitung dan memperingatkan dampak natrium dari makanan kemasan secara cepat dan visual dalam kehidupan sehari-hari.

---

## Profil Target Pengguna

1. **Penderita Risiko Kesehatan Khusus:** Individu dengan hipertensi, gangguan fungsi ginjal, atau lansia yang diwajibkan oleh medis untuk mengontrol dan membatasi asupan natrium harian.
2. **Masyarakat Sadar Kesehatan (*Health-Conscious*):** Individu yang sedang menjalankan pola hidup sehat, diet rendah garam, atau menjaga kebugaran tubuh.
3. **Konsumen Makanan Kemasan:** Masyarakat umum dan mahasiswa yang sering mengonsumsi makanan instan/kemasan dan membutuhkan pemantau nutrisi praktis.

---

## Manfaat Utama Aplikasi

- **Deteksi Otomatis & Cepat:** Memudahkan pengguna mengetahui kadar natrium produk makanan kemasan hanya dengan memindai *barcode*.
- **Visualisasi Risiko Nutrisi:** Memberikan edukasi dan peringatan visual langsung (indikator warna Hijau/Kuning/Merah) berdasarkan ambang batas konsumsi harian dari WHO.
- **Pencegahan Risiko Hipertensi:** Mengontrol akumulasi natrium harian pengguna agar tidak melebihi batas aman.
- **Pencatatan Riwayat Mandiri:** Membantu pengguna mengevaluasi riwayat pola makan kemasan secara berkala.

---

## Daftar Fitur Inti

1. **Real-time Barcode Scanner:** Memindai kode batang (*barcode*) kemasan makanan menggunakan kamera *smartphone* (`mobile_scanner`).
2. **Integrasi Open Food Facts API:** Mengambil data nutrisi dan kadar natrium (*sodium*) produk secara otomatis melalui REST API.
3. **Kalkulator & Indikator Risiko Visual:** Menampilkan akumulasi konsumsi natrium harian serta indikator status keamanan (Hijau = Aman, Kuning = Mendekati Batas, Merah = Berbahaya/Melebihi Batas).
4. **Penyimpanan Log Riwayat Lokal:** Menyimpan riwayat makanan yang telah dikonsumsi dan progress statistik harian ke penyimpanan lokal (`Hive Database`).
5. **Input Manual (Fallback System):** Memungkinkan pengguna memasukkan nama makanan dan kadar natrium secara manual jika produk tidak terdaftar di API atau perangkat sedang *offline*.

---

## Fitur yang Tidak Dikerjakan

Untuk menjaga keberhasilan eksekusi dalam batas waktu 12 pertemuan, fitur-fitur berikut **tidak dimasukkan** ke dalam cakupan proyek:

- **Sistem Akun & Autentikasi User (Login/Register):** Aplikasi berfokus pada pendekatan *Local-First* tanpa *database cloud* server mandiri.
- **Sinkronisasi Multi-Device / Cloud Backup:** Data tersimpan murni di *local storage* HP masing-masing pengguna.
- **Pemindaian Nutrisi Lengkap (Kalori, Gula, Lemak):** Fokus aplikasi dispesifikkan khusus pada pemantauan *Sodium/Natrium*.
- **Fitur Rekomendasi Resep Makanan Sehat:** Aplikasi berfungsi sebagai alat *tracking* & deteksi, bukan pembuat jadwal diet/resep.

---

## Kriteria Aplikasi Dinyatakan Berhasil

Aplikasi **SodiScan** dinyatakan berhasil menyelesaikan target proyek apabila memenuhi kriteria berikut:

1. **Fungsi Scan Berjalan Akurat:** Kamera dapat membaca *barcode* produk kemasan dan berhasil mengambil data natrium dari Open Food Facts API dengan respon yang stabil.
2. **Kalkulasi & Indikator Berfungsi:** Sistem berhasil menghitung akumulasi natrium harian pengguna dan mengubah warna indikator secara dinamis sesuai batas aman harian.
3. **Persistensi Data Lokal Teruji:** Data riwayat makanan dan total natrium harian tidak hilang saat aplikasi ditutup dan dibuka kembali (berhasil tersimpan di `Hive`).
4. **Penanganan Kondisi Offline (*Graceful Fallback*):** Saat tidak ada koneksi internet, aplikasi tidak *crash* dan pengguna tetap bisa menginput data secara manual serta melihat riwayat lokal.

---

## Arsitektur Sistem

SodiScan menerapkan pola **Local-First Client Architecture with External Backend Service**:

- **Frontend (FE):** Dibangun menggunakan **Flutter Framework** dengan bahasa **Dart** (UI, Kamera Scanner, State Management, dan Kalkulasi Logika).
- **External Backend Service (REST API):** Menggunakan **Open Food Facts API** untuk *fetch* data nutrisi produk secara *real-time* (Akses internet bersifat *Read-Only* satu arah).
- **Local Database:** Menggunakan **Hive Database** (*NoSQL Key-Value Store*) untuk menyimpan riwayat konsumsi harian secara lokal di HP pengguna.

```text
┌─────────────────────────────────────────────────────────────────┐
│              FRONTEND (FE): FLUTTER APP (DART)                  │
│                                                                 │
│  [UI Layer]       ──> Dashboard, Camera Scanner, History Log    │
│  [Logic Layer]    ──> Sodium Calculation, Color Gauge Logic     │
│  [Data Layer]     ──> API Client & Hive Storage Handler         │
└─────────────────┬─────────────────────────────┬─────────────────┘
                  │                             │
                  ▼                             ▼
┌───────────────────────────────────┐ ┌───────────────────────────┐
│     EXTERNAL BACKEND SERVICE      │ │    LOCAL DATABASE (FE)    │
│     Open Food Facts REST API      │ │       Hive Database       │
│  (Pencarian Data Gizi & Barcode)  │ │ (Simpan Riwayat Konsumsi) │
└───────────────────────────────────┘ └───────────────────────────┘
