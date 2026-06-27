import 'package:escriba_clinico/features/consultation/data/repositories/consultation_repository_impl.dart';
import 'package:escriba_clinico/features/consultation/domain/entities/clinical_draft.dart';
import 'package:escriba_clinico/features/consultation/domain/entities/consultation.dart';
import 'package:escriba_clinico/features/consultation/domain/repositories/consultation_repository.dart';
import 'package:escriba_clinico/features/consultation/state_management/consultation_controller.dart';
import 'package:escriba_clinico/models/consultation_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repositorio falso para aislar el controller de la red.
class _FakeRepo implements ConsultationRepository {
  bool shouldFail = false;
  List<int>? uploadedBytes;

  @override
  Future<bool> isBackendReachable() async => true;

  @override
  Future<String> createConsultation({
    required String patientId,
    required ConsultationType type,
  }) async =>
      'c-1';

  @override
  Future<void> uploadAudio(
    String consultationId,
    List<int> audioBytes, {
    String filename = 'consulta.m4a',
  }) async {
    uploadedBytes = audioBytes;
  }

  @override
  Future<void> waitForCompletion(String consultationId) async {}

  @override
  Future<Consultation> getConsultation(String consultationId) async {
    if (shouldFail) throw Exception('fallo del servidor');
    return Consultation(
      id: consultationId,
      consultationType: ConsultationType.admissionInterview,
      documentTitle: 'Historia clínica de ingreso',
      sectionLabels: const {},
      draft: ClinicalDraft(
        documentType: ConsultationType.admissionInterview,
        sections: {'plan': ClinicalSection(content: 'ingreso')},
      ),
    );
  }
}

void main() {
  late _FakeRepo repo;
  late ProviderContainer container;

  setUp(() {
    repo = _FakeRepo();
    container = ProviderContainer(
      overrides: [consultationRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  ConsultationController controller() =>
      container.read(consultationProvider.notifier);

  test('selectType fija el tipo y deja la etapa en idle', () {
    controller().selectType(ConsultationType.evolution);

    final state = container.read(consultationProvider);
    expect(state.consultationType, ConsultationType.evolution);
    expect(state.stage, ConsultationStage.idle);
  });

  test('submitAudio (camino feliz) pasa a review con el borrador', () async {
    controller().selectType(ConsultationType.admissionInterview);

    await controller().submitAudio([1, 2, 3], '12345678Z');

    final state = container.read(consultationProvider);
    expect(state.stage, ConsultationStage.review);
    expect(state.consultationId, 'c-1');
    expect(state.patientId, '12345678Z');
    expect(state.note!.sections['plan']!.content, 'ingreso');
    expect(repo.uploadedBytes, [1, 2, 3]);
  });

  test('beginSession crea la consulta y deja la etapa en recording', () async {
    controller().selectType(ConsultationType.admissionInterview);

    final id = await controller().beginSession('12345678Z');

    final state = container.read(consultationProvider);
    expect(id, 'c-1');
    expect(state.stage, ConsultationStage.recording);
    expect(state.consultationId, 'c-1');
    expect(state.patientId, '12345678Z');
  });

  test('beginSession + finalizeWithAudio completa el flujo unificado', () async {
    controller().selectType(ConsultationType.admissionInterview);
    await controller().beginSession('12345678Z');

    await controller().finalizeWithAudio([9, 9], filename: 'live.wav');

    final state = container.read(consultationProvider);
    expect(state.stage, ConsultationStage.review);
    expect(state.consultationId, 'c-1');
    expect(state.patientId, '12345678Z');
    expect(state.note!.sections['plan']!.content, 'ingreso');
    expect(repo.uploadedBytes, [9, 9]);
  });

  test('finalizeWithAudio sin sesión iniciada no hace nada', () async {
    controller().selectType(ConsultationType.admissionInterview);

    await controller().finalizeWithAudio([1]);

    expect(container.read(consultationProvider).stage, ConsultationStage.idle);
    expect(repo.uploadedBytes, isNull);
  });

  test('submitAudio propaga el error como estado de error', () async {
    repo.shouldFail = true;
    controller().selectType(ConsultationType.admissionInterview);

    await controller().submitAudio([1], 'p');

    final state = container.read(consultationProvider);
    expect(state.stage, ConsultationStage.error);
    expect(state.errorMessage, contains('fallo del servidor'));
  });

  test('submitAudio sin tipo seleccionado no hace nada', () async {
    await controller().submitAudio([1], 'p');

    expect(container.read(consultationProvider).stage, ConsultationStage.idle);
  });

  test('updateSectionContent edita la sección del borrador', () async {
    controller().selectType(ConsultationType.admissionInterview);
    await controller().submitAudio([1], 'p');

    controller().updateSectionContent('plan', 'reposo absoluto');

    expect(
      container.read(consultationProvider).note!.sections['plan']!.content,
      'reposo absoluto',
    );
  });
}
