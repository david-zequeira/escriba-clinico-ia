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
  String get devCredentialsHint =>
      'Development environment: any credentials work.';

  @override
  String get toggleTheme => 'Toggle theme';

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
}
