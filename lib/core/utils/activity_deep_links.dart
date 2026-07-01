Uri activityDetailDeepLink(String activityId) {
  return Uri(
    scheme: 'meetingsapp',
    host: 'activity',
    pathSegments: [activityId.trim()],
  );
}

Uri activityShareUri(
  String activityId, {
  String publicBaseUrl = '',
  String publicUrlTemplate = '',
  required String supabaseProjectUrl,
}) {
  final normalizedActivityId = activityId.trim();
  final template = publicUrlTemplate.trim();
  if (template.isNotEmpty) {
    return Uri.parse(
      template.replaceAll(
        '{activityId}',
        Uri.encodeComponent(normalizedActivityId),
      ),
    );
  }

  final baseUrl = publicBaseUrl.trim();
  if (baseUrl.isNotEmpty) {
    return _appendActivityPath(baseUrl, normalizedActivityId);
  }

  return Uri.parse(supabaseProjectUrl.trim()).replace(
    path: '/functions/v1/activity-share',
    queryParameters: {'activity_id': normalizedActivityId},
  );
}

bool isActivityDetailDeepLink(Uri uri) {
  if (uri.scheme == 'meetingsapp') {
    return uri.host == 'activity' || uri.host == 'activity-detail';
  }

  if (uri.scheme != 'https' && uri.scheme != 'http') {
    return false;
  }

  if (uri.pathSegments.length >= 2 &&
      (uri.pathSegments.first == 'activities' ||
          uri.pathSegments.first == 'activity' ||
          uri.pathSegments.first == 'activiteiten')) {
    return true;
  }

  return uri.path == '/functions/v1/activity-share' &&
      (uri.queryParameters['activity_id']?.trim().isNotEmpty ?? false);
}

String? activityIdFromActivityDetailDeepLink(Uri uri) {
  if (!isActivityDetailDeepLink(uri)) {
    return null;
  }

  final fromQuery = uri.queryParameters['activity_id']?.trim();
  if (fromQuery != null && fromQuery.isNotEmpty) {
    return fromQuery;
  }

  if (uri.pathSegments.isEmpty) {
    return null;
  }

  final fromPath = uri.scheme == 'meetingsapp'
      ? uri.pathSegments.first.trim()
      : uri.pathSegments.length >= 2
      ? uri.pathSegments[1].trim()
      : '';
  return fromPath.isEmpty ? null : fromPath;
}

Uri _appendActivityPath(String baseUrl, String activityId) {
  final baseUri = Uri.parse(baseUrl);
  final existingSegments = baseUri.pathSegments
      .where((segment) => segment.trim().isNotEmpty)
      .toList();
  return baseUri.replace(
    pathSegments: [...existingSegments, 'activities', activityId],
    queryParameters: const {},
  );
}
