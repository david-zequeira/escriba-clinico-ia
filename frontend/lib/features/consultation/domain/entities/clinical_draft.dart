import 'package:escriba_clinico/models/consultation_type.dart';
import 'package:escriba_clinico/models/document_templates.dart';

/// Sección editable de un borrador clínico. Entidad de dominio (sin serialización).
class ClinicalSection {
  ClinicalSection({this.content = '', this.needsConfirmation = false});

  String content;
  bool needsConfirmation;
}

/// Borrador clínico tipado (polimórfico según el tipo de documento).
/// Entidad de dominio pura: la (de)serialización vive en la capa data.
class ClinicalDraft {
  ClinicalDraft({
    required this.documentType,
    required this.sections,
    this.generatedByAi = true,
  });

  final ConsultationType documentType;
  final Map<String, ClinicalSection> sections;
  final bool generatedByAi;

  /// Garantiza todos los campos de la plantilla, en orden fijo para la UI.
  static ClinicalDraft normalize(ClinicalDraft draft) {
    final merged = <String, ClinicalSection>{};
    for (final def in DocumentTemplates.forType(draft.documentType)) {
      merged[def.key] = draft.sections[def.key] ?? ClinicalSection();
    }
    return ClinicalDraft(
      documentType: draft.documentType,
      sections: merged,
      generatedByAi: draft.generatedByAi,
    );
  }

  /// Campos ordenados según la plantilla del tipo de documento.
  List<MapEntry<String, ClinicalSection>> get orderedSections {
    return DocumentTemplates.forType(documentType)
        .map((def) => MapEntry(def.key, sections[def.key] ?? ClinicalSection()))
        .toList();
  }

  ClinicalDraft copyWithSection(String key, String content) {
    final section = sections[key] ?? ClinicalSection();
    return ClinicalDraft(
      documentType: documentType,
      generatedByAi: generatedByAi,
      sections: {
        ...sections,
        key: ClinicalSection(
          content: content,
          needsConfirmation: section.needsConfirmation,
        ),
      },
    );
  }
}
