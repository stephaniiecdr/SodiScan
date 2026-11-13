import '../../core/errors/failures.dart';
import '../../domain/usecases/sync_consumptions.dart';
import 'add_consumption_state.dart';
import 'base_notifier.dart';
import 'server_sync_state.dart';

class ServerSyncNotifier extends StateNotifier<ServerSyncState> {
  ServerSyncNotifier({
    required GetServerConsumptions getServerConsumptions,
    required UploadConsumptions uploadConsumptions,
    required RestoreConsumptions restoreConsumptions,
  })  : _getServerConsumptions = getServerConsumptions,
        _uploadConsumptions = uploadConsumptions,
        _restoreConsumptions = restoreConsumptions,
        super(const ServerSyncState());

  static const String networkErrorText = 'Tidak dapat terhubung ke server. Pastikan server berjalan lalu coba lagi.';
  static const String formatErrorText = 'Data dari server tidak valid.';

  final GetServerConsumptions _getServerConsumptions;
  final UploadConsumptions _uploadConsumptions;
  final RestoreConsumptions _restoreConsumptions;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading, clearError: true));
    try {
      final items = await _getServerConsumptions();
      emit(state.copyWith(status: items.isEmpty ? LoadStatus.empty : LoadStatus.success, items: items));
    } on Exception catch (error) {
      emit(state.copyWith(status: LoadStatus.error, items: const [], errorMessage: messageFor(error)));
    }
  }

  Future<void> retry() => load();

  Future<String> upload() => _sync(SyncAction.upload, () async {
        final count = await _uploadConsumptions();
        await load();
        return '$count catatan dikirim ke server.';
      });

  Future<String> restore() => _sync(SyncAction.restore, () async {
        final count = await _restoreConsumptions();
        return '$count catatan dari server disimpan ke perangkat.';
      });

  Future<String> _sync(SyncAction syncAction, Future<String> Function() action) async {
    if (state.isSyncing) return '';
    emit(state.copyWith(activeSync: syncAction));
    try {
      return await action();
    } on Exception catch (error) {
      return messageFor(error);
    } finally {
      emit(state.copyWith(clearActiveSync: true));
    }
  }

  static String messageFor(Exception error) => error is DataFormatFailure ? formatErrorText : networkErrorText;
}
