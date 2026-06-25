import 'package:dio/dio.dart';

import 'config.dart';
import '../models/clinical_note.dart';
import '../models/consultation_type.dart';

/// Cliente HTTP alineado con el backend FastAPI.
class ApiClient {
  ApiClient()
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(seconds: 120),
          ),
        );

  final Dio _dio;

  String get baseUrl => AppConfig.apiBaseUrl;

  /// Comprueba que el backend responde (GET /health).
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
    required ConsultationType type,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/consultations',
        data: {
          'patient_id': patientId,
          'consultation_type': type.apiValue,
        },
      );
      return res.data!['id'] as String;
    } on DioException catch (e) {
      throw _friendlyError('crear la consulta', e);
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
      throw _friendlyError('subir el audio', e);
    }
  }

  Future<String> waitForCompletion(
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
        if (status == 'completed') return status;
        if (status == 'failed') {
          throw Exception(res.data!['error']?.toString() ?? 'Procesamiento fallido en el servidor');
        }
      } on DioException catch (e) {
        throw _friendlyError('consultar el estado', e);
      }
      await Future<void>.delayed(interval);
    }
    throw Exception('Tiempo de espera agotado. ¿Sigue el backend en marcha?');
  }

  Future<ConsultationResult> getConsultation(String consultationId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/consultations/$consultationId');
      final data = res.data!;
      return ConsultationResult(
        id: data['id'] as String,
        consultationType: ConsultationType.fromApi(data['consultation_type'] as String),
        documentTitle: data['document_title'] as String,
        sectionLabels: Map<String, String>.from(data['section_labels'] as Map),
        draft: ClinicalDraft.fromJson(data['clinical_draft'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw _friendlyError('obtener el borrador', e);
    }
  }

  Exception _friendlyError(String action, DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return Exception(
        'No se pudo conectar con el backend ($baseUrl) al $action.\n'
        '¿Está arrancado? cd backend && source .venv/bin/activate && python -m app',
      );
    }
    final detail = e.response?.data?.toString() ?? e.message;
    return Exception('Error al $action: $detail');
  }
}

class ConsultationResult {
  ConsultationResult({
    required this.id,
    required this.consultationType,
    required this.documentTitle,
    required this.sectionLabels,
    required this.draft,
  });

  final String id;
  final ConsultationType consultationType;
  final String documentTitle;
  final Map<String, String> sectionLabels;
  final ClinicalDraft draft;
}
