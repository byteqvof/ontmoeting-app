enum SafetyReportReason {
  inappropriateBehavior(
    backendValue: 'inappropriate_behavior',
    label: 'Ongepast gedrag',
  ),
  harassment(backendValue: 'harassment', label: 'Intimidatie'),
  fakeAccount(backendValue: 'fake_account', label: 'Nepaccount'),
  spam(backendValue: 'spam', label: 'Spam'),
  other(backendValue: 'other', label: 'Anders');

  const SafetyReportReason({required this.backendValue, required this.label});

  final String backendValue;
  final String label;
}
