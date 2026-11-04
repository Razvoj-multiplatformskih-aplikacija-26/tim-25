import 'package:flutter/material.dart';

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.caption});
  final String title;
  final String? caption;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (caption != null)
          Text(caption!, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}
