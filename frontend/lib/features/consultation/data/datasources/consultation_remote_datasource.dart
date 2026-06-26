import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:escriba_clinico/core/config.dart';
import 'package:escriba_clinico/core/network/dio_provider.dart';
import 'package:escriba_clinico/core/network/network_exceptions.dart';

/// Fuente de datos remota: habla HTTP con el backend FastAPI.
/// Devuelve datos crudos (maps/primitivos); el mapeo a entidades es del repositorio.
class ConsultationRemoteDataSource {
  ConsultationRemoteDataSource(this._dio);

  final Dio _dio;

  String get _baseUrl => AppConfig.apiBaseUrl;

  Future<bool> checkHealth() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/health');
      return res.data?['status'] == 'ok';
    } on DioException {
      return false;
    }
  }

  Future<String> createConsultation({
    required String patientId,
    required String typeApiValue,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/consultations',
        data: {'patient_id': patientId, 'consultation_type': typeApiValue},
      );
      return res.data!['id'] as String;
    } on DioException catch (e) {
      throw friendlyApiError('crear la consulta', _baseUrl, e);
    }
  }

  Future<void> uploadAudio(
    String consultationId,
    List<int> audioBytes, {
    String filename = 'consulta.m4a',
  }) async {
    try {
      await _dio.post(
        '/consultations/$consultationId/audio',
        data: FormData.fromMap({
          'audio': MultipartFile.fromBytes(audioBytes, filename: filename),
        }),
      );
    } on DioException catch (e) {
      throw friendlyApiError('subir el audio', _baseUrl, e);
    }
  }

  /// Hace polling del estado hasta `completed`/`failed` o agota el tiempo.
  Future<void> waitForCompletion(
    String consultationId, {
    Duration timeout = const Duration(minutes: 5),
    Duration interval = const Duration(seconds: 2),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      try {
        final res = await _dio.get<Map<String, dynamic>>(
          '/consultations/$consultationId/status',
        );
        final status = res.data!['status'] as String;
        if (status == 'completed') return;
        if (status == 'failed') {
          throw Exception(res.data!['error']?.toString() ??
              'Procesamiento fallido en el servidor');
        }
      } on DioException catch (e) {
        throw friendlyApiError('consultar el estado', _baseUrl, e);
      }
      await Future<void>.delayed(interval);
    }
    throw Exception('Tiempo de espera agotado. ¿Sigue el backend en marcha?');
  }

  Future<Map<String, dynamic>> fetchConsultation(String consultationId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/consultations/$consultationId',
      );
      return res.data!;
    } on DioException catch (e) {
      throw friendlyApiError('obtener el borrador', _baseUrl, e);
    }
  }
}

final consultationRemoteDataSourceProvider =
    Provider<ConsultationRemoteDataSource>((ref) {
  return ConsultationRemoteDataSource(ref.watch(dioProvider));
});
