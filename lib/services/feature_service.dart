import '../models/usage_category.dart';
import 'category_service.dart';

class FeatureService {
static Map<String, dynamic> extractFeatures(
List<Map<String, dynamic>> apps, {
required int numberOfSessions,
required int lateNightUsage,
}) {
int totalScreenTime = 0;
int socialMediaTime = 0;
int entertainmentTime = 0;
int communicationTime = 0;
int gamingTime = 0;
int productivityTime = 0;

final int numberOfApps = apps.length;
int mostUsedAppTime = 0;

for (final app in apps) {
  final int minutes = (app['usageMinutes'] ?? 0) as int;

  totalScreenTime += minutes;

  if (minutes > mostUsedAppTime) {
    mostUsedAppTime = minutes;
  }

  final String packageName =
      app['packageName']?.toString() ?? '';

  final UsageCategory category =
      CategoryService.getCategory(packageName);

  switch (category) {
    case UsageCategory.socialMedia:
      socialMediaTime += minutes;
      break;

    case UsageCategory.entertainment:
      entertainmentTime += minutes;
      break;

    case UsageCategory.communication:
      communicationTime += minutes;
      break;

    case UsageCategory.games:
      gamingTime += minutes;
      break;

    case UsageCategory.productivity:
      productivityTime += minutes;
      break;

    default:
      break;
  }
}

return {
  'total_screen_time': totalScreenTime,
  'social_media_time': socialMediaTime,
  'entertainment_time': entertainmentTime,
  'communication_time': communicationTime,
  'gaming_time': gamingTime,
  'productivity_time': productivityTime,
  'number_of_apps': numberOfApps,
  'number_of_sessions': numberOfSessions,
  'late_night_usage': lateNightUsage,
  'most_used_app_time': mostUsedAppTime,
};

}
}
