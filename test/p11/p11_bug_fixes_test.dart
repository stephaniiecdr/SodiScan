import 'package:flutter_test/flutter_test.dart';
import 'package:sodiscan/domain/entities/food_consumption.dart';
import 'package:sodiscan/domain/entities/sync_report.dart';
import 'package:sodiscan/presentation/providers/server_sync_notifier.dart';

import '../helpers/fake_consumption_repository.dart';

FoodConsumption _item(String id, String name) {
  return FoodConsumption(
    id: id,
    productName: name,
    sodiumMg: 500,
    source: ConsumptionSource.manual,
    consumedAt: fixedNow,
  );
}

void main() {
  group('Issue #1 pesan hasil "Kirim ke Server"', () {
    test('semua berhasil memakai pesan lama', () {
      expect(ServerSyncNotifier.uploadMessage(const UploadReport(total: 4)), '4 catatan dikirim ke server.');
    });

    test('sebagian gagal menyebut jumlah berhasil, jumlah gagal, dan nama catatan', () {
      final message = ServerSyncNotifier.uploadMessage(UploadReport(total: 3, failed: [_item('b', 'Sosis')]));

      expect(message, contains('2 dari 3 catatan dikirim'));
      expect(message, contains('1 gagal (Sosis)'));
      expect(message, contains('lagi untuk mengulang'));
    });

    test('lebih dari tiga catatan gagal diringkas dengan "dan lainnya"', () {
      final failed = [for (var i = 0; i < 5; i++) _item('$i', 'Item$i')];
      final message = ServerSyncNotifier.uploadMessage(UploadReport(total: 6, failed: failed));

      expect(message, contains('Item0, Item1, Item2, dan lainnya'));
      expect(message, isNot(contains('Item3')));
    });
  });
}
