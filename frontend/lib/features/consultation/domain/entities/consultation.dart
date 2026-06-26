import 'package:escriba_clinico/features/consultation/domain/entities/clinical_draft.dart';
import 'package:escriba_clinico/models/consultation_type.dart';

/// Resultado de una consulta procesada: el borrador listo para revisión.
class Consultation {
  Consultation({
    required this.id,
    required this.consultationType,
    required this.documentTitle,
    required this.sectionLabels,
    required this.draft,
  });

  final String id;
  final ConsultationType consultationType;
  final String documentTitle;
  final Map<String, String> sectionLabels;
  final ClinicalDraft draft;
}
