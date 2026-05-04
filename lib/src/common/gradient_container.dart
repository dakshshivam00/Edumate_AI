import 'package:flutter/material.dart';

class GradientContainer extends StatelessWidget {
  final Widget child;
  final bool useSafeArea;
  final EdgeInsets? padding;

  const GradientContainer({
    super.key,
    required this.child,
    this.useSafeArea = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final container = Container(
      height: double.infinity,
      width: double.infinity,
      decoration: BoxDecoration(color: colorScheme.surface),
      child: padding != null ? Padding(padding: padding!, child: child) : child,
    );

    return useSafeArea ? SafeArea(child: container) : container;
  }
}
