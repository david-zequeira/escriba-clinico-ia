import 'package:escriba_clinico/features/consultation/domain/entities/transcript.dart';
import 'package:escriba_clinico/features/consultation/domain/entities/transcription_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TranscriptSegment es final por defecto (isPartial = false)', () {
    const seg = TranscriptSegment(speaker: Speaker.medico, text: 'hola');
    expect(seg.isPartial, isFalse);
  });

  test('TranscriptPartial transporta un segmento marcado como parcial', () {
    const event = TranscriptPartial(
      TranscriptSegment(speaker: Speaker.paciente, text: 'me duele', isPartial: true),
    );
    expect(event.segment.isPartial, isTrue);
    expect(event.segment.speaker, Speaker.paciente);
  });

  test('los eventos se pueden discriminar con switch exhaustivo (sealed)', () {
    String describe(TranscriptionEvent e) => switch (e) {
          TranscriptPartial() => 'partial',
          TranscriptFinal() => 'final',
          TranscriptStreamError() => 'error',
          TranscriptStreamClosed() => 'closed',
        };

    expect(
      describe(const TranscriptFinal(
          TranscriptSegment(speaker: Speaker.medico, text: 'x'))),
      'final',
    );
    expect(describe(const TranscriptStreamError('boom')), 'error');
    expect(describe(const TranscriptStreamClosed()), 'closed');
  });
}
