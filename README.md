# SodiScan
 
## Deskripsi Masalah
 
Konsumsi natrium (garam) berlebih pada makanan kemasan sering kali tidak disadari oleh masyarakat karena informasi kandungan natrium biasanya tercantum dalam label nutrisi yang kecil, menggunakan istilah teknis, dan tidak langsung menunjukkan seberapa besar kontribusinya terhadap batas konsumsi harian. Akibatnya, pengguna kesulitan memantau total asupan natrium dari berbagai produk yang dikonsumsi dalam satu hari, terutama karena perhitungan akumulasi tersebut harus dilakukan secara manual satu per satu.
 
SodiScan hadir sebagai solusi untuk mempermudah proses ini. Dengan memindai barcode produk makanan kemasan, pengguna dapat langsung mengetahui kandungan natrium dari produk tersebut tanpa perlu mencari atau menghitung sendiri, sekaligus melihat akumulasi konsumsi natrium hariannya dibandingkan dengan batas yang direkomendasikan.
 
## Profil Target Pengguna
 
Pengguna utama SodiScan adalah individu yang ingin lebih sadar terhadap konsumsi natrium hariannya dari makanan kemasan, dengan karakteristik sebagai berikut:
 
- Sering mengonsumsi makanan atau minuman kemasan (snack, makanan instan, minuman kemasan, dll).
- Memiliki kebiasaan berbelanja di minimarket atau supermarket dan ingin mengecek kandungan natrium produk secara cepat sebelum atau saat membeli.
- Tidak memiliki waktu atau kebiasaan untuk membaca label nutrisi secara detail dan menghitung akumulasinya sendiri.
- Ingin memiliki gambaran sederhana mengenai posisi konsumsi natrium hariannya, tanpa perlu proses pencatatan yang rumit.
- Menggunakan aplikasi secara singkat dan cepat, misalnya saat berada di rak makanan di toko atau sesaat setelah mengonsumsi produk kemasan.
## Manfaat Aplikasi
 
- Mempermudah pengecekan kandungan natrium suatu produk kemasan hanya dengan memindai barcode.
- Membantu pengguna memantau total konsumsi natrium harian secara otomatis.
- Memberikan indikator sederhana berbasis warna mengenai posisi konsumsi natrium terhadap batas harian.
- Membantu pencatatan riwayat konsumsi makanan secara lokal di perangkat pengguna.
- Tetap menyediakan alternatif input manual ketika produk tidak ditemukan di database atau aplikasi sedang offline.
## Daftar Fitur Inti
 
| Fitur | Deskripsi |
|---|---|
| Barcode Scanner | Memindai barcode produk makanan kemasan menggunakan kamera perangkat. |
| Open Food Facts API | Mengambil data produk secara real-time berdasarkan barcode yang dipindai. |
| Informasi Kandungan Natrium | Menampilkan kandungan natrium produk berdasarkan data yang diterima dari API. |
| Perhitungan Total Natrium Harian | Menjumlahkan seluruh natrium dari produk yang dicatat pengguna dalam satu hari. |
| Indikator Risiko Berbasis Warna | Menampilkan status konsumsi harian (Aman, Mendekati Batas, Bahaya) berdasarkan akumulasi natrium terhadap batas 2.000 mg/hari. |
| Riwayat Konsumsi | Menampilkan daftar makanan yang telah dicatat pengguna beserta kandungan natriumnya. |
| Penyimpanan Lokal (Hive) | Menyimpan seluruh data konsumsi pengguna secara lokal di perangkat tanpa server. |
| Manual Input Natrium | Memungkinkan pengguna memasukkan nilai natrium secara manual jika produk tidak ditemukan. |
| Offline/Error Fallback | Menyediakan alur input alternatif saat aplikasi tidak terhubung ke internet atau API gagal merespons. |
 
## Fitur yang Tidak Dikerjakan
 
Bagian ini menjelaskan fitur atau scope yang secara sengaja tidak dikerjakan dalam proyek ini, mengingat keterbatasan waktu pengerjaan selama 12 pertemuan serta fokus pengembangan yang ditetapkan pada aplikasi local-first:
 
- **Autentikasi dan registrasi akun** — tidak diperlukan karena aplikasi berjalan tanpa sistem login.
- **Backend/server milik sendiri** — seluruh data diproses dan disimpan secara lokal di perangkat pengguna.
- **Cloud synchronization** — data tidak disinkronkan ke layanan cloud mana pun.
- **Integrasi database online untuk data pengguna** — penyimpanan data pengguna sepenuhnya menggunakan Hive secara lokal.
- **Sistem rekomendasi makanan berbasis AI** — di luar scope karena membutuhkan kompleksitas pengembangan yang tidak sesuai dengan waktu pengerjaan.
- **Diagnosis atau rekomendasi medis** — aplikasi hanya menampilkan informasi natrium, bukan saran kesehatan atau diagnosis.
- **Integrasi dengan perangkat wearable** — tidak termasuk dalam kebutuhan dasar proyek.
- **Notifikasi kesehatan yang kompleks** — hanya indikator visual sederhana yang dikerjakan, bukan sistem notifikasi bertingkat.
- **Fitur sosial antar pengguna** — aplikasi difokuskan sebagai alat pemantauan pribadi, bukan platform sosial.
## Kriteria Aplikasi Dinyatakan Berhasil
 
- Pengguna dapat memindai barcode produk menggunakan kamera perangkat.
- Aplikasi dapat mengambil data produk dari Open Food Facts API ketika data tersedia dan koneksi internet aktif.
- Kandungan natrium produk dapat ditampilkan dengan benar berdasarkan data yang diterima dari API.
- Pengguna dapat mencatat konsumsi makanan ke dalam riwayat aplikasi.
- Total natrium harian dapat dihitung secara otomatis dari makanan yang dicatat.
- Indikator warna berubah sesuai dengan total natrium harian (Aman, Mendekati Batas, Bahaya).
- Data riwayat konsumsi tetap tersimpan dan dapat ditampilkan kembali setelah aplikasi ditutup dan dibuka ulang.
- Pengguna tetap dapat memasukkan natrium secara manual ketika produk tidak ditemukan di API atau aplikasi sedang offline.
- Aplikasi dapat digunakan sepenuhnya tanpa akun, dengan seluruh data utama pengguna tersimpan secara lokal di perangkat.
