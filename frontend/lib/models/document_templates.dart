import 'package:escriba_clinico/l10n/app_localizations.dart';
import 'package:escriba_clinico/models/consultation_type.dart';

/// Texto traducible de una sección (etiqueta o pista) resuelto vía i18n.
typedef SectionText = String Function(AppLocalizations l);

/// Definición de un campo de la planilla clínica (espejo del backend).
/// `label`/`hint` son funciones de [AppLocalizations] para soportar i18n.
class DocumentSectionDef {
  const DocumentSectionDef({
    required this.key,
    required this.label,
    required this.hint,
  });

  final String key;
  final SectionText label;
  final SectionText hint;
}

/// Plantillas ordenadas por tipo de documento (LOINC / estándar hospitalario UE).
abstract final class DocumentTemplates {
  static final admission = <DocumentSectionDef>[
    DocumentSectionDef(
      key: 'motivo_ingreso',
      label: (l) => l.admMotivoLabel,
      hint: (l) => l.admMotivoHint,
    ),
    DocumentSectionDef(
      key: 'enfermedad_actual',
      label: (l) => l.admEnfermedadLabel,
      hint: (l) => l.admEnfermedadHint,
    ),
    DocumentSectionDef(
      key: 'antecedentes',
      label: (l) => l.admAntecedentesLabel,
      hint: (l) => l.admAntecedentesHint,
    ),
    DocumentSectionDef(
      key: 'exploracion_fisica',
      label: (l) => l.admExploracionLabel,
      hint: (l) => l.admExploracionHint,
    ),
    DocumentSectionDef(
      key: 'pruebas_complementarias',
      label: (l) => l.admPruebasLabel,
      hint: (l) => l.admPruebasHint,
    ),
    DocumentSectionDef(
      key: 'juicio_clinico',
      label: (l) => l.admJuicioLabel,
      hint: (l) => l.admJuicioHint,
    ),
    DocumentSectionDef(
      key: 'plan',
      label: (l) => l.admPlanLabel,
      hint: (l) => l.admPlanHint,
    ),
  ];

  static final treatmentOrders = <DocumentSectionDef>[
    DocumentSectionDef(
      key: 'contexto',
      label: (l) => l.trtContextoLabel,
      hint: (l) => l.trtContextoHint,
    ),
    DocumentSectionDef(
      key: 'indicaciones_farmacologicas',
      label: (l) => l.trtFarmaLabel,
      hint: (l) => l.trtFarmaHint,
    ),
    DocumentSectionDef(
      key: 'indicaciones_no_farmacologicas',
      label: (l) => l.trtNoFarmaLabel,
      hint: (l) => l.trtNoFarmaHint,
    ),
    DocumentSectionDef(
      key: 'vigilancia',
      label: (l) => l.trtVigilanciaLabel,
      hint: (l) => l.trtVigilanciaHint,
    ),
    DocumentSectionDef(
      key: 'observaciones',
      label: (l) => l.trtObservacionesLabel,
      hint: (l) => l.trtObservacionesHint,
    ),
  ];

  static final evolution = <DocumentSectionDef>[
    DocumentSectionDef(
      key: 'subjetivo',
      label: (l) => l.evoSubjetivoLabel,
      hint: (l) => l.evoSubjetivoHint,
    ),
    DocumentSectionDef(
      key: 'objetivo',
      label: (l) => l.evoObjetivoLabel,
      hint: (l) => l.evoObjetivoHint,
    ),
    DocumentSectionDef(
      key: 'evolucion',
      label: (l) => l.evoEvolucionLabel,
      hint: (l) => l.evoEvolucionHint,
    ),
    DocumentSectionDef(
      key: 'juicio_clinico',
      label: (l) => l.evoJuicioLabel,
      hint: (l) => l.evoJuicioHint,
    ),
    DocumentSectionDef(
      key: 'plan',
      label: (l) => l.evoPlanLabel,
      hint: (l) => l.evoPlanHint,
    ),
  ];

  static List<DocumentSectionDef> forType(ConsultationType type) => switch (type) {
        ConsultationType.admissionInterview => admission,
        ConsultationType.treatmentOrders => treatmentOrders,
        ConsultationType.evolution => evolution,
      };
}
