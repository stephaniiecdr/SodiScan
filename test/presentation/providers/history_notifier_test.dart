import 'package:flutter_test/flutter_test.dart';
import 'package:sodiscan/domain/usecases/get_consumption_history.dart';
import 'package:sodiscan/presentation/providers/add_consumption_state.dart';
import 'package:sodiscan/presentation/providers/history_notifier.dart';

import '../../helpers/fake_consumption_repository.dart';

void main() {
  test('load menghasilkan success, empty, atau error sesuai hasil repository', () async {
    final repository = FakeConsumptionRepository(items: [indomieConsumption()]);
    final notifier = HistoryNotifier(getConsumptionHistory: GetConsumptionHistory(repository));
    expect(notifier.state.status, LoadStatus.loading);

    await notifier.load();
    expect(notifier.state.status, LoadStatus.success);
    expect(notifier.state.days.single.totalSodiumMg, 750);

    repository.items.clear();
    await notifier.load();
    expect(notifier.state.status, LoadStatus.empty);

    repository.failLoad = true;
    await notifier.load();
    expect(notifier.state.status, LoadStatus.error);
    expect(notifier.state.errorMessage, HistoryNotifier.loadErrorText);
    notifier.dispose();
  });
}
