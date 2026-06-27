import 'dart:async';
import 'dart:typed_data';

import 'package:escriba_clinico/features/audio/domain/entities/recorded_audio.dart';
import 'package:escriba_clinico/features/audio/domain/repositories/audio_repository.dart';
import 'package:escriba_clinico/features/consultation/domain/entities/transcript.dart';
import 'package:escriba_clinico/features/consultation/domain/entities/transcription_event.dart';
import 'package:escriba_clinico/features/consultation/domain/repositories/transcription_stream_repository.dart';
import 'package:escriba_clinico/features/consultation/state_management/live_transcription_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Audio falso: amplitud y ciclo de vida controlados, sin micrófono real.
class _FakeAudio implements AudioRepository {
  final amplitudeCtrl = StreamController<double>.broadcast();
  bool started = false;
  int pauseCalls = 0;
  int resumeCalls = 0;
  bool disposed = false;

  @override
  String get preferredExtension => 'wav';

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<void> start(String tempPath) async => started = true;

  @override
  Future<void> pause() async => pauseCalls++;

  @override
  Future<void> resume() async => resumeCalls++;

  @override
  Stream<double> amplitudeStream({Duration interval = const Duration(milliseconds: 120)}) =>
      amplitudeCtrl.stream;

  final audioChunksCtrl = StreamController<List<int>>.broadcast();

  @override
  Stream<List<int>> audioChunks() => audioChunksCtrl.stream;

  @override
  Future<RecordedAudio> stop({required String tempPath}) async =>
      RecordedAudio(bytes: Uint8List.fromList([1, 2, 3]), filename: 'x.wav');

  @override
  Future<void> dispose() async => disposed = true;
}

/// Transcripción falsa: el test inyecta eventos por el [StreamController].
class _FakeTranscription implements TranscriptionStreamRepository {
  final ctrl = StreamController<TranscriptionEvent>.broadcast();
  int pauseCalls = 0;
  int resumeCalls = 0;
  bool closed = false;

  @override
  Stream<TranscriptionEvent> connect(String consultationId) => ctrl.stream;

  final sentAudio = <List<int>>[];

  @override
  Future<void> sendAudio(List<int> bytes) async => sentAudio.add(bytes);

  @override
  Future<void> pause() async => pauseCalls++;

  @override
  Future<void> resume() async => resumeCalls++;

  @override
  Future<void> close() async => closed = true;
}

/// Deja correr los microtasks para que el stream entregue el evento.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeAudio audio;
  late _FakeTranscription transcription;
  late LiveTranscriptionController controller;

  setUp(() {
    audio = _FakeAudio();
    transcription = _FakeTranscription();
    controller = LiveTranscriptionController(audio, transcription);
  });

  tearDown(() {
    controller.dispose();
  });

  test('start arranca micrófono y deja la sesión escuchando', () async {
    await controller.start('c-1', tempPath: '/tmp/x.wav');

    expect(audio.started, isTrue);
    expect(controller.state.status, LiveStatus.listening);
  });

  test('un parcial actualiza la transcripción y luego el final lo consolida',
      () async {
    await controller.start('c-1', tempPath: '/tmp/x.wav');

    transcription.ctrl.add(const TranscriptPartial(
        TranscriptSegment(speaker: Speaker.paciente, text: 'me', isPartial: true)));
    await _settle();

    expect(controller.state.transcript.segments, hasLength(1));
    expect(controller.state.transcript.segments.single.isPartial, isTrue);

    transcription.ctrl.add(const TranscriptFinal(
        TranscriptSegment(speaker: Speaker.paciente, text: 'me duele la cabeza')));
    await _settle();

    final segs = controller.state.transcript.segments;
    expect(segs, hasLength(1));
    expect(segs.single.isPartial, isFalse);
    expect(segs.single.text, 'me duele la cabeza');
  });

  test('reenvía los chunks de audio del micrófono a la transcripción', () async {
    await controller.start('c-1', tempPath: '/tmp/x.wav');

    audio.audioChunksCtrl.add([1, 2, 3]);
    await _settle();

    expect(transcription.sentAudio, [
      [1, 2, 3]
    ]);
  });

  test('la amplitud del micrófono se refleja en el estado', () async {
    await controller.start('c-1', tempPath: '/tmp/x.wav');

    audio.amplitudeCtrl.add(0.8);
    await _settle();

    expect(controller.state.amplitude, 0.8);
  });

  test('pause y resume cambian estado y delegan en audio y transcripción',
      () async {
    await controller.start('c-1', tempPath: '/tmp/x.wav');

    await controller.pause();
    expect(controller.state.status, LiveStatus.paused);
    expect(audio.pauseCalls, 1);
    expect(transcription.pauseCalls, 1);

    await controller.resume();
    expect(controller.state.status, LiveStatus.listening);
    expect(audio.resumeCalls, 1);
    expect(transcription.resumeCalls, 1);
  });

  test('stop finaliza la sesión y libera recursos', () async {
    await controller.start('c-1', tempPath: '/tmp/x.wav');

    await controller.stop();

    expect(controller.state.status, LiveStatus.stopped);
    expect(audio.disposed, isTrue);
    expect(transcription.closed, isTrue);
  });

  test('finishCapture conserva el audio y cierra el canal', () async {
    await controller.start('c-1', tempPath: '/tmp/x.wav');

    final recorded = await controller.finishCapture();

    expect(recorded, isNotNull);
    expect(recorded!.bytes, [1, 2, 3]);
    expect(controller.state.status, LiveStatus.stopped);
    expect(transcription.closed, isTrue);
  });

  test('un evento de error pasa la sesión a error con mensaje', () async {
    await controller.start('c-1', tempPath: '/tmp/x.wav');

    transcription.ctrl.add(const TranscriptStreamError('caída del backend'));
    await _settle();

    expect(controller.state.status, LiveStatus.error);
    expect(controller.state.errorMessage, 'caída del backend');
  });

  test('el evento closed finaliza la sesión', () async {
    await controller.start('c-1', tempPath: '/tmp/x.wav');

    transcription.ctrl.add(const TranscriptStreamClosed());
    await _settle();

    expect(controller.state.status, LiveStatus.stopped);
  });
}
