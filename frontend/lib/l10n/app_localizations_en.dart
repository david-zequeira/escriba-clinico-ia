// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loginSubtitle => 'Access for healthcare staff';

  @override
  String get fieldUser => 'Username';

  @override
  String get validatorUser => 'Enter your username';

  @override
  String get fieldPassword => 'Password';

  @override
  String get validatorPassword => 'Enter your password';

  @override
  String get signIn => 'Sign in';

  @override
  String get signInWithSso => 'Sign in with hospital SSO';

  @override
  String get loginFailed => 'Sign-in failed. Please try again.';

  @override
  String get devAccessLabel => 'development';

  @override
  String get devCredentialsHint =>
      'Development environment: any credentials work.';

  @override
  String get toggleTheme => 'Toggle theme';

  @override
  String get language => 'Language';

  @override
  String get spanish => 'Español';

  @override
  String get english => 'English';

  @override
  String get logout => 'Log out';

  @override
  String get newDocument => 'New document';

  @override
  String get newDocumentSubtitle =>
      'Choose the type of clinical note to generate from the audio.';

  @override
  String get start => 'Start';

  @override
  String get consentTitle => 'Patient consent';

  @override
  String get consentBody =>
      'Confirm that the patient has been informed and consents to recording the consultation to generate an AI-assisted clinical draft.';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String connectedTo(String url) {
    return 'Connected to $url';
  }

  @override
  String backendUnavailable(String url) {
    return 'Backend unavailable at $url';
  }

  @override
  String get backendStartHint =>
      'Start it: cd backend && source .venv/bin/activate && python -m app';

  @override
  String get stopRecording => 'Stop recording';

  @override
  String get finishing => 'Finishing…';

  @override
  String get sendingToServer => 'Sending to server…';

  @override
  String get pressToRecord => 'Tap to record';

  @override
  String get recordingInProgress => 'Recording… tap stop or press Space';

  @override
  String get spaceShortcutHint =>
      'Shortcut: Space (when not focused on a field)';

  @override
  String get progress => 'Progress';

  @override
  String get savingAudioLocally => 'Saving audio locally…';

  @override
  String get processingOnServer => 'Processing on the server (STT + draft)…';

  @override
  String get stepRecording => 'Recording';

  @override
  String get stepTranscription => 'Transcription';

  @override
  String get stepClinicalDraft => 'Clinical draft';

  @override
  String get review => 'Review';

  @override
  String get noDraftYet => 'No draft yet';

  @override
  String get aiBannerTitle => 'AI-assisted draft';

  @override
  String get aiBannerSubtitle =>
      'Fields marked \"Review\" require explicit confirmation.';

  @override
  String fieldsFilledSummary(int filled, int total) {
    return '$filled of $total fields completed by AI. Fill the empty ones and review the rest before confirming.';
  }

  @override
  String get confirmReview => 'Confirm review';

  @override
  String get draftMarkedReviewed => 'Draft marked as reviewed (local only)';

  @override
  String get sendToHis => 'Send to HIS';

  @override
  String get sendToHisTooltip =>
      'Available once connected to the hospital system';

  @override
  String get pendingFieldHint => 'Pending — fill in manually…';

  @override
  String get conversation => 'Conversation';

  @override
  String get evidenceHintEmpty =>
      'Tap \"show evidence\" on a field, or a fragment here, to link them.';

  @override
  String get evidenceHintSelected =>
      'Highlighted: the source of the selected field.';

  @override
  String get noTranscript => 'No transcript available.';

  @override
  String evidenceTitle(String label) {
    return 'Evidence · $label';
  }

  @override
  String get showEvidence => 'Show where it came from';

  @override
  String showEvidenceCount(int count) {
    return 'Show where it came from ($count fragments)';
  }

  @override
  String get speakerDoctor => 'Doctor';

  @override
  String get speakerPatient => 'Patient';

  @override
  String get speakerUnknown => 'Unidentified';

  @override
  String get fieldStatusAi => 'AI';

  @override
  String get fieldStatusEmpty => 'Empty';

  @override
  String get fieldStatusReview => 'Review';

  @override
  String get patientIdLabel => 'Patient ID number';

  @override
  String get patientIdHint => 'National ID or other identifier';

  @override
  String get patientIdRequired => 'Enter the patient\'s ID number';

  @override
  String get audioPathUnavailable => 'Audio path unavailable.';

  @override
  String get emptyRecording => 'The recording is empty. Check the microphone.';

  @override
  String get admissionTitle => 'Hospital admission note';

  @override
  String get admissionSubtitle =>
      'Doctor–patient interview for admission assessment.';

  @override
  String get admissionRecordingHint =>
      'Record the conversation with the patient (with prior consent).';

  @override
  String get admissionShort => 'Admission';

  @override
  String get treatmentTitle => 'Treatment orders';

  @override
  String get treatmentSubtitle =>
      'Doctor\'s dictation with orders for an admitted patient.';

  @override
  String get treatmentRecordingHint =>
      'Record your orders out loud (no patient).';

  @override
  String get treatmentShort => 'Orders';

  @override
  String get evolutionTitle => 'Progress note';

  @override
  String get evolutionSubtitle =>
      'Clinical progress of an already-admitted patient.';

  @override
  String get evolutionRecordingHint =>
      'Record the progress of the admitted patient.';

  @override
  String get evolutionShort => 'Progress';

  @override
  String get admMotivoLabel => 'Reason for admission';

  @override
  String get admMotivoHint => 'Main reason for the hospital admission.';

  @override
  String get admEnfermedadLabel => 'Present illness';

  @override
  String get admEnfermedadHint =>
      'Chronology and features of the current condition.';

  @override
  String get admAntecedentesLabel => 'History';

  @override
  String get admAntecedentesHint =>
      'Personal, family, allergies and usual medication.';

  @override
  String get admExploracionLabel => 'Physical examination';

  @override
  String get admExploracionHint => 'Objective examination findings.';

  @override
  String get admPruebasLabel => 'Complementary tests';

  @override
  String get admPruebasHint => 'Lab work, imaging or other relevant tests.';

  @override
  String get admJuicioLabel => 'Clinical assessment (draft)';

  @override
  String get admJuicioHint =>
      'Preliminary diagnostic impression. Requires doctor validation.';

  @override
  String get admPlanLabel => 'Admission and action plan';

  @override
  String get admPlanHint =>
      'Therapeutic approach, pending studies and admission criteria.';

  @override
  String get trtContextoLabel => 'Patient context';

  @override
  String get trtContextoHint =>
      'Current clinical situation of the admitted patient.';

  @override
  String get trtFarmaLabel => 'Pharmacological orders';

  @override
  String get trtFarmaHint => 'Drugs, dose, route and frequency.';

  @override
  String get trtNoFarmaLabel => 'Non-pharmacological orders and care';

  @override
  String get trtNoFarmaHint =>
      'Diet, mobilization, wound care and other measures.';

  @override
  String get trtVigilanciaLabel => 'Monitoring and vital signs';

  @override
  String get trtVigilanciaHint => 'Checks, monitoring and alerts.';

  @override
  String get trtObservacionesLabel => 'Notes and priority';

  @override
  String get trtObservacionesHint => 'Additional notes or action priority.';

  @override
  String get evoSubjetivoLabel => 'Subjective';

  @override
  String get evoSubjetivoHint => 'Symptoms reported by the patient.';

  @override
  String get evoObjetivoLabel => 'Objective and examination';

  @override
  String get evoObjetivoHint => 'Vital signs, examination and objective data.';

  @override
  String get evoEvolucionLabel => 'Clinical progress';

  @override
  String get evoEvolucionHint =>
      'Course of the condition since the last entry.';

  @override
  String get evoJuicioLabel => 'Clinical assessment (draft)';

  @override
  String get evoJuicioHint =>
      'Current diagnostic impression. Requires doctor validation.';

  @override
  String get evoPlanLabel => 'Therapeutic plan and next steps';

  @override
  String get evoPlanHint => 'Treatment changes and follow-up.';

  @override
  String get liveOpen => 'Live transcription';

  @override
  String get liveRecordingHint =>
      'The transcription appears in real time as you speak. Audio is not stored.';

  @override
  String get liveTranscriptTitle => 'Live transcription';

  @override
  String get transcribing => 'transcribing…';

  @override
  String get liveMicIdle => 'Press “Start” to begin capturing.';

  @override
  String get livePaused => 'Session paused.';

  @override
  String get liveStart => 'Start transcription';

  @override
  String get livePause => 'Pause';

  @override
  String get liveResume => 'Resume';

  @override
  String get liveFinish => 'Finish';

  @override
  String get liveStatusIdle => 'Not started';

  @override
  String get liveStatusConnecting => 'Connecting…';

  @override
  String get liveStatusListening => 'Listening';

  @override
  String get liveStatusPaused => 'Paused';

  @override
  String get liveStatusStopped => 'Finished';

  @override
  String get liveStatusError => 'Error';

  @override
  String get generatingDraft => 'Generating draft…';
}
