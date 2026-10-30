import 'package:flutter_test/flutter_test.dart';
import 'package:sodiscan/core/errors/failures.dart';
import 'package:sodiscan/domain/usecases/update_consumption.dart';

import '../helpers/fake_consumption_repository.dart';

void main() {
  test('mengubah nama (di-trim) dan sodium tanpa mengubah id, sumber, dan waktu', () async {
    final repository = FakeConsumptionRepository(items: [indomieConsumption()]);

    final updated = await UpdateConsumption(repository)(
      indomieConsumption(),
      productName: '  Indomie Soto  ',
      sodiumMg: 820,
    );

    expect(repository.items.single.productName, 'Indomie Soto');
    expect(repository.items.single.sodiumMg, 820);
    expect(updated.id, indomieConsumption().id);
    expect(updated.source, indomieConsumption().source);
    expect(updated.consumedAt, indomieConsumption().consumedAt);
  });

  test('menolak input tidak valid tanpa memanggil repository', () async {
    final repository = FakeConsumptionRepository(items: [indomieConsumption()]);
    final updateConsumption = UpdateConsumption(repository);

    for (final (name, sodium) in [('', 500.0), ('Indomie', 0.0), ('Indomie', 10001.0)]) {
      await expectLater(
        updateConsumption(indomieConsumption(), productName: name, sodiumMg: sodium),
        throwsA(isA<ValidationFailure>()),
      );
    }
    expect(repository.updateCalls, 0);
    expect(repository.items.single.productName, 'Indomie Mi Goreng');
  });
}
