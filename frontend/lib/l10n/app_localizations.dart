import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Access for healthcare staff'**
  String get loginSubtitle;

  /// No description provided for @fieldUser.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get fieldUser;

  /// No description provided for @validatorUser.
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get validatorUser;

  /// No description provided for @fieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get fieldPassword;

  /// No description provided for @validatorPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get validatorPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signInWithSso.
  ///
  /// In en, this message translates to:
  /// **'Sign in with hospital SSO'**
  String get signInWithSso;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Please try again.'**
  String get loginFailed;

  /// No description provided for @devAccessLabel.
  ///
  /// In en, this message translates to:
  /// **'development'**
  String get devAccessLabel;

  /// No description provided for @devCredentialsHint.
  ///
  /// In en, this message translates to:
  /// **'Development environment: any credentials work.'**
  String get devCredentialsHint;

  /// No description provided for @toggleTheme.
  ///
  /// In en, this message translates to:
  /// **'Toggle theme'**
  String get toggleTheme;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get spanish;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @newDocument.
  ///
  /// In en, this message translates to:
  /// **'New document'**
  String get newDocument;

  /// No description provided for @newDocumentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the type of clinical note to generate from the audio.'**
  String get newDocumentSubtitle;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @consentTitle.
  ///
  /// In en, this message translates to:
  /// **'Patient consent'**
  String get consentTitle;

  /// No description provided for @consentBody.
  ///
  /// In en, this message translates to:
  /// **'Confirm that the patient has been informed and consents to recording the consultation to generate an AI-assisted clinical draft.'**
  String get consentBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @connectedTo.
  ///
  /// In en, this message translates to:
  /// **'Connected to {url}'**
  String connectedTo(String url);

  /// No description provided for @backendUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Backend unavailable at {url}'**
  String backendUnavailable(String url);

  /// No description provided for @backendStartHint.
  ///
  /// In en, this message translates to:
  /// **'Start it: cd backend && source .venv/bin/activate && python -m app'**
  String get backendStartHint;

  /// No description provided for @stopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get stopRecording;

  /// No description provided for @finishing.
  ///
  /// In en, this message translates to:
  /// **'Finishing…'**
  String get finishing;

  /// No description provided for @sendingToServer.
  ///
  /// In en, this message translates to:
  /// **'Sending to server…'**
  String get sendingToServer;

  /// No description provided for @pressToRecord.
  ///
  /// In en, this message translates to:
  /// **'Tap to record'**
  String get pressToRecord;

  /// No description provided for @recordingInProgress.
  ///
  /// In en, this message translates to:
  /// **'Recording… tap stop or press Space'**
  String get recordingInProgress;

  /// No description provided for @spaceShortcutHint.
  ///
  /// In en, this message translates to:
  /// **'Shortcut: Space (when not focused on a field)'**
  String get spaceShortcutHint;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @savingAudioLocally.
  ///
  /// In en, this message translates to:
  /// **'Saving audio locally…'**
  String get savingAudioLocally;

  /// No description provided for @processingOnServer.
  ///
  /// In en, this message translates to:
  /// **'Processing on the server (STT + draft)…'**
  String get processingOnServer;

  /// No description provided for @stepRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get stepRecording;

  /// No description provided for @stepTranscription.
  ///
  /// In en, this message translates to:
  /// **'Transcription'**
  String get stepTranscription;

  /// No description provided for @stepClinicalDraft.
  ///
  /// In en, this message translates to:
  /// **'Clinical draft'**
  String get stepClinicalDraft;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @noDraftYet.
  ///
  /// In en, this message translates to:
  /// **'No draft yet'**
  String get noDraftYet;

  /// No description provided for @aiBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'AI-assisted draft'**
  String get aiBannerTitle;

  /// No description provided for @aiBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fields marked \"Review\" require explicit confirmation.'**
  String get aiBannerSubtitle;

  /// No description provided for @fieldsFilledSummary.
  ///
  /// In en, this message translates to:
  /// **'{filled} of {total} fields completed by AI. Fill the empty ones and review the rest before confirming.'**
  String fieldsFilledSummary(int filled, int total);

  /// No description provided for @confirmReview.
  ///
  /// In en, this message translates to:
  /// **'Confirm review'**
  String get confirmReview;

  /// No description provided for @draftMarkedReviewed.
  ///
  /// In en, this message translates to:
  /// **'Draft marked as reviewed (local only)'**
  String get draftMarkedReviewed;

  /// No description provided for @sendToHis.
  ///
  /// In en, this message translates to:
  /// **'Send to HIS'**
  String get sendToHis;

  /// No description provided for @sendToHisTooltip.
  ///
  /// In en, this message translates to:
  /// **'Available once connected to the hospital system'**
  String get sendToHisTooltip;

  /// No description provided for @pendingFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Pending — fill in manually…'**
  String get pendingFieldHint;

  /// No description provided for @conversation.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get conversation;

  /// No description provided for @evidenceHintEmpty.
  ///
  /// In en, this message translates to:
  /// **'Tap \"show evidence\" on a field, or a fragment here, to link them.'**
  String get evidenceHintEmpty;

  /// No description provided for @evidenceHintSelected.
  ///
  /// In en, this message translates to:
  /// **'Highlighted: the source of the selected field.'**
  String get evidenceHintSelected;

  /// No description provided for @noTranscript.
  ///
  /// In en, this message translates to:
  /// **'No transcript available.'**
  String get noTranscript;

  /// No description provided for @evidenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Evidence · {label}'**
  String evidenceTitle(String label);

  /// No description provided for @showEvidence.
  ///
  /// In en, this message translates to:
  /// **'Show where it came from'**
  String get showEvidence;

  /// No description provided for @showEvidenceCount.
  ///
  /// In en, this message translates to:
  /// **'Show where it came from ({count} fragments)'**
  String showEvidenceCount(int count);

  /// No description provided for @speakerDoctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get speakerDoctor;

  /// No description provided for @speakerPatient.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get speakerPatient;

  /// No description provided for @speakerUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unidentified'**
  String get speakerUnknown;

  /// No description provided for @fieldStatusAi.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get fieldStatusAi;

  /// No description provided for @fieldStatusEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get fieldStatusEmpty;

  /// No description provided for @fieldStatusReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get fieldStatusReview;

  /// No description provided for @patientIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Patient ID number'**
  String get patientIdLabel;

  /// No description provided for @patientIdHint.
  ///
  /// In en, this message translates to:
  /// **'National ID or other identifier'**
  String get patientIdHint;

  /// No description provided for @patientIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the patient\'s ID number'**
  String get patientIdRequired;

  /// No description provided for @audioPathUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Audio path unavailable.'**
  String get audioPathUnavailable;

  /// No description provided for @emptyRecording.
  ///
  /// In en, this message translates to:
  /// **'The recording is empty. Check the microphone.'**
  String get emptyRecording;

  /// No description provided for @admissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Hospital admission note'**
  String get admissionTitle;

  /// No description provided for @admissionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Doctor–patient interview for admission assessment.'**
  String get admissionSubtitle;

  /// No description provided for @admissionRecordingHint.
  ///
  /// In en, this message translates to:
  /// **'Record the conversation with the patient (with prior consent).'**
  String get admissionRecordingHint;

  /// No description provided for @admissionShort.
  ///
  /// In en, this message translates to:
  /// **'Admission'**
  String get admissionShort;

  /// No description provided for @treatmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Treatment orders'**
  String get treatmentTitle;

  /// No description provided for @treatmentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Doctor\'s dictation with orders for an admitted patient.'**
  String get treatmentSubtitle;

  /// No description provided for @treatmentRecordingHint.
  ///
  /// In en, this message translates to:
  /// **'Record your orders out loud (no patient).'**
  String get treatmentRecordingHint;

  /// No description provided for @treatmentShort.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get treatmentShort;

  /// No description provided for @evolutionTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress note'**
  String get evolutionTitle;

  /// No description provided for @evolutionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clinical progress of an already-admitted patient.'**
  String get evolutionSubtitle;

  /// No description provided for @evolutionRecordingHint.
  ///
  /// In en, this message translates to:
  /// **'Record the progress of the admitted patient.'**
  String get evolutionRecordingHint;

  /// No description provided for @evolutionShort.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get evolutionShort;

  /// No description provided for @admMotivoLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason for admission'**
  String get admMotivoLabel;

  /// No description provided for @admMotivoHint.
  ///
  /// In en, this message translates to:
  /// **'Main reason for the hospital admission.'**
  String get admMotivoHint;

  /// No description provided for @admEnfermedadLabel.
  ///
  /// In en, this message translates to:
  /// **'Present illness'**
  String get admEnfermedadLabel;

  /// No description provided for @admEnfermedadHint.
  ///
  /// In en, this message translates to:
  /// **'Chronology and features of the current condition.'**
  String get admEnfermedadHint;

  /// No description provided for @admAntecedentesLabel.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get admAntecedentesLabel;

  /// No description provided for @admAntecedentesHint.
  ///
  /// In en, this message translates to:
  /// **'Personal, family, allergies and usual medication.'**
  String get admAntecedentesHint;

  /// No description provided for @admExploracionLabel.
  ///
  /// In en, this message translates to:
  /// **'Physical examination'**
  String get admExploracionLabel;

  /// No description provided for @admExploracionHint.
  ///
  /// In en, this message translates to:
  /// **'Objective examination findings.'**
  String get admExploracionHint;

  /// No description provided for @admPruebasLabel.
  ///
  /// In en, this message translates to:
  /// **'Complementary tests'**
  String get admPruebasLabel;

  /// No description provided for @admPruebasHint.
  ///
  /// In en, this message translates to:
  /// **'Lab work, imaging or other relevant tests.'**
  String get admPruebasHint;

  /// No description provided for @admJuicioLabel.
  ///
  /// In en, this message translates to:
  /// **'Clinical assessment (draft)'**
  String get admJuicioLabel;

  /// No description provided for @admJuicioHint.
  ///
  /// In en, this message translates to:
  /// **'Preliminary diagnostic impression. Requires doctor validation.'**
  String get admJuicioHint;

  /// No description provided for @admPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Admission and action plan'**
  String get admPlanLabel;

  /// No description provided for @admPlanHint.
  ///
  /// In en, this message translates to:
  /// **'Therapeutic approach, pending studies and admission criteria.'**
  String get admPlanHint;

  /// No description provided for @trtContextoLabel.
  ///
  /// In en, this message translates to:
  /// **'Patient context'**
  String get trtContextoLabel;

  /// No description provided for @trtContextoHint.
  ///
  /// In en, this message translates to:
  /// **'Current clinical situation of the admitted patient.'**
  String get trtContextoHint;

  /// No description provided for @trtFarmaLabel.
  ///
  /// In en, this message translates to:
  /// **'Pharmacological orders'**
  String get trtFarmaLabel;

  /// No description provided for @trtFarmaHint.
  ///
  /// In en, this message translates to:
  /// **'Drugs, dose, route and frequency.'**
  String get trtFarmaHint;

  /// No description provided for @trtNoFarmaLabel.
  ///
  /// In en, this message translates to:
  /// **'Non-pharmacological orders and care'**
  String get trtNoFarmaLabel;

  /// No description provided for @trtNoFarmaHint.
  ///
  /// In en, this message translates to:
  /// **'Diet, mobilization, wound care and other measures.'**
  String get trtNoFarmaHint;

  /// No description provided for @trtVigilanciaLabel.
  ///
  /// In en, this message translates to:
  /// **'Monitoring and vital signs'**
  String get trtVigilanciaLabel;

  /// No description provided for @trtVigilanciaHint.
  ///
  /// In en, this message translates to:
  /// **'Checks, monitoring and alerts.'**
  String get trtVigilanciaHint;

  /// No description provided for @trtObservacionesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes and priority'**
  String get trtObservacionesLabel;

  /// No description provided for @trtObservacionesHint.
  ///
  /// In en, this message translates to:
  /// **'Additional notes or action priority.'**
  String get trtObservacionesHint;

  /// No description provided for @evoSubjetivoLabel.
  ///
  /// In en, this message translates to:
  /// **'Subjective'**
  String get evoSubjetivoLabel;

  /// No description provided for @evoSubjetivoHint.
  ///
  /// In en, this message translates to:
  /// **'Symptoms reported by the patient.'**
  String get evoSubjetivoHint;

  /// No description provided for @evoObjetivoLabel.
  ///
  /// In en, this message translates to:
  /// **'Objective and examination'**
  String get evoObjetivoLabel;

  /// No description provided for @evoObjetivoHint.
  ///
  /// In en, this message translates to:
  /// **'Vital signs, examination and objective data.'**
  String get evoObjetivoHint;

  /// No description provided for @evoEvolucionLabel.
  ///
  /// In en, this message translates to:
  /// **'Clinical progress'**
  String get evoEvolucionLabel;

  /// No description provided for @evoEvolucionHint.
  ///
  /// In en, this message translates to:
  /// **'Course of the condition since the last entry.'**
  String get evoEvolucionHint;

  /// No description provided for @evoJuicioLabel.
  ///
  /// In en, this message translates to:
  /// **'Clinical assessment (draft)'**
  String get evoJuicioLabel;

  /// No description provided for @evoJuicioHint.
  ///
  /// In en, this message translates to:
  /// **'Current diagnostic impression. Requires doctor validation.'**
  String get evoJuicioHint;

  /// No description provided for @evoPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Therapeutic plan and next steps'**
  String get evoPlanLabel;

  /// No description provided for @evoPlanHint.
  ///
  /// In en, this message translates to:
  /// **'Treatment changes and follow-up.'**
  String get evoPlanHint;

  /// No description provided for @liveOpen.
  ///
  /// In en, this message translates to:
  /// **'Live transcription'**
  String get liveOpen;

  /// No description provided for @liveRecordingHint.
  ///
  /// In en, this message translates to:
  /// **'The transcription appears in real time as you speak. Audio is not stored.'**
  String get liveRecordingHint;

  /// No description provided for @liveTranscriptTitle.
  ///
  /// In en, this message translates to:
  /// **'Live transcription'**
  String get liveTranscriptTitle;

  /// No description provided for @transcribing.
  ///
  /// In en, this message translates to:
  /// **'transcribing…'**
  String get transcribing;

  /// No description provided for @liveMicIdle.
  ///
  /// In en, this message translates to:
  /// **'Press “Start” to begin capturing.'**
  String get liveMicIdle;

  /// No description provided for @livePaused.
  ///
  /// In en, this message translates to:
  /// **'Session paused.'**
  String get livePaused;

  /// No description provided for @liveStart.
  ///
  /// In en, this message translates to:
  /// **'Start transcription'**
  String get liveStart;

  /// No description provided for @livePause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get livePause;

  /// No description provided for @liveResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get liveResume;

  /// No description provided for @liveFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get liveFinish;

  /// No description provided for @liveStatusIdle.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get liveStatusIdle;

  /// No description provided for @liveStatusConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get liveStatusConnecting;

  /// No description provided for @liveStatusListening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get liveStatusListening;

  /// No description provided for @liveStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get liveStatusPaused;

  /// No description provided for @liveStatusStopped.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get liveStatusStopped;

  /// No description provided for @liveStatusError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get liveStatusError;

  /// No description provided for @generatingDraft.
  ///
  /// In en, this message translates to:
  /// **'Generating draft…'**
  String get generatingDraft;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
