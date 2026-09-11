# SodiScan
**SodiScan** adalah aplikasi mobile berbasis Flutter yang dirancang untuk membantu pengguna memantau dan membatasi asupan natrium (garam) harian dari makanan kemasan melalui pemindaian *barcode*.

## Tujuan Proyek (Project Goals)
- **Edukasi Nutrisi:** Meningkatkan kesadaran masyarakat terhadap kadar natrium/garam "tersembunyi" pada makanan kemasan.
- **Pencegahan Risiko Kesehatan:** Membantu pengguna mengontrol konsumsi garam harian guna meminimalkan risiko hipertensi dan penyakit ginjal.
- **Monitoring Praktis:** Menyediakan alat pemantau nutrisi harian yang cepat dan otomatis berbasis teknologi pemindaian *barcode*.

## Target Pengguna (Target Audience)
1. **Individu dengan Kondisi Kesehatan Khusus:** Penderita hipertensi, penderita gangguan ginjal, atau lansia yang wajib membatasi asupan natrium harian.
2. **Masyarakat Sadar Kesehatan (*Health-Conscious*):** Orang yang sedang menjalani pola hidup sehat atau diet rendah garam.
3. **Konsumen Makanan Kemasan / Anak Kos:** Pengguna yang sering mengonsumsi makanan instan/kemasan dan ingin memantau gizi dengan mudah.

## Alur Utama Aplikasi (Core Workflow)

```text
[Scan Barcode Makanan] ──> [Ambil Data dari Open Food Facts API]
                                     │
                                     ▼
[Tampilkan Kadar Natrium & Indikator Warna (Hijau/Kuning/Merah)]
                                     │
                                     ▼
 [Konfirmasi Konsumsi] ──> [Simpan ke Log Riwayat & Update Progress Bar Harian]
