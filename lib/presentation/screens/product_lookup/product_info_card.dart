import 'package:flutter/material.dart';

import '../../../core/utils/sodium_format.dart';
import '../../../domain/entities/product.dart';

class ProductInfoCard extends StatelessWidget {
  const ProductInfoCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.name, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            if (product.brand != null) Text(product.brand!, style: textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text('Barcode ${product.barcode}', style: textTheme.bodySmall),
            const Divider(height: 24),
            _InfoRow(label: 'Takaran saji', value: product.servingSize ?? '-'),
            _InfoRow(label: 'Natrium per saji', value: _sodium(product.sodiumPerServingMg)),
            _InfoRow(label: 'Natrium per 100 g', value: _sodium(product.sodiumPer100gMg)),
          ],
        ),
      ),
    );
  }

  String _sodium(double? value) => value == null ? '-' : formatSodiumMg(value);
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
