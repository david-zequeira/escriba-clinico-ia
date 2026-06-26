/// Textos de UI para identificación del paciente (el API sigue usando `patient_id`).
abstract final class PatientIdentityLabels {
  static const fieldLabel = 'Nº de identidad del paciente';
  static const hint = 'DNI, NIE u otro identificador';
  static const requiredMessage = 'Introduce el número de identidad del paciente';
}
