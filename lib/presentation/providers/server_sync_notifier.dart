import 'package:flutter/foundation.dart';

import '../../core/errors/failures.dart';
import '../../domain/usecases/sync_consumptions.dart';
import 'add_consumption_state.dart';
import 'server_sync_state.dart';

class ServerSyncNotifier extends ChangeNotifier {
  ServerSyncNotifier({
    required GetServerConsumptions getServerConsumptions,
    required UploadConsumptions uploadConsumptions,
    required RestoreConsumptions restoreConsumptions,
  })  : _getServerConsumptions = getServerConsumptions,
        _uploadConsumptions = uploadConsumptions,
        _restoreConsumptions = restoreConsumptions;

  static const String networkErrorText = 'Tidak dapat terhubung ke server. Pastikan server berjalan lalu coba lagi.';
  static const String formatErrorText = 'Data dari server tidak valid.';

  final GetServerConsumptions _getServerConsumptions;
  final UploadConsumptions _uploadConsumptions;
  final RestoreConsumptions _restoreConsumptions;

  ServerSyncState _state = const ServerSyncState();
  bool _isDisposed = false;

  ServerSyncState get state => _state;

  Future<void> load() async {
    _emit(_state.copyWith(status: LoadStatus.loading, clearError: true));
    try {
      final items = await _getServerConsumptions();
      _emit(_state.copyWith(status: items.isEmpty ? LoadStatus.empty : LoadStatus.success, items: items));
    } on Exception catch (error) {
      _emit(_state.copyWith(status: LoadStatus.error, items: const [], errorMessage: messageFor(error)));
    }
  }

  Future<void> retry() => load();

  Future<String> upload() => _sync(() async {
        final count = await _uploadConsumptions();
        await load();
        return '$count catatan dikirim ke server.';
      });

  Future<String> restore() => _sync(() async {
        final count = await _restoreConsumptions();
        return '$count catatan dari server disimpan ke perangkat.';
      });

  Future<String> _sync(Future<String> Function() action) async {
    if (_state.isSyncing) return '';
    _emit(_state.copyWith(isSyncing: true));
    try {
      return await action();
    } on Exception catch (error) {
      return messageFor(error);
    } finally {
      _emit(_state.copyWith(isSyncing: false));
    }
  }

  static String messageFor(Exception error) => error is DataFormatFailure ? formatErrorText : networkErrorText;

  void _emit(ServerSyncState newState) {
    if (_isDisposed) return;
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
