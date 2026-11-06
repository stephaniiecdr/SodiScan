import 'package:flutter/material.dart';

import '../../core/utils/sodium_format.dart';
import '../../domain/entities/food_consumption.dart';
import 'adaptive_layout.dart';

class ConsumptionTile extends StatelessWidget {
  const ConsumptionTile({super.key, required this.consumption, this.onEdit, this.onDelete});

  final FoodConsumption consumption;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(consumption.consumedAt).format(context);
    final sodiumText = formatSodiumMg(consumption.sodiumMg);
    final sodium = ExcludeSemantics(child: Text(sodiumText, style: Theme.of(context).textTheme.titleSmall));
    final name = consumption.productName;
    // Teks besar: jumlah sodium pindah ke subtitle agar nama makanan tidak terjepit tombol.
    final largeText = isLargeText(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.restaurant),
      title: Semantics(
        label: '$name, $sodiumText, pukul $time',
        excludeSemantics: true,
        child: Text(name),
      ),
      subtitle: ExcludeSemantics(child: Text(largeText ? '$time · $sodiumText' : time)),
      trailing: onEdit == null && onDelete == null
          ? (largeText ? null : sodium)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!largeText) sodium,
                if (onEdit != null)
                  IconButton(
                    key: Key('editConsumption-${consumption.id}'),
                    tooltip: 'Ubah $name',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onEdit,
                  ),
                if (onDelete != null)
                  IconButton(
                    key: Key('deleteConsumption-${consumption.id}'),
                    tooltip: 'Hapus $name',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                  ),
              ],
            ),
    );
  }
}
