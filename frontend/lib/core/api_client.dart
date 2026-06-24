import 'package:dio/dio.dart';

import 'config.dart';

/// Cliente HTTP central. Añade aquí interceptores de auth y reintentos.
class ApiClient {
  ApiClient() : _dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));

  final Dio _dio;

  /// Sube el audio de la consulta y recibe el borrador estructurado.
  Future<Map<String, dynamic>> uploadConsultation(
    List<int> audioBytes, {
    String specialty = 'general',
  }) async {
    final form = FormData.fromMap({
      'specialty': specialty,
      'audio': MultipartFile.fromBytes(audioBytes, filename: 'consulta.m4a'),
    });
    final res = await _dio.post('/consultations', data: form);
    return res.data as Map<String, dynamic>;
  }

  /// Envía la nota revisada por el médico para volcarla al HIS (FHIR).
  Future<Map<String, dynamic>> validateNote(
    String consultationId,
    Map<String, dynamic> note,
    String patientId,
  ) async {
    final res = await _dio.post(
      '/consultations/$consultationId/validate',
      queryParameters: {'patient_id': patientId},
      data: note,
    );
    return res.data as Map<String, dynamic>;
  }
}
