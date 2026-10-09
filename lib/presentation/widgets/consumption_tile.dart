import 'package:flutter/material.dart';

import '../../core/utils/sodium_format.dart';
import '../../domain/entities/food_consumption.dart';

class ConsumptionTile extends StatelessWidget {
  const ConsumptionTile({super.key, required this.consumption});

  final FoodConsumption consumption;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(consumption.consumedAt).format(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.restaurant),
      title: Text(consumption.productName),
      subtitle: Text(time),
      trailing: Text(formatSodiumMg(consumption.sodiumMg), style: Theme.of(context).textTheme.titleSmall),
    );
  }
}
