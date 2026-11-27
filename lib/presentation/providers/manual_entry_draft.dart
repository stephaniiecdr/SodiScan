/// Data awal untuk form Input Manual saat pencarian produk tidak berhasil,
/// supaya pengguna tidak perlu mengetik ulang nama produk dan barcode tetap tercatat.
class ManualEntryDraft {
  const ManualEntryDraft({this.productName, this.barcode});

  final String? productName;
  final String? barcode;
}

/// Hasil halaman Cari Produk: konsumsi sudah disimpan, atau pengguna memilih Input Manual.
class LookupResult {
  const LookupResult.saved() : manualEntry = null;
  const LookupResult.manualEntry(ManualEntryDraft this.manualEntry);

  final ManualEntryDraft? manualEntry;

  bool get isSaved => manualEntry == null;
}
