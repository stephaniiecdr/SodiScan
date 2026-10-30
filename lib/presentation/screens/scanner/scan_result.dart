import 'package:flutter/widgets.dart';

class ScanResult {
  const ScanResult.barcode(String this.barcode);

  const ScanResult.manualEntry() : barcode = null;

  final String? barcode;

  bool get isManualEntry => barcode == null;
}

typedef ScanBarcode = Future<ScanResult?> Function(BuildContext context);
