/// Espejo del modelo del backend: borrador de historia clínica revisable.
class ClinicalSection {
  ClinicalSection({this.content = '', this.needsConfirmation = false});

  String content;
  bool needsConfirmation;

  factory ClinicalSection.fromJson(Map<String, dynamic> j) => ClinicalSection(
        content: j['content'] ?? '',
        needsConfirmation: j['needs_confirmation'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'content': content,
        'needs_confirmation': needsConfirmation,
      };
}

class ClinicalNote {
  ClinicalNote({
    required this.motivoConsulta,
    required this.anamnesis,
    required this.exploracion,
    required this.diagnostico,
    required this.plan,
  });

  ClinicalSection motivoConsulta;
  ClinicalSection anamnesis;
  ClinicalSection exploracion;
  ClinicalSection diagnostico;
  ClinicalSection plan;

  factory ClinicalNote.fromJson(Map<String, dynamic> j) => ClinicalNote(
        motivoConsulta: ClinicalSection.fromJson(j['motivo_consulta'] ?? {}),
        anamnesis: ClinicalSection.fromJson(j['anamnesis'] ?? {}),
        exploracion: ClinicalSection.fromJson(j['exploracion'] ?? {}),
        diagnostico: ClinicalSection.fromJson(j['diagnostico'] ?? {}),
        plan: ClinicalSection.fromJson(j['plan'] ?? {}),
      );

  Map<String, dynamic> toJson() => {
        'motivo_consulta': motivoConsulta.toJson(),
        'anamnesis': anamnesis.toJson(),
        'exploracion': exploracion.toJson(),
        'diagnostico': diagnostico.toJson(),
        'plan': plan.toJson(),
      };
}
