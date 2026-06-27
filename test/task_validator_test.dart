import 'package:flutter_test/flutter_test.dart';
import 'package:focusboard/app/model/task_validator.dart';

void main() {
  group('TaskValidator.sanitizeTitle', () {
    test('trims whitespace', () {
      expect(TaskValidator.sanitizeTitle('  hello  '), 'hello');
    });

    test('removes HTML tags', () {
      expect(TaskValidator.sanitizeTitle('<b>bold</b>'), 'bold');
      expect(TaskValidator.sanitizeTitle('<script>x</script>'), 'x');
    });

    test('removes dangerous characters', () {
      expect(TaskValidator.sanitizeTitle('a&b'), 'ab');
      expect(TaskValidator.sanitizeTitle('a"b'), 'ab');
      expect(TaskValidator.sanitizeTitle("a'b"), 'ab');
      expect(TaskValidator.sanitizeTitle('a\\b'), 'ab');
    });

    test('collapses multiple spaces', () {
      expect(TaskValidator.sanitizeTitle('a   b'), 'a b');
    });

    test('truncates to max length', () {
      final String long = 'a' * 250;
      final String result = TaskValidator.sanitizeTitle(long);
      expect(result.length, TaskValidator.maxTitleLength);
      expect(result.endsWith('...'), isTrue);
    });

    test('throws on null/empty', () {
      expect(() => TaskValidator.sanitizeTitle(null), throwsArgumentError);
      expect(() => TaskValidator.sanitizeTitle(''), throwsArgumentError);
      expect(() => TaskValidator.sanitizeTitle('   '), throwsArgumentError);
    });

    test('throws when title is only invalid characters', () {
      expect(() => TaskValidator.sanitizeTitle('<>&\'"\\'),
          throwsArgumentError);
    });
  });

  group('TaskValidator.validateId', () {
    test('returns false for null/empty', () {
      expect(TaskValidator.validateId(null), isFalse);
      expect(TaskValidator.validateId(''), isFalse);
      expect(TaskValidator.validateId('   '), isFalse);
    });

    test('returns true for valid id', () {
      expect(TaskValidator.validateId('abc-123'), isTrue);
    });
  });

  group('TaskValidator.parseBoolean', () {
    test('parses booleans', () {
      expect(TaskValidator.parseBoolean(true), isTrue);
      expect(TaskValidator.parseBoolean(false), isFalse);
    });

    test('parses strings', () {
      expect(TaskValidator.parseBoolean('true'), isTrue);
      expect(TaskValidator.parseBoolean('TRUE'), isTrue);
      expect(TaskValidator.parseBoolean('false'), isFalse);
      expect(TaskValidator.parseBoolean('garbage'), isFalse);
    });

    test('handles null gracefully', () {
      expect(TaskValidator.parseBoolean(null), isFalse);
    });
  });

  group('TaskValidator.generateUuid', () {
    test('returns non-empty uuid', () {
      final String id = TaskValidator.generateUuid();
      expect(id, isNotEmpty);
      expect(id.contains('-'), isTrue);
    });

    test('produces unique values', () {
      final Set<String> ids = <String>{};
      for (int i = 0; i < 100; i++) {
        ids.add(TaskValidator.generateUuid());
      }
      expect(ids.length, 100);
    });
  });
}
