import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:escriba_clinico/features/consultation/data/datasources/consultation_remote_datasource.dart';
import 'package:escriba_clinico/features/consultation/domain/entities/clinical_draft.dart';
import 'package:escriba_clinico/features/consultation/domain/entities/consultation.dart';
import 'package:escriba_clinico/features/consultation/domain/entities/transcript.dart';
import 'package:escriba_clinico/features/consultation/domain/repositories/consultation_repository.dart';
import 'package:escriba_clinico/models/consultation_type.dart';

/// Implementación HTTP del repositorio. Traduce los datos crudos del datasource
/// a entidades de dominio. Es la ÚNICA capa que conoce el formato JSON del backend.
class ConsultationRepositoryImpl implements ConsultationRepository {
  ConsultationRepositoryImpl(this._remote);

  final ConsultationRemoteDataSource _remote;

  static const _metaFields = {
    'document_type',
    'generated_by_ai',
    'model_name',
    'created_at',
  };

  @override
  Future<bool> isBackendReachable() => _remote.checkHealth();

  @override
  Future<String> createConsultation({
    required String patientId,
    required ConsultationType type,
  }) {
    return _remote.createConsultation(
      patientId: patientId,
      typeApiValue: type.apiValue,
    );
  }

  @override
  Future<void> uploadAudio(
    String consultationId,
    List<int> audioBytes, {
    String filename = 'consulta.m4a',
  }) {
    return _remote.uploadAudio(consultationId, audioBytes, filename: filename);
  }

  @override
  Future<void> waitForCompletion(String consultationId) {
    return _remote.waitForCompletion(consultationId);
  }

  @override
  Future<Consultation> getConsultation(String consultationId) async {
    final data = await _remote.fetchConsultation(consultationId);
    final draft = _draftFromJson(data['clinical_draft'] as Map<String, dynamic>);

    // Evidencia (trazabilidad Clase I): si el backend la provee, se usa; si no
    // —caso actual— se genera un mock determinista para construir/demostrar la UI.
    final transcript = _transcriptFromJson(data['transcript']);
    final evidence = _evidenceFromJson(data['evidence']);
    final hasReal = transcript.isNotEmpty && evidence.isNotEmpty;
    final mock = hasReal ? null : _mockEvidence(draft);

    return Consultation(
      id: data['id'] as String,
      consultationType:
          ConsultationType.fromApi(data['consultation_type'] as String),
      documentTitle: data['document_title'] as String,
      sectionLabels: Map<String, String>.from(data['section_labels'] as Map),
      draft: draft,
      transcript: hasReal ? transcript : mock!.transcript,
      evidenceBySection: hasReal ? evidence : mock!.evidence,
    );
  }

  // --- Mapeo JSON -> entidad de dominio ---

  ClinicalDraft _draftFromJson(Map<String, dynamic> j) {
    final type = ConsultationType.fromApi(j['document_type'] as String? ?? '');
    final sections = <String, ClinicalSection>{};
    for (final entry in j.entries) {
      if (entry.value is! Map) continue;
      if (_metaFields.contains(entry.key)) continue;
      final raw = Map<String, dynamic>.from(entry.value as Map);
      sections[entry.key] = ClinicalSection(
        content: raw['content'] as String? ?? '',
        needsConfirmation: raw['needs_confirmation'] as bool? ?? false,
      );
    }
    return ClinicalDraft.normalize(
      ClinicalDraft(
        documentType: type,
        sections: sections,
        generatedByAi: j['generated_by_ai'] as bool? ?? true,
      ),
    );
  }

  Transcript _transcriptFromJson(dynamic raw) {
    if (raw is! List) return const Transcript();
    return Transcript(
      segments: raw.whereType<Map>().map((m) {
        final mm = Map<String, dynamic>.from(m);
        return TranscriptSegment(
          speaker: Speaker.fromApi(mm['speaker'] as String?),
          text: mm['text'] as String? ?? '',
          startMs: mm['start_ms'] as int?,
          endMs: mm['end_ms'] as int?,
        );
      }).toList(),
    );
  }

  Map<String, List<int>> _evidenceFromJson(dynamic raw) {
    if (raw is! Map) return const {};
    final out = <String, List<int>>{};
    raw.forEach((k, v) {
      if (v is List) {
        out['$k'] = v.whereType<num>().map((n) => n.toInt()).toList();
      }
    });
    return out;
  }

  /// MOCK temporal (contrato F1): construye una conversación sintética a partir
  /// del borrador y enlaza cada sección con su segmento. Se elimina en cuanto el
  /// backend devuelva `transcript` + `evidence` reales.
  ({Transcript transcript, Map<String, List<int>> evidence}) _mockEvidence(
    ClinicalDraft draft,
  ) {
    final segments = <TranscriptSegment>[
      const TranscriptSegment(
        speaker: Speaker.medico,
        text: 'Buenos días, cuénteme qué le ocurre.',
      ),
    ];
    final evidence = <String, List<int>>{};
    for (final entry in draft.orderedSections) {
      final content = entry.value.content.trim();
      if (content.isEmpty) continue;
      // Cada sección cita 2 fragmentos: la pregunta del médico y la respuesta.
      final questionIdx = segments.length;
      segments.add(const TranscriptSegment(
        speaker: Speaker.medico,
        text: 'De acuerdo. ¿Puede darme más detalles?',
      ));
      final answerIdx = segments.length;
      segments.add(TranscriptSegment(speaker: Speaker.paciente, text: content));
      evidence[entry.key] = [questionIdx, answerIdx];
    }
    return (transcript: Transcript(segments: segments), evidence: evidence);
  }
}

final consultationRepositoryProvider = Provider<ConsultationRepository>((ref) {
  return ConsultationRepositoryImpl(
    ref.watch(consultationRemoteDataSourceProvider),
  );
});
