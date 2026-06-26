import 'package:escriba_clinico/models/consultation_type.dart';

/// Definición de un campo de la planilla clínica (espejo del backend).
class DocumentSectionDef {
  const DocumentSectionDef({
    required this.key,
    required this.label,
    required this.hint,
  });

  final String key;
  final String label;
  final String hint;
}

/// Plantillas ordenadas por tipo de documento (LOINC / estándar hospitalario UE).
abstract final class DocumentTemplates {
  static const admission = [
    DocumentSectionDef(
      key: 'motivo_ingreso',
      label: 'Motivo de ingreso',
      hint: 'Motivo principal que origina el ingreso hospitalario.',
    ),
    DocumentSectionDef(
      key: 'enfermedad_actual',
      label: 'Enfermedad actual',
      hint: 'Cronología y características del cuadro actual.',
    ),
    DocumentSectionDef(
      key: 'antecedentes',
      label: 'Antecedentes',
      hint: 'Personales, familiares, alergias y medicación habitual.',
    ),
    DocumentSectionDef(
      key: 'exploracion_fisica',
      label: 'Exploración física',
      hint: 'Hallazgos objetivos de la exploración.',
    ),
    DocumentSectionDef(
      key: 'pruebas_complementarias',
      label: 'Pruebas complementarias',
      hint: 'Analítica, imagen u otras pruebas relevantes.',
    ),
    DocumentSectionDef(
      key: 'juicio_clinico',
      label: 'Juicio clínico (borrador)',
      hint: 'Impresión diagnóstica preliminar. Requiere validación del médico.',
    ),
    DocumentSectionDef(
      key: 'plan',
      label: 'Plan de ingreso y actuación',
      hint: 'Conducta terapéutica, estudios pendientes y criterios de ingreso.',
    ),
  ];

  static const treatmentOrders = [
    DocumentSectionDef(
      key: 'contexto',
      label: 'Contexto del paciente',
      hint: 'Situación clínica actual del paciente ingresado.',
    ),
    DocumentSectionDef(
      key: 'indicaciones_farmacologicas',
      label: 'Indicaciones farmacológicas',
      hint: 'Fármacos, dosis, vía y frecuencia.',
    ),
    DocumentSectionDef(
      key: 'indicaciones_no_farmacologicas',
      label: 'Indicaciones no farmacológicas y cuidados',
      hint: 'Dieta, movilización, curas y otras medidas.',
    ),
    DocumentSectionDef(
      key: 'vigilancia',
      label: 'Vigilancia y constantes',
      hint: 'Controles, monitorización y alertas.',
    ),
    DocumentSectionDef(
      key: 'observaciones',
      label: 'Observaciones y prioridad',
      hint: 'Notas adicionales o prioridad de actuación.',
    ),
  ];

  static const evolution = [
    DocumentSectionDef(
      key: 'subjetivo',
      label: 'Subjetivo',
      hint: 'Síntomas referidos por el paciente.',
    ),
    DocumentSectionDef(
      key: 'objetivo',
      label: 'Objetivo y exploración',
      hint: 'Constantes, exploración y datos objetivos.',
    ),
    DocumentSectionDef(
      key: 'evolucion',
      label: 'Evolución clínica',
      hint: 'Curso del cuadro desde el último registro.',
    ),
    DocumentSectionDef(
      key: 'juicio_clinico',
      label: 'Juicio clínico (borrador)',
      hint: 'Impresión diagnóstica actual. Requiere validación del médico.',
    ),
    DocumentSectionDef(
      key: 'plan',
      label: 'Plan terapéutico y próximos pasos',
      hint: 'Cambios de tratamiento y seguimiento.',
    ),
  ];

  static List<DocumentSectionDef> forType(ConsultationType type) => switch (type) {
        ConsultationType.admissionInterview => admission,
        ConsultationType.treatmentOrders => treatmentOrders,
        ConsultationType.evolution => evolution,
      };
}
