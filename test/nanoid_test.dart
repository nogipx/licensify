import 'package:licensify/licensify.dart';
import 'package:test/test.dart';

void main() {
  group('NanoId', () {
    test('generates default length NanoID', () {
      final id = NanoId.generate();
      expect(id, hasLength(NanoId.defaultSize));
      expect(
        id.split('').every(NanoId.defaultAlphabet.contains),
        isTrue,
      );
    });

    test('supports custom size and alphabet', () {
      const alphabet = 'abc';
      final id = NanoId.generate(size: 128, alphabet: alphabet);
      expect(id, hasLength(128));
      expect(id.split('').every(alphabet.contains), isTrue);
    });

    test('handles single-character alphabet', () {
      const alphabet = 'x';
      final id = NanoId.generate(size: 5, alphabet: alphabet);
      expect(id, equals('xxxxx'));
    });

    test('throws when size is not positive', () {
      expect(() => NanoId.generate(size: 0), throwsArgumentError);
    });

    test('throws when alphabet is empty', () {
      expect(() => NanoId.generate(alphabet: ''), throwsArgumentError);
    });

    test('throws when alphabet is too long', () {
      final alphabet = List.filled(256, 'a').join();
      expect(() => NanoId.generate(alphabet: alphabet), throwsArgumentError);
    });
  });

  group('Licensify.nanoId', () {
    test('delegates to NanoId.generate', () {
      final id = Licensify.nanoId(size: 10);
      expect(id, hasLength(10));
      expect(
        id.split('').every(NanoId.defaultAlphabet.contains),
        isTrue,
      );
    });
  });
}
