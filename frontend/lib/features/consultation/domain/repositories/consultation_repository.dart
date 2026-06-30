import 'package:escriba_clinico/features/consultation/domain/entities/consultation.dart';
import 'package:escriba_clinico/models/consultation_type.dart';

/// Puerto del dominio: contrato de persistencia/proceso de consultas.
/// La capa de presentación depende de ESTA interfaz, nunca de la implementación
/// concreta (HTTP). Así el backend, los mocks o los tests son intercambiables.
abstract class ConsultationRepository {
  /// ¿El backend responde? (para avisar antes de grabar).
  Future<bool> isBackendReachable();

  /// Crea la consulta y devuelve su id.
  Future<String> createConsultation({
    required String patientId,
    required ConsultationType type,
  });

  /// Sube el audio capturado para que el backend lo procese (async).
  Future<void> uploadAudio(
    String consultationId,
    List<int> audioBytes, {
    String filename,
  });

  /// Espera (polling) hasta que el procesamiento termina o falla.
  Future<void> waitForCompletion(String consultationId);

  /// Obtiene el borrador estructurado ya procesado.
  Future<Consultation> getConsultation(String consultationId);
}
