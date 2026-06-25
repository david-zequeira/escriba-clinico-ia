import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../models/clinical_note.dart';
import '../../models/consultation_type.dart';

enum ConsultationStage { idle, recording, processing, review, done, error }

class ConsultationState {
  ConsultationState({
    this.stage = ConsultationStage.idle,
    this.consultationType,
    this.documentTitle,
    this.sectionLabels = const {},
    this.note,
    this.consultationId,
    this.patientId,
    this.errorMessage,
  });

  final ConsultationStage stage;
  final ConsultationType? consultationType;
  final String? documentTitle;
  final Map<String, String> sectionLabels;
  final ClinicalDraft? note;
  final String? consultationId;
  final String? patientId;
  final String? errorMessage;

  ConsultationState copyWith({
    ConsultationStage? stage,
    ConsultationType? consultationType,
    String? documentTitle,
    Map<String, String>? sectionLabels,
    ClinicalDraft? note,
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
        consultationId: consultationId ?? this.consultationId,
        patientId: patientId ?? this.patientId,
        errorMessage: errorMessage,
      );
}

class ConsultationController extends StateNotifier<ConsultationState> {
  ConsultationController(this._api) : super(ConsultationState());

  final ApiClient _api;

  void selectType(ConsultationType type) {
    state = ConsultationState(consultationType: type, stage: ConsultationStage.idle);
  }

  Future<void> submitAudio(
    List<int> audioBytes,
    String patientId, {
    String filename = 'consulta.m4a',
  }) async {
    final type = state.consultationType;
    if (type == null) return;

    state = state.copyWith(stage: ConsultationStage.processing, errorMessage: null);
    try {
      final id = await _api.createConsultation(patientId: patientId, type: type);
      await _api.uploadAudio(id, audioBytes, filename: filename);
      await _api.waitForCompletion(id);
      final result = await _api.getConsultation(id);
      state = state.copyWith(
        stage: ConsultationStage.review,
        consultationId: result.id,
        patientId: patientId,
        documentTitle: result.documentTitle,
        sectionLabels: result.sectionLabels,
        note: ClinicalDraft.normalize(result.draft),
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

final apiClientProvider = Provider((ref) => ApiClient());

final consultationProvider =
    StateNotifierProvider<ConsultationController, ConsultationState>(
  (ref) => ConsultationController(ref.read(apiClientProvider)),
);
