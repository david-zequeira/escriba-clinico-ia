import 'package:dio/dio.dart';
import 'package:escriba_clinico/core/network/dio_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('applyAuthHeader', () {
    test('añade Authorization: Bearer cuando hay token', () {
      final options = RequestOptions(path: '/consultations');
      applyAuthHeader(options, 'access-abc');
      expect(options.headers['Authorization'], 'Bearer access-abc');
    });

    test('no añade cabecera si el token es null', () {
      final options = RequestOptions(path: '/consultations');
      applyAuthHeader(options, null);
      expect(options.headers.containsKey('Authorization'), isFalse);
    });

    test('no añade cabecera si el token es vacío', () {
      final options = RequestOptions(path: '/consultations');
      applyAuthHeader(options, '');
      expect(options.headers.containsKey('Authorization'), isFalse);
    });
  });
}
