import 'package:dartssh2/src/http/http_client.dart';
import 'package:dartssh2/src/http/http_exception.dart';
import 'package:test/test.dart';

void main() {
  group('HTTP header validation', () {
    test('rejects header field containing CR', () {
      expect(
        () => validateHttpHeaderField('X-Bad\rHeader'),
        throwsA(isA<SSHHttpException>()),
      );
    });

    test('rejects header field containing LF', () {
      expect(
        () => validateHttpHeaderField('X-Bad\nHeader'),
        throwsA(isA<SSHHttpException>()),
      );
    });

    test('rejects header field containing CRLF', () {
      expect(
        () => validateHttpHeaderField('value\r\nInjected: header'),
        throwsA(isA<SSHHttpException>()),
      );
    });

    test('accepts valid header field', () {
      expect(
        () => validateHttpHeaderField('valid-header-value'),
        returnsNormally,
      );
    });

    test('accepts empty header field', () {
      expect(
        () => validateHttpHeaderField(''),
        returnsNormally,
      );
    });
  });
}
