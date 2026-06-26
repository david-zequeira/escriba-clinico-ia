import 'package:dio/dio.dart';
import 'package:escriba_clinico/features/consultation/data/datasources/consultation_remote_datasource.dart';
import 'package:escriba_clinico/features/consultation/data/repositories/consultation_repository_impl.dart';
import 'package:escriba_clinico/features/consultation/domain/entities/transcript.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRemote extends ConsultationRemoteDataSource {
  _FakeRemote(this.json) : super(Dio());
  final Map<String, dynamic> json;

  @override
  Future<Map<String, dynamic>> fetchConsultation(String consultationId) async =>
      json;
}

Map<String, dynamic> _baseJson({Map<String, dynamic>? extra}) => {
      'id': 'c-1',
      'consultation_type': 'admission_interview',
      'document_title': 'Historia clínica de ingreso',
      'section_labels': const {},
      'clinical_draft': {
        'document_type': 'admission_interview',
        'motivo_ingreso': {'content': 'dolor torácico', 'needs_confirmation': false},
        'plan': {'content': 'ingreso en observación', 'needs_confirmation': false},
      },
      ...?extra,
    };

void main() {
  group('Evidencia (F1)', () {
    test('genera transcript + evidencia mock cuando el backend no los provee', () async {
      final repo = ConsultationRepositoryImpl(_FakeRemote(_baseJson()));

      final c = await repo.getConsultation('c-1');

      expect(c.transcript.isNotEmpty, isTrue);
      // Las secciones con contenido tienen evidencia…
      expect(c.evidenceBySection['motivo_ingreso'], isNotEmpty);
      expect(c.evidenceBySection['plan'], isNotEmpty);
      // …y los índices apuntan a segmentos válidos de la transcripción.
      final idx = c.evidenceBySection['motivo_ingreso']!.first;
      expect(idx, lessThan(c.transcript.segments.length));
    });

    test('usa transcript + evidencia reales cuando el backend los envía', () async {
      final json = _baseJson(extra: {
        'transcript': [
          {'speaker': 'medico', 'text': '¿Qué le ocurre?'},
          {'speaker': 'paciente', 'text': 'Dolor en el pecho.'},
        ],
        'evidence': {
          'plan': [1],
        },
      });
      final repo = ConsultationRepositoryImpl(_FakeRemote(json));

      final c = await repo.getConsultation('c-1');

      expect(c.transcript.segments.length, 2);
      expect(c.transcript.segments.first.speaker, Speaker.medico);
      expect(c.evidenceBySection['plan'], [1]);
    });
  });
}
