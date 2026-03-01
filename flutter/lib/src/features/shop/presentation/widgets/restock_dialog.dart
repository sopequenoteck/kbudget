import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RestockDialog extends StatefulWidget {
  const RestockDialog({super.key});

  @override
  State<RestockDialog> createState() => _RestockDialogState();
}

class _RestockDialogState extends State<RestockDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validate() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Veuillez saisir une quantité');
      return;
    }
    final value = int.tryParse(text);
    if (value == null || value <= 0) {
      setState(() => _error = 'La quantité doit être un entier positif');
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter du stock'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Quantité',
              hintText: 'Ex: 10',
              errorText: _error,
            ),
            onSubmitted: (_) => _validate(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _validate,
          child: const Text('Confirmer'),
        ),
      ],
    );
  }
}
