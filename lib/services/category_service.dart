import '../models/usage_category.dart';
class CategoryService {
  static UsageCategory getCategory(String packageName) {
    final package = packageName.toLowerCase();
    // System services should remain uncategorized as Other.
    if (package == 'com.google.android.gms') {
      return UsageCategory.other;
    }
    // Google Meet and study apps
    if (package == 'com.google.android.apps.tachyon' ||
        package == 'com.google.android.gm' ||
        package == 'com.openai.chatgpt' ||
        package.contains('chatgpt') ||
        package.contains('openai') ||
        package.contains('classroom') ||
        package.contains('coursera') ||
        package.contains('udemy') ||
        package.contains('unacademy') ||
        package.contains('byju') ||
        package.contains('duolingo') ||
        package.contains('khanacademy') ||
        package.contains('quizlet') ||
        package.contains('edx') ||
        package.contains('skillshare') ||
        package.contains('study')) {
      return UsageCategory.education;
    }
    // Social Media
    if (package.contains('instagram') ||
        package.contains('facebook') ||
        package.contains('snapchat') ||
        package.contains('twitter') ||
        package.contains('tiktok') ||
        package.contains('linkedin')) {
      return UsageCategory.socialMedia;
    }

    // Entertainment
    if (package.contains('graymatrix.did') ||
        package.contains('hotstar') ||
        package.contains('youtube') ||
        package.contains('netflix') ||
        package.contains('spotify') ||
        package.contains('primevideo')) {
      return UsageCategory.entertainment;
    }

    // Communication
    if (package.contains('whatsapp') ||
        package.contains('telegram') ||
        package.contains('messenger') ||
        package.contains('dialer') ||
        package.contains('contacts')) {
      return UsageCategory.communication;
    }

    // Games
    if (package.contains('game') ||
        package.contains('pubg') ||
        package.contains('freefire') ||
        package.contains('minecraft') ||
        package.contains('roblox')) {
      return UsageCategory.games;
    }

    // Finance
    if (package.contains('paisa') ||
        package.contains('gpay') ||
        package.contains('googlequicksearchbox') ||
        package.contains('phonepe') ||
        package.contains('paytm') ||
        package.contains('bank')) {
      return UsageCategory.finance;
    }

    // Shopping
    if (package.contains('meesho') ||
        package.contains('amazon') ||
        package.contains('flipkart') ||
        package.contains('myntra')) {
      return UsageCategory.shopping;
    }

    // Browser
    if (package.contains('chrome') ||
        package.contains('firefox') ||
        package.contains('browser') ||
        package.contains('brave')) {
      return UsageCategory.browser;
    }

    // Productivity
    if (package.contains('drive') ||
        package.contains('docs') ||
        package.contains('sheets') ||
        package.contains('office') ||
        package.contains('word')) {
      return UsageCategory.productivity;
    }

    // Utilities
    if (package.contains('calculator') ||
        package.contains('camera') ||
        package.contains('settings') ||
        package.contains('maps')) {
      return UsageCategory.utilities;
    }

    return UsageCategory.other;
  }

  static String getCategoryName(UsageCategory category) {
    switch (category) {
      case UsageCategory.socialMedia:
        return 'Social Media';
      case UsageCategory.entertainment:
        return 'Entertainment';
      case UsageCategory.communication:
        return 'Communication';
      case UsageCategory.education:
        return 'Study';
      case UsageCategory.games:
        return 'Games';
      case UsageCategory.productivity:
        return 'Productivity';
      case UsageCategory.finance:
        return 'Finance';
      case UsageCategory.shopping:
        return 'Shopping';
      case UsageCategory.browser:
        return 'Browser';
      case UsageCategory.utilities:
        return 'Utilities';
      case UsageCategory.other:
        return 'Other';
    }
  }
}