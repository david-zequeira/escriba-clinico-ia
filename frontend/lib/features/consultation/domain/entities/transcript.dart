import 'package:escriba_clinico/l10n/app_localizations.dart';

/// Interlocutor de un segmento de transcripción (diarización médico/paciente).
enum Speaker {
  medico,
  paciente,
  desconocido;

  static Speaker fromApi(String? value) => switch (value) {
        'medico' => Speaker.medico,
        'paciente' => Speaker.paciente,
        _ => Speaker.desconocido,
      };

  /// Etiqueta traducida del interlocutor.
  String label(AppLocalizations l) => switch (this) {
        Speaker.medico => l.speakerDoctor,
        Speaker.paciente => l.speakerPatient,
        Speaker.desconocido => l.speakerUnknown,
      };
}

/// Un fragmento de la conversación, con interlocutor y marcas de tiempo.
class TranscriptSegment {
  const TranscriptSegment({
    required this.speaker,
    required this.text,
    this.startMs,
    this.endMs,
  });

  final Speaker speaker;
  final String text;
  final int? startMs;
  final int? endMs;
}

/// Transcripción completa de una consulta. Entidad de dominio.
class Transcript {
  const Transcript({this.segments = const []});

  final List<TranscriptSegment> segments;

  bool get isEmpty => segments.isEmpty;
  bool get isNotEmpty => segments.isNotEmpty;
}
