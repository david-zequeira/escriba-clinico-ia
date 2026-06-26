import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vionix_app_ui/vionix_app_ui.dart';

import 'package:escriba_clinico/core/l10n_ext.dart';
import 'package:escriba_clinico/core/theme_mode_controller.dart';
import 'package:escriba_clinico/features/auth/state_management/auth_controller.dart';
import 'package:escriba_clinico/features/home/presentation/widgets/brand_row.dart';
import 'package:escriba_clinico/features/home/presentation/widgets/type_card.dart';
import 'package:escriba_clinico/models/consultation_type.dart';

/// Selección del tipo de documento clínico.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // select: el nombre solo provoca rebuild si cambia (no todo el AuthState).
    final doctorName = ref.watch(authProvider.select((s) => s.doctorName));

    return AppPage(
      actions: [
        if (doctorName != null)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: Text(doctorName, style: Theme.of(context).textTheme.bodySmall),
            ),
          ),
        const _ThemeToggleButton(),
        IconButton(
          tooltip: context.l10n.logout,
          icon: const Icon(Icons.logout_rounded),
          onPressed: () => ref.read(authProvider.notifier).logout(),
        ),
      ],
      body: LayoutBuilder(
        builder: (context, constraints) {
          final cols = contentColumns(constraints.maxWidth);
          final compact = constraints.maxWidth >= 900;
          const spacing = 16.0;
          const headerBlock = 130.0;

          // Aspect ratio dinámico según espacio real (estable con zoom / resize).
          final rows = (ConsultationType.values.length / cols).ceil();
          final gridHeight =
              (constraints.maxHeight - headerBlock - 24).clamp(160.0, 600.0);
          final cellWidth = (constraints.maxWidth - spacing * (cols - 1)) / cols;
          final cellHeight = (gridHeight - spacing * (rows - 1)) / rows;
          final aspectRatio = (cellWidth / cellHeight).clamp(0.75, 1.6);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeSlideIn(child: _Header(compact: compact)),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  clipBehavior: Clip.none,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    childAspectRatio: aspectRatio,
                  ),
                  itemCount: ConsultationType.values.length,
                  itemBuilder: (context, i) {
                    final type = ConsultationType.values[i];
                    return FadeSlideIn(
                      delay: VionixMotion.stagger * (i + 1),
                      offset: const Offset(0, 24),
                      child: SizedBox.expand(child: TypeCard(type: type)),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Encabezado de la pantalla; adapta su disposición a ancho compacto/amplio.
class _Header extends StatelessWidget {
  const _Header({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final description = context.l10n.newDocumentSubtitle;
    final title = Text(context.l10n.newDocument,
        style: Theme.of(context).textTheme.headlineMedium);

    if (compact) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BrandRow(compact: true),
                const SizedBox(height: 20),
                title,
              ],
            ),
          ),
          SizedBox(
            width: 320,
            child: Text(description, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BrandRow(compact: false),
        const SizedBox(height: 20),
        title,
        const SizedBox(height: 8),
        Text(description, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

/// Botón de cambio de tema, aislado en su propio Consumer para que alternar el
/// tema no reconstruya toda la pantalla.
class _ThemeToggleButton extends ConsumerWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    return IconButton(
      tooltip: 'Cambiar tema',
      icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
    );
  }
}
