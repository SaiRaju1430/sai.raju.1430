import 'package:flutter/material.dart';

/// A clean responsive wrapper that constrains and centers content on wide desktop/web screens
/// while preserving 100% natural full-width behavior on mobile and tablet screens.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  const ResponsiveContainer({
    Key? key,
    required this.child,
    this.maxWidth = 1200.0,
    this.padding,
    this.alignment = Alignment.topCenter,
  }) : super(key: key);

  /// Convenient preset for authentication, forms, and dialog-like cards
  const ResponsiveContainer.form({
    Key? key,
    required this.child,
    this.maxWidth = 520.0,
    this.padding,
    this.alignment = Alignment.center,
  }) : super(key: key);

  /// Convenient preset for dashboards and wide grids
  const ResponsiveContainer.wide({
    Key? key,
    required this.child,
    this.maxWidth = 1280.0,
    this.padding,
    this.alignment = Alignment.topCenter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}
