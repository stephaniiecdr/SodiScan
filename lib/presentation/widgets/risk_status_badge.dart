import 'package:flutter/material.dart';

import '../../domain/entities/risk_status.dart';

Color riskStatusColor(RiskStatus status) {
  return switch (status) {
    RiskStatus.safe => const Color(0xFF2E7D32),
    RiskStatus.nearLimit => const Color(0xFFBF360C),
    RiskStatus.danger => const Color(0xFFC62828),
  };
}

String riskStatusLabel(RiskStatus status) {
  return switch (status) {
    RiskStatus.safe => 'Aman',
    RiskStatus.nearLimit => 'Mendekati Batas',
    RiskStatus.danger => 'Bahaya',
  };
}

class RiskStatusBadge extends StatelessWidget {
  const RiskStatusBadge({super.key, required this.status});

  final RiskStatus status;

  @override
  Widget build(BuildContext context) {
    final label = riskStatusLabel(status);

    return Semantics(
      label: 'Status risiko: $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: riskStatusColor(status),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
