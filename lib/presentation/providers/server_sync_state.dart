import '../../domain/entities/food_consumption.dart';
import 'add_consumption_state.dart';

class ServerSyncState {
  const ServerSyncState({
    this.status = LoadStatus.loading,
    this.items = const [],
    this.errorMessage,
    this.isSyncing = false,
  });

  final LoadStatus status;
  final List<FoodConsumption> items;
  final String? errorMessage;
  final bool isSyncing;

  ServerSyncState copyWith({
    LoadStatus? status,
    List<FoodConsumption>? items,
    String? errorMessage,
    bool? isSyncing,
    bool clearError = false,
  }) {
    return ServerSyncState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}
