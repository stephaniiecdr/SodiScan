import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../product_lookup/product_lookup_validators.dart';
import 'scan_result.dart';

Future<ScanResult?> scanBarcode(BuildContext context) {
  final scan = context.read<ScanBarcode?>() ?? ScannerScreen.open;
  return scan(context);
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  static Future<ScanResult?> open(BuildContext context) {
    return Navigator.of(context).push(MaterialPageRoute<ScanResult>(builder: (_) => const ScannerScreen()));
  }

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.ean13, BarcodeFormat.ean8, BarcodeFormat.upcA, BarcodeFormat.upcE],
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue?.trim();
      if (code != null && validateBarcode(code) == null) {
        _handled = true;
        Navigator.of(context).pop(ScanResult.barcode(code));
        return;
      }
    }
  }

  void _typeManually() => Navigator.of(context).pop(const ScanResult.manualEntry());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Pindai Barcode'),
        actions: [
          IconButton(
            key: const Key('torchButton'),
            tooltip: 'Senter',
            icon: const Icon(Icons.flashlight_on_outlined),
            onPressed: _controller.toggleTorch,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            placeholderBuilder: (_) => const ScannerStatusView.loading(),
            errorBuilder: (_, error) => ScannerStatusView.error(
              error: error.errorCode,
              onRetry: _controller.start,
              onTypeManually: _typeManually,
            ),
          ),
          const IgnorePointer(child: _ScanFrame()),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              child: FilledButton.tonalIcon(
                key: const Key('typeBarcodeButton'),
                onPressed: _typeManually,
                icon: const Icon(Icons.keyboard),
                label: const Text('Ketik Barcode'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 280,
            height: 160,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Arahkan kamera ke barcode kemasan',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class ScannerStatusView extends StatelessWidget {
  const ScannerStatusView.loading({super.key})
      : error = null,
        onRetry = null,
        onTypeManually = null;

  const ScannerStatusView.error({
    super.key,
    required MobileScannerErrorCode this.error,
    required this.onRetry,
    required this.onTypeManually,
  });

  final MobileScannerErrorCode? error;
  final VoidCallback? onRetry;
  final VoidCallback? onTypeManually;

  @override
  Widget build(BuildContext context) {
    final (icon, title, message) = switch (error) {
      null => (Icons.photo_camera_outlined, 'Menyiapkan kamera...', ''),
      MobileScannerErrorCode.permissionDenied => (
          Icons.no_photography_outlined,
          'Izin Kamera Ditolak',
          'Izinkan akses kamera agar SodiScan dapat memindai barcode. '
              'Jika sudah ditolak permanen, buka Pengaturan HP > Aplikasi > SodiScan > Izin.',
        ),
      MobileScannerErrorCode.unsupported => (
          Icons.videocam_off_outlined,
          'Kamera Tidak Tersedia',
          'Perangkat ini tidak mendukung pemindaian kamera. Ketik kode barcode secara manual.',
        ),
      _ => (Icons.error_outline, 'Kamera Gagal Dibuka', 'Tutup aplikasi lain yang memakai kamera, lalu coba lagi.'),
    };

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (error == null) const CircularProgressIndicator(color: Colors.white) else Icon(icon, size: 56, color: Colors.white),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              if (message.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              ],
              if (error != null) ...[
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    if (error != MobileScannerErrorCode.unsupported)
                      FilledButton.icon(
                        key: const Key('scannerRetryButton'),
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba Lagi'),
                      ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                      onPressed: onTypeManually,
                      icon: const Icon(Icons.keyboard),
                      label: const Text('Ketik Barcode'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
