import '../models/consultation_type.dart';
import 'document_templates.dart';

/// Sección editable de un borrador clínico.
class ClinicalSection {
  ClinicalSection({this.content = '', this.needsConfirmation = false});

  String content;
  bool needsConfirmation;

  factory ClinicalSection.fromJson(Map<String, dynamic> j) => ClinicalSection(
        content: j['content'] ?? '',
        needsConfirmation: j['needs_confirmation'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'content': content,
        'needs_confirmation': needsConfirmation,
      };
}

/// Borrador clínico tipado (polimórfico según document_type del backend).
class ClinicalDraft {
  ClinicalDraft({
    required this.documentType,
    required this.sections,
    this.generatedByAi = true,
  });

  final ConsultationType documentType;
  final Map<String, ClinicalSection> sections;
  final bool generatedByAi;

  factory ClinicalDraft.fromJson(Map<String, dynamic> j) {
    final type = ConsultationType.fromApi(j['document_type'] as String? ?? '');
    final sections = <String, ClinicalSection>{};
    for (final entry in j.entries) {
      if (entry.value is! Map) continue;
      if (_metaFields.contains(entry.key)) continue;
      sections[entry.key] = ClinicalSection.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
      );
    }
    return normalize(
      ClinicalDraft(
        documentType: type,
        sections: sections,
        generatedByAi: j['generated_by_ai'] as bool? ?? true,
      ),
    );
  }

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

  Map<String, dynamic> toJson() => {
        'document_type': documentType.apiValue,
        'generated_by_ai': generatedByAi,
        ...sections.map((k, v) => MapEntry(k, v.toJson())),
      };

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

  static const _metaFields = {'document_type', 'generated_by_ai', 'model_name', 'created_at'};
}
