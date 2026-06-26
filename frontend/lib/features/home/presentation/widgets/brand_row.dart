import 'package:flutter/material.dart';
import 'package:vionix_app_ui/vionix_app_ui.dart';

/// Logotipo + nombre de la app. Sin estado: `const` para evitar rebuilds.
class BrandRow extends StatelessWidget {
  const BrandRow({super.key, required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: compact ? 40 : 44,
          height: compact ? 40 : 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [context.tokens.primary, context.tokens.primaryDark]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.medical_services_outlined,
              color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Text('Vionix', style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}
