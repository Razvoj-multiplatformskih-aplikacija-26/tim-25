import 'package:flutter/material.dart';

Future<bool> confirmAction(BuildContext context, String title) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text('Ovu promenu nije moguće poništiti.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Potvrdi'),
          ),
        ],
      ),
    ) ??
    false;
