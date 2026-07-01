import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('presentation copy does not expose internal technical wording', () {
    final roots = [
      Directory('lib/features/auth/presentation'),
      Directory('lib/features/home/presentation'),
      Directory('lib/features/profile/presentation'),
      Directory('lib/core/widgets'),
    ];
    final bannedTerms = <String>[
      'supabase',
      'firebase',
      'backend',
      'database',
      'debug-console',
      'ontwikkelmodus',
      'sms-provider',
      'build',
      'service',
    ];

    final findings = <String>[];
    for (final root in roots.where((directory) => directory.existsSync())) {
      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }

        final source = entity
            .readAsLinesSync()
            .where((line) {
              final trimmed = line.trimLeft();
              return !trimmed.startsWith('import ') &&
                  !trimmed.startsWith('export ') &&
                  !trimmed.startsWith('//');
            })
            .join('\n');
        final literalMatches = RegExp(
          r"'([^'\\]*(?:\\.[^'\\]*)*)'",
          multiLine: true,
        ).allMatches(source);

        for (final match in literalMatches) {
          final literal = match.group(1)?.toLowerCase() ?? '';
          for (final term in bannedTerms) {
            if (literal.contains(term)) {
              findings.add('${entity.path}: "$literal" contains "$term"');
            }
          }
        }
      }
    }

    expect(findings, isEmpty, reason: findings.join('\n'));
  });
}
