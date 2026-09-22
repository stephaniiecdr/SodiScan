# SodiScan
**Aplikasi Pemantau Asupan Natrium Harian dari Makanan Kemasan**
## 1. Deskripsi Masalah
Konsumsi natrium (sodium) berlebih merupakan salah satu kontributor utama penyakit tidak menular seperti hipertensi, stroke, dan penyakit kardiovaskular. Organisasi kesehatan dunia merekomendasikan batas asupan natrium harian sebesar **2.000 mg** (setara ±5 gram garam), namun batas ini sangat mudah terlampaui tanpa disadari.
 
Masalah utamanya terletak pada **natrium tersembunyi (hidden sodium)** di dalam makanan kemasan/olahan seperti mi instan, makanan ringan (snack), makanan kaleng, saus, dan produk siap saji. Kandungan natrium pada produk-produk ini sering kali:
 
- Tidak disadari konsumen karena rasa produk tidak selalu terasa "asin".
- Tertulis dalam satuan (mg) pada label gizi yang jarang dibaca atau sulit diinterpretasikan secara cepat oleh konsumen awam.
- Terakumulasi dari beberapa produk berbeda dalam satu hari tanpa ada mekanisme pencatatan yang praktis.
Akibatnya, banyak pengguna—terutama penderita hipertensi atau kelompok berisiko—tidak memiliki gambaran akurat mengenai total asupan natrium harian mereka, sehingga sulit melakukan kontrol pola makan secara proaktif.
 
SodiScan hadir untuk menjembatani kesenjangan ini dengan menyederhanakan proses pembacaan label gizi menjadi satu kali pindai (scan) barcode, lengkap dengan akumulasi otomatis terhadap batas aman harian.
 
---
 
## 2. Profil Target Pengguna
| Segmen Pengguna | Kebutuhan Utama |
|---|---|
| **Penderita Hipertensi** | Kontrol ketat asupan natrium sesuai anjuran dokter/ahli gizi |
| **Individu Sadar Kesehatan (Health-Conscious)** | Menjaga pola makan sehat dan preventif terhadap penyakit kardiovaskular |
| **Lansia dan Keluarga Pendamping** | Membantu memantau konsumsi garam anggota keluarga lanjut usia |
| **Individu dengan Riwayat Penyakit Ginjal** | Pembatasan natrium sebagai bagian dari terapi diet |
| **Pengguna Umum yang Sering Konsumsi Makanan Kemasan** | Edukasi dan kesadaran (awareness) terhadap kandungan gizi produk yang dikonsumsi |
 
---
 
## 3. Manfaat Aplikasi
- **Transparansi Instan** — Pengguna dapat mengetahui kandungan natrium suatu produk hanya dengan memindai barcode, tanpa perlu mencari dan menghitung manual dari label kemasan.
- **Kontrol Akumulatif Harian** — Aplikasi secara otomatis menjumlahkan total natrium yang telah dikonsumsi dalam satu hari dan membandingkannya dengan batas aman (2.000 mg).
- **Pengambilan Keputusan Lebih Baik** — Pengguna dapat memutuskan untuk menghindari atau membatasi produk tertentu sebelum dikonsumsi, bukan setelahnya.
- **Privasi Terjaga** — Karena bersifat *local-first*, seluruh riwayat konsumsi tersimpan hanya di perangkat pengguna tanpa perlu membuat akun atau mengirim data pribadi ke server pihak ketiga.
- **Akses Offline untuk Data Historis** — Riwayat yang sudah tersimpan tetap dapat diakses tanpa koneksi internet.

---
 
## 4. Daftar Fitur Inti
Fitur berikut dirancang agar realistis diselesaikan dalam **12 kali pertemuan (±12 minggu)**:
1. **Scan Barcode Produk**
   Menggunakan kamera smartphone untuk memindai barcode (EAN/UPC) pada kemasan produk.
2. **Pengambilan Data Nutrisi via Open Food Facts API**
   Mengirim kode barcode hasil scan ke Open Food Facts API dan menampilkan data nutrisi (khususnya kandungan natrium) secara real-time.
3. **Kalkulasi & Visualisasi Batas Harian (2.000 mg)**
   Menjumlahkan total natrium yang dikonsumsi dalam satu hari dan menampilkan progres (misalnya dalam bentuk progress bar) terhadap batas aman harian.
4. **Input Manual Produk**
   Opsi untuk menambahkan data konsumsi secara manual apabila barcode tidak ditemukan di database Open Food Facts.
5. **Penyimpanan Riwayat Konsumsi Lokal (Hive Database)**
   Menyimpan setiap entri konsumsi (nama produk, kandungan natrium, waktu, tanggal) ke penyimpanan lokal perangkat.
6. **Riwayat Harian & Kalender Sederhana**
   Menampilkan daftar riwayat konsumsi yang dikelompokkan per hari, dengan kemampuan melihat riwayat hari-hari sebelumnya.
7. **Notifikasi/Peringatan Ambang Batas**
   Memberikan indikator visual (misalnya warna kuning/merah) ketika akumulasi natrium harian mendekati atau melebihi 2.000 mg.
8. **Hapus/Edit Entri Konsumsi**
   Kemampuan dasar CRUD (khususnya *delete* dan *edit*) pada data konsumsi yang sudah tersimpan.
9. **Halaman Detail Produk**
   Menampilkan informasi tambahan produk hasil scan (nama, merek, foto produk jika tersedia dari API).

---
 
## 5. Fitur yang Tidak Dikerjakan (Out of Scope)
Untuk menjaga agar proyek tetap realistis diselesaikan dalam 12 pertemuan, fitur-fitur berikut **secara sengaja tidak dikerjakan** pada versi ini:
 
- **Sistem Login/Register & Manajemen Akun Pengguna**
- **Sinkronisasi Cloud / Backup Otomatis ke Server**
- **Backend/Server Mandiri** (aplikasi hanya mengonsumsi Open Food Facts API sebagai *read-only* service)
- **Kalkulasi Nutrisi Lain** (kalori, gula, lemak, protein, dll) — fokus aplikasi hanya pada natrium
- **Rekomendasi Produk Alternatif Berbasis AI/Machine Learning**
- **Fitur Sosial** (berbagi riwayat, komunitas, leaderboard, dsb.)
- **Multi-platform Sinkronisasi Lintas Perangkat**
- **Integrasi dengan Perangkat Wearable/Kesehatan (Smartwatch, dsb.)**
- **Mode Multi-bahasa (Localization) di luar Bahasa Indonesia/Inggris dasar**
- **Kontribusi Data Balik ke Open Food Facts (Crowdsourcing Input)**

---
 
## 6. Kriteria Aplikasi Dinyatakan Berhasil
### Kriteria Fungsional
- Aplikasi berhasil membaca barcode produk menggunakan kamera dengan tingkat keberhasilan yang wajar pada kondisi pencahayaan normal.
- Data nutrisi (khususnya natrium) berhasil diambil dari Open Food Facts API dan ditampilkan ke pengguna dalam waktu respons yang wajar.
- Sistem mampu menjumlahkan total konsumsi natrium harian secara akurat berdasarkan seluruh entri pada tanggal tersebut.
- Pengguna dapat menambahkan data secara manual ketika produk tidak ditemukan di database API.
- Seluruh data konsumsi tersimpan secara persisten di Hive Database dan tetap dapat diakses setelah aplikasi ditutup/dibuka kembali (termasuk dalam kondisi offline).
- Pengguna dapat melihat, mengedit, dan menghapus riwayat konsumsi yang telah tercatat.
### Kriteria Teknis
- Aplikasi berjalan stabil (tanpa *crash*) pada alur utama: scan → ambil data → simpan → lihat riwayat.
- Tidak terjadi kebocoran memori atau *lag* signifikan saat proses scanning berlangsung.
- Aplikasi tetap dapat menampilkan riwayat data lama meskipun tidak ada koneksi internet (local-first).
- Struktur kode terorganisir dengan pemisahan yang jelas antara UI, logika bisnis, dan lapisan data (data layer).
### Kriteria Non-Fungsional
- Antarmuka pengguna (UI) sederhana dan mudah dipahami tanpa memerlukan proses onboarding yang rumit.
- Proses scan hingga tampilnya data nutrisi berlangsung dalam waktu yang terasa responsif bagi pengguna.
- Aplikasi tidak memerlukan proses pendaftaran akun untuk dapat langsung digunakan (zero-friction onboarding).
