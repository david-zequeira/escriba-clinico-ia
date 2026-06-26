import 'package:escriba_clinico/features/consultation/domain/entities/clinical_draft.dart';
import 'package:escriba_clinico/features/consultation/domain/entities/consultation.dart';
import 'package:escriba_clinico/features/consultation/domain/entities/transcript.dart';
import 'package:escriba_clinico/features/consultation/domain/repositories/consultation_repository.dart';
import 'package:escriba_clinico/features/consultation/presentation/screens/review_screen.dart';
import 'package:escriba_clinico/features/consultation/state_management/consultation_controller.dart';
import 'package:escriba_clinico/l10n/app_localizations.dart';
import 'package:escriba_clinico/models/consultation_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoopRepo implements ConsultationRepository {
  @override
  Future<bool> isBackendReachable() async => true;
  @override
  Future<String> createConsultation({
    required String patientId,
    required ConsultationType type,
  }) async =>
      'x';
  @override
  Future<void> uploadAudio(String id, List<int> bytes,
      {String filename = 'consulta.m4a'}) async {}
  @override
  Future<void> waitForCompletion(String id) async {}
  @override
  Future<Consultation> getConsultation(String id) async =>
      throw UnimplementedError();
}

/// Controller con estado de revisión ya cargado (sin pasar por la red).
class _SeededController extends ConsultationController {
  _SeededController(ConsultationState seeded) : super(_NoopRepo()) {
    state = seeded;
  }
}

void main() {
  testWidgets('la revisión muestra la conversación y permite resaltar evidencia',
      (tester) async {
    final seeded = ConsultationState(
      stage: ConsultationStage.review,
      consultationType: ConsultationType.admissionInterview,
      documentTitle: 'Historia clínica de ingreso',
      note: ClinicalDraft(
        documentType: ConsultationType.admissionInterview,
        sections: {
          'motivo_ingreso': ClinicalSection(content: 'dolor torácico'),
          'plan': ClinicalSection(content: 'ingreso en observación'),
        },
      ),
      transcript: const Transcript(segments: [
        TranscriptSegment(speaker: Speaker.medico, text: '¿Qué le ocurre?'),
        TranscriptSegment(speaker: Speaker.paciente, text: 'Dolor en el pecho.'),
        TranscriptSegment(speaker: Speaker.medico, text: 'Lo dejamos en observación.'),
      ]),
      evidenceBySection: const {
        'motivo_ingreso': [1],
        'plan': [2],
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          consultationProvider.overrideWith((ref) => _SeededController(seeded)),
        ],
        child: const MaterialApp(home: ReviewScreen(), locale: Locale('es'), localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: [Locale('es'), Locale('en')]),
      ),
    );
    await tester.pumpAndSettle();

    // El panel de conversación y sus segmentos se renderizan.
    expect(find.text('Conversación'), findsOneWidget);
    expect(find.text('Dolor en el pecho.'), findsOneWidget);

    // Hay botones "ver evidencia" en los campos con evidencia.
    final evidenceButtons = find.byTooltip('Ver de dónde salió');
    expect(evidenceButtons, findsWidgets);

    // Pulsar uno no rompe y mantiene la conversación visible.
    await tester.tap(evidenceButtons.first);
    await tester.pumpAndSettle();
    expect(find.text('Conversación'), findsOneWidget);

    // Bidireccional: tocar un fragmento de la conversación selecciona su campo
    // sin romper la pantalla.
    await tester.tap(find.text('Dolor en el pecho.'));
    await tester.pumpAndSettle();
    expect(find.text('Conversación'), findsOneWidget);
    expect(find.text('Dolor en el pecho.'), findsOneWidget);
  });

  testWidgets('en pantalla estrecha, «ver evidencia» abre un bottom sheet',
      (tester) async {
    // Tamaño tipo móvil → layout compacto.
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final seeded = ConsultationState(
      stage: ConsultationStage.review,
      consultationType: ConsultationType.admissionInterview,
      documentTitle: 'Historia clínica de ingreso',
      note: ClinicalDraft(
        documentType: ConsultationType.admissionInterview,
        sections: {'motivo_ingreso': ClinicalSection(content: 'dolor torácico')},
      ),
      transcript: const Transcript(segments: [
        TranscriptSegment(speaker: Speaker.medico, text: '¿Qué le ocurre?'),
        TranscriptSegment(speaker: Speaker.paciente, text: 'Dolor en el pecho.'),
      ]),
      evidenceBySection: const {
        'motivo_ingreso': [1],
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          consultationProvider.overrideWith((ref) => _SeededController(seeded)),
        ],
        child: const MaterialApp(home: ReviewScreen(), locale: Locale('es'), localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: [Locale('es'), Locale('en')]),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Ver de dónde salió').first);
    await tester.pumpAndSettle();

    // El sheet muestra la evidencia del campo.
    expect(find.textContaining('Evidencia ·'), findsOneWidget);
  });
}
