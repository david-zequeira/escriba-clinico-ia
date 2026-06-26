import 'package:escriba_clinico/features/consultation/domain/entities/clinical_draft.dart';
import 'package:escriba_clinico/models/consultation_type.dart';
import 'package:escriba_clinico/models/document_templates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClinicalDraft.normalize', () {
    test('completa todas las secciones de la plantilla en orden', () {
      final draft = ClinicalDraft(
        documentType: ConsultationType.admissionInterview,
        sections: {'plan': ClinicalSection(content: 'reposo')},
      );

      final normalized = ClinicalDraft.normalize(draft);

      final expectedKeys = DocumentTemplates.forType(
        ConsultationType.admissionInterview,
      ).map((d) => d.key).toList();

      expect(normalized.sections.keys.toList(), expectedKeys);
      expect(normalized.sections['plan']!.content, 'reposo');
      expect(normalized.sections['motivo_ingreso']!.content, isEmpty);
    });
  });

  test('orderedSections respeta el orden de la plantilla', () {
    final draft = ClinicalDraft(
      documentType: ConsultationType.evolution,
      sections: const {},
    );

    final keys = draft.orderedSections.map((e) => e.key).toList();

    expect(
      keys,
      DocumentTemplates.forType(ConsultationType.evolution)
          .map((d) => d.key)
          .toList(),
    );
  });

  group('ClinicalDraft.copyWithSection', () {
    test('actualiza el contenido y conserva needsConfirmation', () {
      final original = ClinicalDraft(
        documentType: ConsultationType.admissionInterview,
        sections: {
          'plan': ClinicalSection(content: 'a', needsConfirmation: true),
        },
      );

      final updated = original.copyWithSection('plan', 'b');

      expect(updated.sections['plan']!.content, 'b');
      expect(updated.sections['plan']!.needsConfirmation, isTrue);
    });

    test('no muta el borrador original (inmutable)', () {
      final original = ClinicalDraft(
        documentType: ConsultationType.admissionInterview,
        sections: {'plan': ClinicalSection(content: 'a')},
      );

      final updated = original.copyWithSection('plan', 'b');

      expect(original.sections['plan']!.content, 'a');
      expect(identical(updated, original), isFalse);
    });
  });
}
