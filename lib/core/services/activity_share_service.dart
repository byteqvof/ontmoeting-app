import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/home/domain/entities/home_activity.dart';
import '../config/supabase_config.dart';
import '../utils/activity_deep_links.dart';

class ActivityShareService {
  const ActivityShareService();

  Future<void> shareActivity({
    required HomeActivity activity,
    Rect? sharePositionOrigin,
  }) async {
    final text = buildActivityShareText(activity);
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: activity.title,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }
}

String buildActivityShareText(
  HomeActivity activity, {
  String publicBaseUrl = tochPublicShareBaseUrl,
  String publicUrlTemplate = tochPublicShareUrlTemplate,
  String supabaseProjectUrl = supabaseUrl,
}) {
  final dateTime = [
    activity.dateLabel.trim(),
    activity.timeLabel.trim(),
  ].where((part) => part.isNotEmpty).join(' om ');
  final location = activity.meetingPoint.trim().isNotEmpty
      ? activity.meetingPoint.trim()
      : activity.locationName.trim();
  final link = activityShareUri(
    activity.id,
    publicBaseUrl: publicBaseUrl,
    publicUrlTemplate: publicUrlTemplate,
    supabaseProjectUrl: supabaseProjectUrl,
  ).toString();

  return [
    'Deze activiteit op TOCH lijkt me iets voor jou:',
    activity.title.trim(),
    if (dateTime.isNotEmpty) dateTime,
    if (location.isNotEmpty) location,
    '',
    'Bekijk en sluit aan: $link',
  ].join('\n');
}
