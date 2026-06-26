import 'dart:async';

import 'package:escriba_clinico/features/consultation/data/datasources/transcription_stream_source.dart';
import 'package:escriba_clinico/features/consultation/data/repositories/transcription_stream_repository_impl.dart';
import 'package:escriba_clinico/features/consultation/domain/entities/transcript.dart';
import 'package:escriba_clinico/features/consultation/domain/entities/transcription_event.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fuente falsa que emite frames crudos controlados por el test.
class _FakeSource implements TranscriptionStreamSource {
  _FakeSource(this._frames);

  final List<Map<String, dynamic>> _frames;
  int pauseCalls = 0;
  int resumeCalls = 0;
  int closeCalls = 0;

  @override
  Stream<Map<String, dynamic>> frames(String consultationId) =>
      Stream.fromIterable(_frames);

  @override
  Future<void> pause() async => pauseCalls++;

  @override
  Future<void> resume() async => resumeCalls++;

  @override
  Future<void> close() async => closeCalls++;
}

void main() {
  test('mapea frames crudos a eventos de dominio en orden', () async {
    final source = _FakeSource([
      {'type': 'partial', 'speaker': 'medico', 'text': 'Buenos', 'start_ms': 0},
      {
        'type': 'final',
        'speaker': 'medico',
        'text': 'Buenos días',
        'start_ms': 0,
        'end_ms': 1200,
      },
      {'type': 'error', 'message': 'caída de red'},
      {'type': 'closed'},
    ]);
    final repo = TranscriptionStreamRepositoryImpl(source);

    final events = await repo.connect('c-1').toList();

    expect(events, hasLength(4));

    final partial = events[0] as TranscriptPartial;
    expect(partial.segment.speaker, Speaker.medico);
    expect(partial.segment.text, 'Buenos');
    expect(partial.segment.isPartial, isTrue);

    final fin = events[1] as TranscriptFinal;
    expect(fin.segment.text, 'Buenos días');
    expect(fin.segment.endMs, 1200);
    expect(fin.segment.isPartial, isFalse);

    expect((events[2] as TranscriptStreamError).message, 'caída de red');
    expect(events[3], isA<TranscriptStreamClosed>());
  });

  test('un frame de tipo desconocido se convierte en error', () async {
    final repo = TranscriptionStreamRepositoryImpl(
      _FakeSource([
        {'type': 'wat'},
      ]),
    );

    final events = await repo.connect('c-1').toList();
    expect(events.single, isA<TranscriptStreamError>());
  });

  test('pause/resume/close delegan en la fuente', () async {
    final source = _FakeSource([]);
    final repo = TranscriptionStreamRepositoryImpl(source);

    await repo.pause();
    await repo.resume();
    await repo.close();

    expect(source.pauseCalls, 1);
    expect(source.resumeCalls, 1);
    expect(source.closeCalls, 1);
  });
}
