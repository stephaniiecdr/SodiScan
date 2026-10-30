import 'package:flutter/material.dart';

import '../../core/utils/sodium_format.dart';
import '../../domain/entities/food_consumption.dart';

class ConsumptionTile extends StatelessWidget {
  const ConsumptionTile({super.key, required this.consumption, this.onEdit, this.onDelete});

  final FoodConsumption consumption;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(consumption.consumedAt).format(context);
    final sodium = Text(formatSodiumMg(consumption.sodiumMg), style: Theme.of(context).textTheme.titleSmall);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.restaurant),
      title: Text(consumption.productName),
      subtitle: Text(time),
      trailing: onEdit == null && onDelete == null
          ? sodium
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                sodium,
                if (onEdit != null)
                  IconButton(
                    key: Key('editConsumption-${consumption.id}'),
                    tooltip: 'Ubah',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onEdit,
                  ),
                if (onDelete != null)
                  IconButton(
                    key: Key('deleteConsumption-${consumption.id}'),
                    tooltip: 'Hapus',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                  ),
              ],
            ),
    );
  }
}
