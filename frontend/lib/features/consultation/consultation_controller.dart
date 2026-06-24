import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../models/clinical_note.dart';

enum ConsultationStage { idle, recording, processing, review, done, error }

class ConsultationState {
  ConsultationState({this.stage = ConsultationStage.idle, this.note, this.consultationId});
  final ConsultationStage stage;
  final ClinicalNote? note;
  final String? consultationId;

  ConsultationState copyWith({ConsultationStage? stage, ClinicalNote? note, String? consultationId}) =>
      ConsultationState(
        stage: stage ?? this.stage,
        note: note ?? this.note,
        consultationId: consultationId ?? this.consultationId,
      );
}

class ConsultationController extends StateNotifier<ConsultationState> {
  ConsultationController(this._api) : super(ConsultationState());
  final ApiClient _api;

  /// Sube el audio capturado y pasa a la fase de revisión con el borrador.
  Future<void> submitAudio(List<int> audioBytes) async {
    state = state.copyWith(stage: ConsultationStage.processing);
    try {
      final data = await _api.uploadConsultation(audioBytes);
      final note = ClinicalNote.fromJson(data['draft'] ?? {});
      state = state.copyWith(
        stage: ConsultationStage.review,
        note: note,
        consultationId: data['consultation_id'],
      );
    } catch (_) {
      state = state.copyWith(stage: ConsultationStage.error);
    }
  }

  /// El médico valida la nota revisada -> se vuelca al HIS.
  Future<void> validate(String patientId) async {
    if (state.note == null || state.consultationId == null) return;
    await _api.validateNote(state.consultationId!, state.note!.toJson(), patientId);
    state = state.copyWith(stage: ConsultationStage.done);
  }
}

final apiClientProvider = Provider((ref) => ApiClient());

final consultationProvider =
    StateNotifierProvider<ConsultationController, ConsultationState>(
  (ref) => ConsultationController(ref.read(apiClientProvider)),
);
