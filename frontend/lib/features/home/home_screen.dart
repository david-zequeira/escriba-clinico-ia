import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_layout.dart';
import '../../core/navigation/app_page_route.dart';
import '../../core/platform_info.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/hover_scale_card.dart';
import '../../models/consultation_type.dart';
import '../auth/auth_controller.dart';
import '../consultation/recording_screen.dart';

/// Selección del tipo de documento clínico.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return AppPage(
      actions: [
        if (auth.doctorName != null)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: Text(auth.doctorName!, style: Theme.of(context).textTheme.bodySmall),
            ),
          ),
        IconButton(
          tooltip: 'Cerrar sesión',
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
          final gridHeight = (constraints.maxHeight - headerBlock - 24).clamp(160.0, 600.0);
          final cellWidth = (constraints.maxWidth - spacing * (cols - 1)) / cols;
          final cellHeight = (gridHeight - spacing * (rows - 1)) / rows;
          final aspectRatio = (cellWidth / cellHeight).clamp(0.75, 1.6);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeSlideIn(
                child: compact
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _BrandRow(compact: true),
                                const SizedBox(height: 20),
                                Text(
                                  'Nuevo documento',
                                  style: Theme.of(context).textTheme.headlineMedium,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 320,
                            child: Text(
                              'Elige el tipo de nota clínica a generar a partir del audio.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _BrandRow(compact: false),
                          const SizedBox(height: 20),
                          Text('Nuevo documento', style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 8),
                          Text(
                            'Elige el tipo de nota clínica a generar a partir del audio.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
              ),
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
                    return SizedBox.expand(child: _TypeCard(type: type));
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

class _BrandRow extends StatelessWidget {
  const _BrandRow({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: compact ? 40 : 44,
          height: compact ? 40 : 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.medical_services_outlined, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Text('Vionix', style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({required this.type});

  final ConsultationType type;

  void _open(BuildContext context) {
    Navigator.of(context).push(AppPageRoute(page: RecordingScreen(consultationType: type)));
  }

  @override
  Widget build(BuildContext context) {
    return HoverScaleCard(
      accentColor: type.accentColor,
      accentSoft: type.accentSoft,
      onTap: () => _open(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: type.accentSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(type.icon, color: type.accentColor, size: 22),
            ),
            const SizedBox(height: 12),
            Text(type.shortLabel.toUpperCase(), style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              type.title,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                type.subtitle,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Comenzar',
                    style: TextStyle(fontWeight: FontWeight.w600, color: type.accentColor),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: type.accentColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
