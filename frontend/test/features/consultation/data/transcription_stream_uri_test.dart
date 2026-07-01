import 'package:escriba_clinico/features/consultation/data/datasources/transcription_stream_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WebSocketTranscriptionSource.streamUri', () {
    test('incluye el token como query param cuando hay sesión', () {
      final source = WebSocketTranscriptionSource(token: 'access-abc');
      final uri = source.streamUriForTest('c-123');

      expect(uri.scheme, anyOf('ws', 'wss'));
      expect(uri.path.endsWith('/consultations/c-123/stream'), isTrue);
      expect(uri.queryParameters['token'], 'access-abc');
    });

    test('no añade token en modo dev (sin sesión)', () {
      final source = WebSocketTranscriptionSource();
      final uri = source.streamUriForTest('c-123');

      expect(uri.queryParameters.containsKey('token'), isFalse);
    });
  });
}
