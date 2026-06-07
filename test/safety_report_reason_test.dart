import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/core/services/safety_report_reason.dart';

void main() {
  test('exposes the fixed MVP report categories', () {
    expect(SafetyReportReason.values.map((reason) => reason.backendValue), [
      'inappropriate_behavior',
      'harassment',
      'fake_account',
      'spam',
      'other',
    ]);
  });

  test('uses Dutch user-facing labels without unsafe wording', () {
    expect(SafetyReportReason.harassment.label, 'Intimidatie');
    expect(
      SafetyReportReason.values
          .map((reason) => reason.label.toLowerCase())
          .any((label) => label.contains('veilig persoon')),
      isFalse,
    );
  });
}
