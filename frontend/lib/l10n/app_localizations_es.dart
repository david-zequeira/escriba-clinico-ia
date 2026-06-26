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
}
