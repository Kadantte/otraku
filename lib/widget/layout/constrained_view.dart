import 'package:flutter/widgets.dart';
import 'package:otraku/util/theming.dart';

/// Horizontally constrains [child] into the center.
class ConstrainedView extends StatelessWidget {
  const ConstrainedView({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: Theming.offset),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: Theming.windowWidthMedium,
          ),
          child: child,
        ),
      ),
    );
  }
}

class SliverConstrainedView extends StatelessWidget {
  const SliverConstrainedView({required this.sliver});

  final Widget sliver;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final side =
            (constraints.crossAxisExtent - Theming.windowWidthMedium) / 2;

        return SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: side < Theming.offset ? Theming.offset : side,
          ),
          sliver: sliver,
        );
      },
    );
  }
}
