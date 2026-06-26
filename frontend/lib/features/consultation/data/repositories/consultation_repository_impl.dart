import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:escriba_clinico/features/consultation/data/datasources/consultation_remote_datasource.dart';
import 'package:escriba_clinico/features/consultation/domain/entities/clinical_draft.dart';
import 'package:escriba_clinico/features/consultation/domain/entities/consultation.dart';
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
    return Consultation(
      id: data['id'] as String,
      consultationType:
          ConsultationType.fromApi(data['consultation_type'] as String),
      documentTitle: data['document_title'] as String,
      sectionLabels: Map<String, String>.from(data['section_labels'] as Map),
      draft: _draftFromJson(data['clinical_draft'] as Map<String, dynamic>),
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
}

final consultationRepositoryProvider = Provider<ConsultationRepository>((ref) {
  return ConsultationRepositoryImpl(
    ref.watch(consultationRemoteDataSourceProvider),
  );
});
