import 'package:flutter/material.dart';

import '../../domain/entities/risk_status.dart';

class RiskStatusBadge extends StatelessWidget {
  const RiskStatusBadge({super.key, required this.status});

  final RiskStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      RiskStatus.safe => ('Aman', const Color(0xFF2E7D32)),
      RiskStatus.nearLimit => ('Mendekati Batas', const Color(0xFFE65100)),
      RiskStatus.danger => ('Bahaya', const Color(0xFFC62828)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }
}
