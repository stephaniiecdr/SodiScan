import '../entities/food_consumption.dart';
import '../entities/frequent_food.dart';
import '../repositories/consumption_repository.dart';

/// Mengambil makanan yang paling sering dicatat (nama tanpa beda huruf besar/kecil
/// dan spasi dianggap sama), diurutkan dari yang paling sering lalu yang terbaru.
class GetFrequentFoods {
  const GetFrequentFoods(this._repository, {this.limit = 5});

  final ConsumptionRepository _repository;
  final int limit;

  Future<List<FrequentFood>> call() async {
    final groups = <String, List<FoodConsumption>>{};
    for (final item in await _repository.getAllConsumptions()) {
      groups.putIfAbsent(_key(item.productName), () => []).add(item);
    }

    final foods = groups.values.map((items) {
      final latest = items.reduce((a, b) => a.consumedAt.isAfter(b.consumedAt) ? a : b);
      return FrequentFood(
        productName: latest.productName,
        sodiumMg: latest.sodiumMg,
        source: latest.source,
        barcode: latest.barcode,
        count: items.length,
        lastConsumedAt: latest.consumedAt,
      );
    }).toList()
      ..sort((a, b) {
        final byCount = b.count.compareTo(a.count);
        return byCount != 0 ? byCount : b.lastConsumedAt.compareTo(a.lastConsumedAt);
      });

    return foods.take(limit).toList();
  }

  static String _key(String name) => name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
