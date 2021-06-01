import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otraku/utils/config.dart';

class Toast {
  Toast._();

  static OverlayEntry? _entry;
  static bool _busy = false;

  static void show(final BuildContext ctx, final String text) {
    _busy = true;
    _entry?.remove();

    _entry = OverlayEntry(
      builder: (ctx) => Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: EdgeInsets.only(
            bottom: 70 +
                MediaQuery.of(ctx).viewPadding.bottom +
                MediaQuery.of(ctx).viewInsets.bottom,
          ),
          padding: Config.PADDING,
          decoration: BoxDecoration(
            color: Theme.of(ctx).primaryColor,
            borderRadius: Config.BORDER_RADIUS,
            boxShadow: [
              BoxShadow(color: Theme.of(ctx).backgroundColor, blurRadius: 10),
            ],
          ),
          child: Text(text, style: Theme.of(ctx).textTheme.bodyText1),
        ),
      ),
    );

    Overlay.of(ctx)!.insert(_entry!);

    Future.delayed(const Duration(seconds: 2)).then((_) {
      if (!_busy) {
        _entry?.remove();
        _entry = null;
      }
    });

    _busy = false;
  }

  static void copy(final BuildContext ctx, final String? text) =>
      Clipboard.setData(ClipboardData(text: text))
          .then((_) => show(ctx, 'Copied'));
}
