import '../../core/errors/failures.dart';
import '../../core/logging/app_log.dart';
import '../../domain/entities/sync_report.dart';
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

  static const String _tag = 'Sinkronisasi';
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
      AppLog.w(_tag, 'Data server gagal dimuat', error);
      emit(state.copyWith(status: LoadStatus.error, items: const [], errorMessage: messageFor(error)));
    }
  }

  Future<void> retry() => load();

  Future<String> upload() => _sync(SyncAction.upload, () async {
        final report = await _uploadConsumptions();
        await load();
        if (report.hasFailures) {
          AppLog.w(_tag, 'Upload sebagian gagal: ${report.failed.map((item) => item.id).join(', ')}');
        }
        return uploadMessage(report);
      });

  Future<String> restore() => _sync(SyncAction.restore, () async {
        final report = await _restoreConsumptions();
        return restoreMessage(report);
      });

  static String uploadMessage(UploadReport report) {
    if (!report.hasFailures) return '${report.total} catatan dikirim ke server.';

    final names = report.failed.map((item) => item.productName).take(3).join(', ');
    final more = report.failed.length > 3 ? ', dan lainnya' : '';
    return '${report.successCount} dari ${report.total} catatan dikirim. '
        '${report.failed.length} gagal ($names$more). Tekan "Kirim ke Server" lagi untuk mengulang.';
  }

  static String restoreMessage(RestoreReport report) {
    final parts = <String>['${report.savedCount} catatan dari server disimpan ke perangkat.'];
    if (report.keptLocal > 0) parts.add('${report.keptLocal} catatan lokal yang lebih baru dipertahankan.');
    return parts.join(' ');
  }

  Future<String> _sync(SyncAction syncAction, Future<String> Function() action) async {
    if (state.isSyncing) return '';
    emit(state.copyWith(activeSync: syncAction));
    AppLog.i(_tag, 'Mulai ${syncAction.name}');
    try {
      final message = await action();
      AppLog.i(_tag, '${syncAction.name} selesai: $message');
      return message;
    } on Exception catch (error) {
      AppLog.w(_tag, '${syncAction.name} gagal', error);
      return messageFor(error);
    } finally {
      emit(state.copyWith(clearActiveSync: true));
    }
  }

  static String messageFor(Exception error) => error is DataFormatFailure ? formatErrorText : networkErrorText;
}
