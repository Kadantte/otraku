import 'package:flutter/material.dart';
import 'package:otraku/utils/config.dart';
import 'package:otraku/widgets/html_content.dart';

Future<dynamic> showPopUp(BuildContext ctx, Widget child) => showDialog(
      context: ctx,
      builder: (ctx) => PopUpAnimation(child),
      barrierColor: Theme.of(ctx).colorScheme.background.withAlpha(200),
    );

class PopUpAnimation extends StatefulWidget {
  final Widget child;
  const PopUpAnimation(this.child);

  @override
  _PopUpAnimationState createState() => _PopUpAnimationState();
}

class _PopUpAnimationState extends State<PopUpAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
      value: 0.1,
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
        scale: _anim,
        child: widget.child,
      );
}

class InputDialog extends StatelessWidget {
  final String initial;
  final void Function(String) onChanged;

  InputDialog({required this.initial, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    String text = initial;

    return TextFormField(
      maxLines: 5,
      initialValue: initial,
      onChanged: (t) => text = t,
      onEditingComplete: () {
        Navigator.pop(context);
        onChanged(text.trim());
      },
    );
  }
}

// A basic container for a dialog.
class DialogBox extends StatelessWidget {
  final Widget child;
  const DialogBox(this.child);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
        child: child,
      ),
    );
  }
}

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String? content;
  final String mainAction;
  final String? secondaryAction;
  final void Function()? onConfirm;

  ConfirmationDialog({
    required this.title,
    required this.mainAction,
    this.content,
    this.secondaryAction,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: content != null ? Text(content!) : null,
      actions: [
        if (secondaryAction != null)
          TextButton(
            child: Text(
              secondaryAction!,
              style:
                  TextStyle(color: Theme.of(context).colorScheme.onBackground),
            ),
            onPressed: Navigator.of(context).pop,
          ),
        TextButton(
          child: Text(mainAction),
          onPressed: () {
            onConfirm?.call();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class ImageDialog extends StatelessWidget {
  final String url;
  final BoxFit fit;

  const ImageDialog(this.url, [this.fit = BoxFit.cover]);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
      shape: const RoundedRectangleBorder(borderRadius: Config.BORDER_RADIUS),
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: Config.BORDER_RADIUS,
        child: Image.network(url, fit: fit),
      ),
    );
  }
}

class TextDialog extends StatelessWidget {
  final String title;
  final String text;
  const TextDialog({required this.title, required this.text});

  @override
  Widget build(BuildContext context) =>
      _DialogColumn(title: title, expand: false, child: Text(text));
}

class HtmlDialog extends StatelessWidget {
  final String title;
  final String text;
  const HtmlDialog({required this.title, required this.text});

  @override
  Widget build(BuildContext context) =>
      _DialogColumn(title: title, expand: true, child: HtmlContent(text));
}

class _DialogColumn extends StatelessWidget {
  final String title;
  final Widget child;
  final bool expand;

  const _DialogColumn({
    required this.title,
    required this.child,
    required this.expand,
  });

  @override
  Widget build(BuildContext context) {
    return DialogBox(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Config.RADIUS),
              color: Theme.of(context).colorScheme.background,
            ),
            padding: Config.PADDING,
            child: Text(title, style: Theme.of(context).textTheme.subtitle1),
          ),
          Flexible(
            fit: expand ? FlexFit.tight : FlexFit.loose,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(bottom: Config.RADIUS),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Scrollbar(
                child: SingleChildScrollView(
                  physics: Config.PHYSICS,
                  padding: Config.PADDING,
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
