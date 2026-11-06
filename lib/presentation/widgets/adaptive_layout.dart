import 'dart:math' as math;

import 'package:flutter/material.dart';

class Breakpoints {
  static const double expanded = 840;
  static const double contentMaxWidth = 640;
}

bool isExpandedWidth(BuildContext context) => MediaQuery.sizeOf(context).width >= Breakpoints.expanded;

bool isLargeText(BuildContext context) => MediaQuery.textScalerOf(context).scale(1) >= 1.3;

/// Padding yang menjaga konten tetap di tengah dengan lebar maksimal [Breakpoints.contentMaxWidth]
/// agar form dan daftar tidak melebar di tablet / landscape.
EdgeInsets adaptivePadding(BuildContext context, {double base = 16}) {
  final width = MediaQuery.sizeOf(context).width;
  final horizontal = math.max(base, (width - Breakpoints.contentMaxWidth) / 2);
  return EdgeInsets.symmetric(horizontal: horizontal, vertical: base);
}

class TwoPaneLayout extends StatelessWidget {
  const TwoPaneLayout({super.key, required this.primary, required this.secondary});

  final Widget primary;
  final Widget secondary;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 2, child: primary),
        const VerticalDivider(width: 1),
        Expanded(flex: 3, child: secondary),
      ],
    );
  }
}
