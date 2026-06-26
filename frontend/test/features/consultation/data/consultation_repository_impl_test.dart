import 'package:dio/dio.dart';
import 'package:escriba_clinico/features/consultation/data/datasources/consultation_remote_datasource.dart';
import 'package:escriba_clinico/features/consultation/data/repositories/consultation_repository_impl.dart';
import 'package:escriba_clinico/models/consultation_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// Datasource falso: devuelve JSON fijo sin tocar la red.
class _FakeRemote extends ConsultationRemoteDataSource {
  _FakeRemote(this.json, {this.healthy = true}) : super(Dio());

  final Map<String, dynamic> json;
  final bool healthy;

  @override
  Future<bool> checkHealth() async => healthy;

  @override
  Future<Map<String, dynamic>> fetchConsultation(String consultationId) async =>
      json;
}

void main() {
  group('ConsultationRepositoryImpl.getConsultation', () {
    final backendJson = <String, dynamic>{
      'id': 'c-123',
      'consultation_type': 'admission_interview',
      'document_title': 'Historia clínica de ingreso',
      'section_labels': {'plan': 'Plan'},
      'clinical_draft': {
        'document_type': 'admission_interview',
        'generated_by_ai': true,
        'model_name': 'mistral-small', // metadato: NO debe ser una sección
        'motivo_ingreso': {'content': 'dolor', 'needs_confirmation': true},
        'plan': {'content': 'ingreso', 'needs_confirmation': false},
      },
    };

    test('mapea el JSON del backend a la entidad Consultation', () async {
      final repo = ConsultationRepositoryImpl(_FakeRemote(backendJson));

      final result = await repo.getConsultation('c-123');

      expect(result.id, 'c-123');
      expect(result.consultationType, ConsultationType.admissionInterview);
      expect(result.documentTitle, 'Historia clínica de ingreso');
      expect(result.draft.sections['motivo_ingreso']!.content, 'dolor');
      expect(result.draft.sections['motivo_ingreso']!.needsConfirmation, isTrue);
    });

    test('ignora los metadatos como secciones y normaliza la plantilla', () async {
      final repo = ConsultationRepositoryImpl(_FakeRemote(backendJson));

      final result = await repo.getConsultation('c-123');

      // 'model_name' es metadato, no una sección clínica.
      expect(result.draft.sections.containsKey('model_name'), isFalse);
      // normalize añade las secciones de plantilla ausentes (p.ej. antecedentes).
      expect(result.draft.sections.containsKey('antecedentes'), isTrue);
      expect(result.draft.sections['antecedentes']!.content, isEmpty);
    });

    test('isBackendReachable refleja el estado del datasource', () async {
      final ok = ConsultationRepositoryImpl(_FakeRemote(backendJson, healthy: true));
      final ko = ConsultationRepositoryImpl(_FakeRemote(backendJson, healthy: false));

      expect(await ok.isBackendReachable(), isTrue);
      expect(await ko.isBackendReachable(), isFalse);
    });
  });
}
