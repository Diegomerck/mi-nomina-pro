import 'package:flutter_test/flutter_test.dart';

void main() {
  group('APK Download Card & Release Configuration Tests', () {
    test('GitHub latest release URL is properly formatted', () {
      const releaseUrl =
          'https://github.com/Diegomerck/mi-nomina-pro/releases/latest';
      final uri = Uri.parse(releaseUrl);

      expect(uri.isAbsolute, isTrue);
      expect(uri.scheme, equals('https'));
      expect(uri.host, equals('github.com'));
      expect(
          uri.path, equals('/Diegomerck/mi-nomina-pro/releases/latest'));
    });

    test('Installation steps definitions', () {
      final steps = [
        {
          'number': '1',
          'title': 'Descarga el archivo APK',
        },
        {
          'number': '2',
          'title': 'Permite la instalación',
        },
        {
          'number': '3',
          'title': 'Abre e instala',
        },
      ];

      expect(steps.length, equals(3));
      expect(steps[0]['number'], equals('1'));
      expect(steps[1]['number'], equals('2'));
      expect(steps[2]['number'], equals('3'));
    });
  });
}
