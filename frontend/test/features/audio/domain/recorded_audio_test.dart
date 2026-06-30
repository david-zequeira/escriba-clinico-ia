import 'dart:typed_data';

import 'package:escriba_clinico/features/audio/domain/entities/recorded_audio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RecordedAudio conserva bytes y filename', () {
    final audio = RecordedAudio(
      bytes: Uint8List.fromList([1, 2, 3, 4]),
      filename: 'consulta.wav',
    );

    expect(audio.bytes.length, 4);
    expect(audio.filename, 'consulta.wav');
  });
}
