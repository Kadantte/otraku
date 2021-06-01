import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otraku/utils/config.dart';

class NumberField extends StatefulWidget {
  final num value;
  final num? maxValue;
  final Function(num) update;

  NumberField({
    required this.update,
    this.value = 0,
    this.maxValue,
  });

  @override
  _NumberFieldState createState() => _NumberFieldState();
}

class _NumberFieldState extends State<NumberField> {
  late TextEditingController _controller;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: Config.BORDER_RADIUS,
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () => _validateInput(add: -1),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                ],
                textAlign: TextAlign.center,
                cursorColor: Theme.of(context).accentColor,
                decoration: const InputDecoration(border: InputBorder.none),
                onChanged: (value) => _validateInput(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _validateInput(add: 1),
            ),
          ],
        ),
      );

  void _validateInput({num add = 0}) {
    num result;
    bool needEdit = true;

    if (_controller.text == '')
      result = 0;
    else {
      final number = num.parse(_controller.text) + add;

      if (widget.maxValue != null && number > widget.maxValue!)
        result = widget.maxValue!;
      else if (number < 0)
        result = 0;
      else {
        result = number;
        if (add == 0 && int.tryParse(_controller.text) == null)
          needEdit = false;
      }
    }

    widget.update(result);

    if (needEdit) {
      final text = result.toString();
      _controller.value = _controller.value.copyWith(
        text: text,
        selection: TextSelection(
          baseOffset: text.length,
          extentOffset: text.length,
        ),
        composing: TextRange.empty,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
    _controller.addListener(_validateInput);
  }

  @override
  void didUpdateWidget(covariant NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = widget.value.toString();
    _controller.value = _controller.value.copyWith(
      text: text,
      selection: TextSelection(
        baseOffset: text.length,
        extentOffset: text.length,
      ),
      composing: TextRange.empty,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
