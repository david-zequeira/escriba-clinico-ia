import 'package:flutter/material.dart';

/// Tipos de documento clínico (espejo del backend).
enum ConsultationType {
  admissionInterview('admission_interview'),
  treatmentOrders('treatment_orders'),
  evolution('evolution');

  const ConsultationType(this.apiValue);
  final String apiValue;

  String get title => switch (this) {
        ConsultationType.admissionInterview => 'Historia clínica de ingreso',
        ConsultationType.treatmentOrders => 'Indicaciones de tratamiento',
        ConsultationType.evolution => 'Nota de evolución',
      };

  String get subtitle => switch (this) {
        ConsultationType.admissionInterview =>
          'Entrevista médico-paciente para valoración de ingreso.',
        ConsultationType.treatmentOrders =>
          'Dictado del médico con indicaciones para paciente ingresado.',
        ConsultationType.evolution =>
          'Evolución clínica de paciente ya ingresado.',
      };

  String get recordingHint => switch (this) {
        ConsultationType.admissionInterview =>
          'Graba la conversación con el paciente (consentimiento previo).',
        ConsultationType.treatmentOrders =>
          'Graba tus indicaciones en voz alta (sin paciente).',
        ConsultationType.evolution =>
          'Graba la evolución del paciente ingresado.',
      };

  String get shortLabel => switch (this) {
        ConsultationType.admissionInterview => 'Ingreso',
        ConsultationType.treatmentOrders => 'Indicaciones',
        ConsultationType.evolution => 'Evolución',
      };

  IconData get icon => switch (this) {
        ConsultationType.admissionInterview => Icons.people_alt_outlined,
        ConsultationType.treatmentOrders => Icons.medication_liquid_outlined,
        ConsultationType.evolution => Icons.show_chart_outlined,
      };

  static ConsultationType fromApi(String value) => ConsultationType.values.firstWhere(
        (t) => t.apiValue == value,
        orElse: () => ConsultationType.admissionInterview,
      );
}
