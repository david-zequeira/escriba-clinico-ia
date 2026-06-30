import 'package:flutter/material.dart';

import 'package:escriba_clinico/l10n/app_localizations.dart';

/// Tipos de documento clínico (espejo del backend).
/// Los textos visibles se resuelven vía i18n (`AppLocalizations`).
enum ConsultationType {
  admissionInterview('admission_interview'),
  treatmentOrders('treatment_orders'),
  evolution('evolution');

  const ConsultationType(this.apiValue);
  final String apiValue;

  String title(AppLocalizations l) => switch (this) {
        ConsultationType.admissionInterview => l.admissionTitle,
        ConsultationType.treatmentOrders => l.treatmentTitle,
        ConsultationType.evolution => l.evolutionTitle,
      };

  String subtitle(AppLocalizations l) => switch (this) {
        ConsultationType.admissionInterview => l.admissionSubtitle,
        ConsultationType.treatmentOrders => l.treatmentSubtitle,
        ConsultationType.evolution => l.evolutionSubtitle,
      };

  String recordingHint(AppLocalizations l) => switch (this) {
        ConsultationType.admissionInterview => l.admissionRecordingHint,
        ConsultationType.treatmentOrders => l.treatmentRecordingHint,
        ConsultationType.evolution => l.evolutionRecordingHint,
      };

  String shortLabel(AppLocalizations l) => switch (this) {
        ConsultationType.admissionInterview => l.admissionShort,
        ConsultationType.treatmentOrders => l.treatmentShort,
        ConsultationType.evolution => l.evolutionShort,
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
