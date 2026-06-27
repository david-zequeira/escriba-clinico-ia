import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:escriba_clinico/features/consultation/data/repositories/consultation_repository_impl.dart';
import 'package:escriba_clinico/features/consultation/domain/entities/clinical_draft.dart';
import 'package:escriba_clinico/features/consultation/domain/entities/transcript.dart';
import 'package:escriba_clinico/features/consultation/domain/repositories/consultation_repository.dart';
import 'package:escriba_clinico/models/consultation_type.dart';

enum ConsultationStage { idle, recording, processing, review, done, error }

class ConsultationState {
  ConsultationState({
    this.stage = ConsultationStage.idle,
    this.consultationType,
    this.documentTitle,
    this.sectionLabels = const {},
    this.note,
    this.transcript = const Transcript(),
    this.evidenceBySection = const {},
    this.consultationId,
    this.patientId,
    this.errorMessage,
  });

  final ConsultationStage stage;
  final ConsultationType? consultationType;
  final String? documentTitle;
  final Map<String, String> sectionLabels;
  final ClinicalDraft? note;
  final Transcript transcript;
  final Map<String, List<int>> evidenceBySection;
  final String? consultationId;
  final String? patientId;
  final String? errorMessage;

  ConsultationState copyWith({
    ConsultationStage? stage,
    ConsultationType? consultationType,
    String? documentTitle,
    Map<String, String>? sectionLabels,
    ClinicalDraft? note,
    Transcript? transcript,
    Map<String, List<int>>? evidenceBySection,
    String? consultationId,
    String? patientId,
    String? errorMessage,
  }) =>
      ConsultationState(
        stage: stage ?? this.stage,
        consultationType: consultationType ?? this.consultationType,
        documentTitle: documentTitle ?? this.documentTitle,
        sectionLabels: sectionLabels ?? this.sectionLabels,
        note: note ?? this.note,
        transcript: transcript ?? this.transcript,
        evidenceBySection: evidenceBySection ?? this.evidenceBySection,
        consultationId: consultationId ?? this.consultationId,
        patientId: patientId ?? this.patientId,
        errorMessage: errorMessage,
      );
}

/// Orquesta el flujo de consulta apoyándose en [ConsultationRepository].
/// No conoce HTTP ni JSON: solo el contrato del dominio.
class ConsultationController extends StateNotifier<ConsultationState> {
  ConsultationController(this._repo) : super(ConsultationState());

  final ConsultationRepository _repo;

  void selectType(ConsultationType type) {
    state = ConsultationState(consultationType: type, stage: ConsultationStage.idle);
  }

  /// Crea la consulta en el backend ANTES de capturar (para tener un id real con
  /// el que abrir el canal de streaming en vivo) y deja la etapa en `recording`.
  /// Devuelve el id, o `null` si falla (la etapa pasa a `error`).
  ///
  /// Es el primer paso del flujo unificado de captura: `beginSession` →
  /// streaming en vivo → [finalizeWithAudio].
  Future<String?> beginSession(String patientId) async {
    final type = state.consultationType;
    if (type == null) return null;

    state = state.copyWith(stage: ConsultationStage.recording, errorMessage: null);
    try {
      final id = await _repo.createConsultation(patientId: patientId, type: type);
      state = state.copyWith(consultationId: id, patientId: patientId);
      return id;
    } catch (e) {
      state = state.copyWith(
        stage: ConsultationStage.error,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Finaliza una sesión ya iniciada con [beginSession]: sube el audio capturado
  /// a la consulta existente y trae el borrador → etapa `review`.
  Future<void> finalizeWithAudio(
    List<int> audioBytes, {
    String filename = 'consulta.m4a',
  }) async {
    final id = state.consultationId;
    if (id == null) return;
    await _processAudio(id, state.patientId ?? '', audioBytes, filename);
  }

  /// Flujo batch de un solo paso: crea la consulta, sube el audio y trae el
  /// borrador. Se mantiene para la subida directa de un audio ya grabado.
  Future<void> submitAudio(
    List<int> audioBytes,
    String patientId, {
    String filename = 'consulta.m4a',
  }) async {
    final type = state.consultationType;
    if (type == null) return;

    state = state.copyWith(stage: ConsultationStage.processing, errorMessage: null);
    try {
      final id = await _repo.createConsultation(patientId: patientId, type: type);
      await _processAudio(id, patientId, audioBytes, filename);
    } catch (e) {
      state = state.copyWith(
        stage: ConsultationStage.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Sube el audio a una consulta ya creada, espera el procesamiento y publica
  /// el borrador en la etapa `review`. Único punto que orquesta upload→draft.
  Future<void> _processAudio(
    String id,
    String patientId,
    List<int> audioBytes,
    String filename,
  ) async {
    state = state.copyWith(stage: ConsultationStage.processing, errorMessage: null);
    try {
      await _repo.uploadAudio(id, audioBytes, filename: filename);
      await _repo.waitForCompletion(id);
      final result = await _repo.getConsultation(id);
      state = state.copyWith(
        stage: ConsultationStage.review,
        consultationId: result.id,
        patientId: patientId,
        documentTitle: result.documentTitle,
        sectionLabels: result.sectionLabels,
        note: result.draft,
        transcript: result.transcript,
        evidenceBySection: result.evidenceBySection,
      );
    } catch (e) {
      state = state.copyWith(
        stage: ConsultationStage.error,
        errorMessage: e.toString(),
      );
    }
  }

  void updateSectionContent(String key, String content) {
    final draft = state.note;
    if (draft == null) return;
    state = state.copyWith(note: draft.copyWithSection(key, content));
  }

  void markReviewedLocally() {
    state = state.copyWith(stage: ConsultationStage.done);
  }

  void reset() {
    state = ConsultationState();
  }
}

final consultationProvider =
    StateNotifierProvider<ConsultationController, ConsultationState>(
  (ref) => ConsultationController(ref.watch(consultationRepositoryProvider)),
);
