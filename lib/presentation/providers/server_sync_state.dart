import '../../domain/entities/food_consumption.dart';
import 'add_consumption_state.dart';

enum SyncAction { upload, restore }

class ServerSyncState {
  const ServerSyncState({
    this.status = LoadStatus.loading,
    this.items = const [],
    this.errorMessage,
    this.activeSync,
  });

  final LoadStatus status;
  final List<FoodConsumption> items;
  final String? errorMessage;
  final SyncAction? activeSync;

  bool get isSyncing => activeSync != null;

  ServerSyncState copyWith({
    LoadStatus? status,
    List<FoodConsumption>? items,
    String? errorMessage,
    SyncAction? activeSync,
    bool clearError = false,
    bool clearActiveSync = false,
  }) {
    return ServerSyncState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      activeSync: clearActiveSync ? null : activeSync ?? this.activeSync,
    );
  }
}
