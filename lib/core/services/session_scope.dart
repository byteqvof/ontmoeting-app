class SessionScope {
  const SessionScope({required String? Function() currentUserId})
    : _currentUserId = currentUserId;

  static const anonymousCacheKey = '__anonymous_session__';

  final String? Function() _currentUserId;

  String get cacheKey {
    final userId = _currentUserId()?.trim();
    if (userId == null || userId.isEmpty) {
      return anonymousCacheKey;
    }
    return userId;
  }
}
