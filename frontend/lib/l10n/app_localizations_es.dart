// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get loginSubtitle => 'Acceso para personal sanitario';

  @override
  String get fieldUser => 'Usuario';

  @override
  String get validatorUser => 'Introduce tu usuario';

  @override
  String get fieldPassword => 'Contraseña';

  @override
  String get validatorPassword => 'Introduce tu contraseña';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get devCredentialsHint =>
      'Entorno de desarrollo: cualquier credencial válida.';

  @override
  String get toggleTheme => 'Cambiar tema';

  @override
  String get language => 'Idioma';

  @override
  String get spanish => 'Español';

  @override
  String get english => 'English';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get newDocument => 'Nuevo documento';

  @override
  String get newDocumentSubtitle =>
      'Elige el tipo de nota clínica a generar a partir del audio.';

  @override
  String get start => 'Comenzar';

  @override
  String get consentTitle => 'Consentimiento del paciente';

  @override
  String get consentBody =>
      'Confirma que el paciente ha sido informado y consiente la grabación de la consulta para generar un borrador clínico con asistencia de IA.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String connectedTo(String url) {
    return 'Conectado a $url';
  }

  @override
  String backendUnavailable(String url) {
    return 'Backend no disponible en $url';
  }

  @override
  String get backendStartHint =>
      'Arranca: cd backend && source .venv/bin/activate && python -m app';

  @override
  String get stopRecording => 'Detener grabación';

  @override
  String get finishing => 'Finalizando…';

  @override
  String get sendingToServer => 'Enviando al servidor…';

  @override
  String get pressToRecord => 'Pulsa para grabar';

  @override
  String get recordingInProgress => 'Grabando… pulsa detener o usa Espacio';

  @override
  String get spaceShortcutHint =>
      'Atajo: Espacio (si el foco no está en un campo)';

  @override
  String get progress => 'Progreso';

  @override
  String get savingAudioLocally => 'Guardando audio localmente…';

  @override
  String get processingOnServer =>
      'Procesando en el servidor (STT + borrador)…';

  @override
  String get stepRecording => 'Grabación';

  @override
  String get stepTranscription => 'Transcripción';

  @override
  String get stepClinicalDraft => 'Borrador clínico';

  @override
  String get review => 'Revisión';

  @override
  String get noDraftYet => 'Sin borrador todavía';

  @override
  String get aiBannerTitle => 'Borrador con asistencia de IA';

  @override
  String get aiBannerSubtitle =>
      'Los campos marcados como «Revisar» requieren confirmación explícita.';

  @override
  String fieldsFilledSummary(int filled, int total) {
    return '$filled de $total campos completados por la IA. Completa los vacíos y revisa el resto antes de confirmar.';
  }

  @override
  String get confirmReview => 'Confirmar revisión';

  @override
  String get draftMarkedReviewed =>
      'Borrador marcado como revisado (solo local)';

  @override
  String get sendToHis => 'Enviar al HIS';

  @override
  String get sendToHisTooltip =>
      'Disponible cuando se conecte al sistema del hospital';

  @override
  String get pendingFieldHint => 'Pendiente — completa manualmente…';

  @override
  String get conversation => 'Conversación';

  @override
  String get evidenceHintEmpty =>
      'Toca «ver evidencia» en un campo, o un fragmento aquí, para enlazarlos.';

  @override
  String get evidenceHintSelected =>
      'Resaltado: el origen del campo seleccionado.';

  @override
  String get noTranscript => 'Sin transcripción disponible.';

  @override
  String evidenceTitle(String label) {
    return 'Evidencia · $label';
  }

  @override
  String get showEvidence => 'Ver de dónde salió';

  @override
  String showEvidenceCount(int count) {
    return 'Ver de dónde salió ($count fragmentos)';
  }

  @override
  String get speakerDoctor => 'Médico';

  @override
  String get speakerPatient => 'Paciente';

  @override
  String get speakerUnknown => 'Sin identificar';

  @override
  String get fieldStatusAi => 'IA';

  @override
  String get fieldStatusEmpty => 'Vacío';

  @override
  String get fieldStatusReview => 'Revisar';

  @override
  String get patientIdLabel => 'Nº de identidad del paciente';

  @override
  String get patientIdHint => 'DNI, NIE u otro identificador';

  @override
  String get patientIdRequired =>
      'Introduce el número de identidad del paciente';

  @override
  String get audioPathUnavailable => 'Ruta de audio no disponible.';

  @override
  String get emptyRecording =>
      'La grabación está vacía. Comprueba el micrófono.';

  @override
  String get admissionTitle => 'Historia clínica de ingreso';

  @override
  String get admissionSubtitle =>
      'Entrevista médico-paciente para valoración de ingreso.';

  @override
  String get admissionRecordingHint =>
      'Graba la conversación con el paciente (consentimiento previo).';

  @override
  String get admissionShort => 'Ingreso';

  @override
  String get treatmentTitle => 'Indicaciones de tratamiento';

  @override
  String get treatmentSubtitle =>
      'Dictado del médico con indicaciones para paciente ingresado.';

  @override
  String get treatmentRecordingHint =>
      'Graba tus indicaciones en voz alta (sin paciente).';

  @override
  String get treatmentShort => 'Indicaciones';

  @override
  String get evolutionTitle => 'Nota de evolución';

  @override
  String get evolutionSubtitle => 'Evolución clínica de paciente ya ingresado.';

  @override
  String get evolutionRecordingHint =>
      'Graba la evolución del paciente ingresado.';

  @override
  String get evolutionShort => 'Evolución';

  @override
  String get admMotivoLabel => 'Motivo de ingreso';

  @override
  String get admMotivoHint =>
      'Motivo principal que origina el ingreso hospitalario.';

  @override
  String get admEnfermedadLabel => 'Enfermedad actual';

  @override
  String get admEnfermedadHint =>
      'Cronología y características del cuadro actual.';

  @override
  String get admAntecedentesLabel => 'Antecedentes';

  @override
  String get admAntecedentesHint =>
      'Personales, familiares, alergias y medicación habitual.';

  @override
  String get admExploracionLabel => 'Exploración física';

  @override
  String get admExploracionHint => 'Hallazgos objetivos de la exploración.';

  @override
  String get admPruebasLabel => 'Pruebas complementarias';

  @override
  String get admPruebasHint => 'Analítica, imagen u otras pruebas relevantes.';

  @override
  String get admJuicioLabel => 'Juicio clínico (borrador)';

  @override
  String get admJuicioHint =>
      'Impresión diagnóstica preliminar. Requiere validación del médico.';

  @override
  String get admPlanLabel => 'Plan de ingreso y actuación';

  @override
  String get admPlanHint =>
      'Conducta terapéutica, estudios pendientes y criterios de ingreso.';

  @override
  String get trtContextoLabel => 'Contexto del paciente';

  @override
  String get trtContextoHint =>
      'Situación clínica actual del paciente ingresado.';

  @override
  String get trtFarmaLabel => 'Indicaciones farmacológicas';

  @override
  String get trtFarmaHint => 'Fármacos, dosis, vía y frecuencia.';

  @override
  String get trtNoFarmaLabel => 'Indicaciones no farmacológicas y cuidados';

  @override
  String get trtNoFarmaHint => 'Dieta, movilización, curas y otras medidas.';

  @override
  String get trtVigilanciaLabel => 'Vigilancia y constantes';

  @override
  String get trtVigilanciaHint => 'Controles, monitorización y alertas.';

  @override
  String get trtObservacionesLabel => 'Observaciones y prioridad';

  @override
  String get trtObservacionesHint =>
      'Notas adicionales o prioridad de actuación.';

  @override
  String get evoSubjetivoLabel => 'Subjetivo';

  @override
  String get evoSubjetivoHint => 'Síntomas referidos por el paciente.';

  @override
  String get evoObjetivoLabel => 'Objetivo y exploración';

  @override
  String get evoObjetivoHint => 'Constantes, exploración y datos objetivos.';

  @override
  String get evoEvolucionLabel => 'Evolución clínica';

  @override
  String get evoEvolucionHint => 'Curso del cuadro desde el último registro.';

  @override
  String get evoJuicioLabel => 'Juicio clínico (borrador)';

  @override
  String get evoJuicioHint =>
      'Impresión diagnóstica actual. Requiere validación del médico.';

  @override
  String get evoPlanLabel => 'Plan terapéutico y próximos pasos';

  @override
  String get evoPlanHint => 'Cambios de tratamiento y seguimiento.';

  @override
  String get liveOpen => 'Transcripción en vivo';

  @override
  String get liveRecordingHint =>
      'La transcripción aparece en tiempo real mientras hablas. El audio no se guarda.';

  @override
  String get liveTranscriptTitle => 'Transcripción en vivo';

  @override
  String get transcribing => 'transcribiendo…';

  @override
  String get liveMicIdle => 'Pulsa «Iniciar» para empezar a capturar.';

  @override
  String get livePaused => 'Sesión en pausa.';

  @override
  String get liveStart => 'Iniciar transcripción';

  @override
  String get livePause => 'Pausar';

  @override
  String get liveResume => 'Reanudar';

  @override
  String get liveFinish => 'Finalizar';

  @override
  String get liveStatusIdle => 'Sin iniciar';

  @override
  String get liveStatusConnecting => 'Conectando…';

  @override
  String get liveStatusListening => 'Escuchando';

  @override
  String get liveStatusPaused => 'En pausa';

  @override
  String get liveStatusStopped => 'Finalizada';

  @override
  String get liveStatusError => 'Error';

  @override
  String get generatingDraft => 'Generando borrador…';
}
