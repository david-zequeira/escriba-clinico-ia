import 'package:escriba_clinico/features/consultation/domain/entities/clinical_draft.dart';
import 'package:escriba_clinico/features/consultation/domain/entities/transcript.dart';
import 'package:escriba_clinico/models/consultation_type.dart';

/// Resultado de una consulta procesada: el borrador listo para revisión.
class Consultation {
  Consultation({
    required this.id,
    required this.consultationType,
    required this.documentTitle,
    required this.sectionLabels,
    required this.draft,
    this.transcript = const Transcript(),
    this.evidenceBySection = const {},
  });

  final String id;
  final ConsultationType consultationType;
  final String documentTitle;
  final Map<String, String> sectionLabels;
  final ClinicalDraft draft;

  /// Transcripción de la conversación (origen del borrador).
  final Transcript transcript;

  /// Evidencia por sección: para cada clave de campo, los índices de los
  /// segmentos de [transcript] que respaldan ese contenido (trazabilidad / Clase I).
  final Map<String, List<int>> evidenceBySection;
}
