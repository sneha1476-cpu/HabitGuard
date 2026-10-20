import 'package:flutter/material.dart';

import '../services/guardian_alert_service.dart';
import '../services/usage_service.dart';
import '../services/category_service.dart';
import '../services/history_service.dart';
import '../services/feature_service.dart';
import '../services/ml_service.dart';
import 'history_screen.dart';
import 'insights_screen.dart';
import 'coach_screen.dart';
import 'weekly_analytics_screen.dart';
import 'guardian_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  bool _hasUsageAccess = false;

  List<Map<String, dynamic>> _usageData = [];

  String _riskLevel = 'UNKNOWN';
  double _riskConfidence = 0.0;

  String _riskSummary = '';
  List<String> _riskReasons = [];
  List<Map<String, dynamic>> _topFeatures = [];
  List<Map<String, dynamic>> _shapFeatures = [];

  @override
  void initState() {
    super.initState();
    _checkUsageAccess();
  }

  Future<void> _checkUsageAccess() async {
    try {
      final hasAccess = await UsageService.hasUsageAccess();

      if (!mounted) return;

      setState(() {
        _hasUsageAccess = hasAccess;
      });

      if (hasAccess) {
        await _loadUsageData();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Usage access error: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUsageData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final usage = await UsageService.getUsageStats();

      debugPrint('HABITGUARD_FLUTTER_USAGE_COUNT: ${usage.length}');

      for (final app in usage) {
        debugPrint(
          'HABITGUARD_FLUTTER_APP: '
          'package=${app['packageName']} '
          'name=${app['appName']} '
          'minutes=${app['usageMinutes']}',
        );
      }

      final metrics = await UsageService.getUsageMetrics();

      final int numberOfSessions =
          (metrics['number_of_sessions'] as num?)?.toInt() ?? 0;

      final int lateNightUsage =
          (metrics['late_night_usage'] as num?)?.toInt() ?? 0;

      debugPrint('Android Total Sessions: $numberOfSessions');
      debugPrint('Android Late Night Usage: $lateNightUsage min');

      final features = FeatureService.extractFeatures(
        usage,
        numberOfSessions: numberOfSessions,
        lateNightUsage: lateNightUsage,
      );

      debugPrint('ML Features: $features');

      final prediction = await MLService.predictRisk(
        features: features,
      );

      debugPrint('ML Prediction: $prediction');

      final predictedRiskLevel =
          prediction['risk_level']?.toString() ?? 'UNKNOWN';

      final probabilities =
          prediction['probabilities'] as Map<String, dynamic>? ?? {};

      final predictedRiskConfidence =
          (probabilities[predictedRiskLevel] as num?)?.toDouble() ?? 0.0;

      final explanation =
          prediction['explanation'] as Map<String, dynamic>? ?? {};

      final summary = explanation['summary']?.toString() ?? '';

      final List<String> reasons = [];
      final reasonsRaw = explanation['reasons'];

      if (reasonsRaw is List) {
        for (final reason in reasonsRaw) {
          reasons.add(reason.toString());
        }
      }

      final featureImportance =
          prediction['feature_importance'] as Map<String, dynamic>? ?? {};

      final List<Map<String, dynamic>> topFeatures = [];
      final topFeaturesRaw = featureImportance['top_features'];

      if (topFeaturesRaw is List) {
        for (final feature in topFeaturesRaw) {
          if (feature is Map) {
            topFeatures.add(Map<String, dynamic>.from(feature));
          }
        }
      }

      final shapExplanation =
          prediction['shap_explanation'] as Map<String, dynamic>? ?? {};

      final List<Map<String, dynamic>> shapFeatures = [];
      final shapFeaturesRaw = shapExplanation['top_features'];

      if (shapFeaturesRaw is List) {
        for (final feature in shapFeaturesRaw) {
          if (feature is Map) {
            shapFeatures.add(Map<String, dynamic>.from(feature));
          }
        }
      }

      debugPrint('SHAP Features: $shapFeatures');

      if (!mounted) return;

      setState(() {
        _usageData = usage;
        _riskLevel = predictedRiskLevel;
        _riskConfidence = predictedRiskConfidence;
        _riskSummary = summary;
        _riskReasons = reasons;
        _topFeatures = topFeatures;
        _shapFeatures = shapFeatures;
        _isLoading = false;
        _hasUsageAccess = true;
      });

      final today = DateTime.now().toIso8601String().substring(0, 10);

      await HistoryService.saveUsage(
        date: today,
        apps: usage,
        riskLevel: predictedRiskLevel,
        riskConfidence: predictedRiskConfidence,
      );

      debugPrint('Saved usage for $today');

      final normalizedRisk = predictedRiskLevel.toUpperCase();
      final int totalScreenTime = usage.fold<int>(
        0,
        (total, app) =>
            total + ((app['usageMinutes'] as num?)?.toInt() ?? 0),
      );

      final bool smsSubmitted = await GuardianAlertService().processRiskLevel(
        riskLevel: normalizedRisk,
        totalScreenTime: totalScreenTime,
        riskConfidence: predictedRiskConfidence,
      );

      debugPrint('Guardian SMS submitted: $smsSubmitted; risk=$normalizedRisk');
    } catch (e) {
      debugPrint('Load usage / ML error: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load usage data.\n$e'),
        ),
      );
    }
  }

  int get _totalUsageMinutes {
    int total = 0;

    for (final app in _usageData) {
      total += (app['usageMinutes'] as num?)?.toInt() ?? 0;
    }

    return total;
  }

  Map<String, int> get _categoryUsage {
    final Map<String, int> result = {};

    for (final app in _usageData) {
      final packageName = app['packageName']?.toString() ?? '';

      final category = CategoryService.getCategory(packageName);
      final categoryName = CategoryService.getCategoryName(category);
      final minutes = (app['usageMinutes'] as num?)?.toInt() ?? 0;

      result[categoryName] = (result[categoryName] ?? 0) + minutes;
    }

    return result;
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }

    final hours = minutes ~/ 60;
    final remaining = minutes % 60;

    if (remaining == 0) {
      return '${hours}h';
    }

    return '${hours}h ${remaining}m';
  }

  Color _getRiskColor() {
    switch (_riskLevel.toUpperCase()) {
      case 'LOW':
        return Colors.green;
      case 'MODERATE':
        return Colors.orange;
      case 'HIGH':
        return Colors.red;
      case 'CRITICAL':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  String _getRiskDescription() {
    switch (_riskLevel.toUpperCase()) {
      case 'LOW':
        return 'Your current usage pattern shows relatively lower-risk behavior.';
      case 'MODERATE':
        return 'Some usage patterns indicate moderate digital wellbeing risk.';
      case 'HIGH':
        return 'Several usage patterns indicate elevated digital wellbeing risk.';
      case 'CRITICAL':
        return 'Multiple usage patterns indicate very high digital wellbeing risk.';
      default:
        return 'Risk prediction is not available yet.';
    }
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              child: Icon(icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskCard() {
    final riskColor = _getRiskColor();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.psychology),
                SizedBox(width: 8),
                Text(
                  'AI Risk Prediction',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: riskColor, width: 1.5),
                ),
                child: Text(
                  _riskLevel,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: riskColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Confidence: '
              '${(_riskConfidence * 100).toStringAsFixed(2)}%',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              _riskSummary.isNotEmpty
                  ? _riskSummary
                  : _getRiskDescription(),
            ),
            if (_riskReasons.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Why this prediction?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._riskReasons.map(
                (reason) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('\u2022 '),
                      Expanded(child: Text(reason)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureImportanceCard() {
    if (_topFeatures.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics_outlined),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Model Feature Importance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Based on Random Forest feature importance.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ..._topFeatures.map((feature) {
              final displayName =
                  feature['display_name']?.toString() ??
                  feature['feature']?.toString() ??
                  'Feature';

              final importance =
                  (feature['importance'] as num?)?.toDouble() ?? 0.0;

              final value = feature['value']?.toString() ?? '-';

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${(importance * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    LinearProgressIndicator(
                      value: importance.clamp(0.0, 1.0),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Current value: $value',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildShapExplanationCard() {
    if (_shapFeatures.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.psychology_outlined),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Why This Risk Level?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'SHAP explains how individual usage features '
              'contributed to this prediction.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ..._shapFeatures.map((feature) {
              final displayName =
                  feature['display_name']?.toString() ??
                  feature['feature']?.toString() ??
                  'Feature';

              final value = feature['value']?.toString() ?? '-';

              final shapValue =
                  (feature['shap_value'] as num?)?.toDouble() ?? 0.0;

              final impact = feature['impact']?.toString() ?? 'neutral';

              final bool supportsPredictedClass =
                  impact == 'supports predicted class';
              final bool opposesPredictedClass =
                  impact == 'opposes predicted class';

              final Color impactColor = supportsPredictedClass
                  ? Colors.red
                  : opposesPredictedClass
                      ? Colors.green
                      : Colors.grey;

              final IconData impactIcon = supportsPredictedClass
                  ? Icons.arrow_upward
                  : opposesPredictedClass
                      ? Icons.arrow_downward
                      : Icons.remove;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: impactColor.withValues(alpha: 0.08),
                    border: Border.all(
                      color: impactColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            impactColor.withValues(alpha: 0.12),
                        child: Icon(
                          impactIcon,
                          color: impactColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Current value: $value',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              impact,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: impactColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${shapValue >= 0 ? '+' : ''}'
                        '${shapValue.toStringAsFixed(4)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: impactColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 4),
            const Text(
              'Note: SHAP values represent model contribution '
              'for this prediction; they are not percentages.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard() {
    final categories = _categoryUsage.entries.toList();

    categories.sort((a, b) => b.value.compareTo(a.value));

    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.category_outlined),
                SizedBox(width: 8),
                Text(
                  'Category Usage',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...categories.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(child: Text(entry.key)),
                    Text(
                      _formatMinutes(entry.value),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppUsageCard() {
    final sortedApps = List<Map<String, dynamic>>.from(_usageData);

    // Diagnostic logs: verify which apps reach the dashboard list.
    debugPrint(
      'HABITGUARD_DASHBOARD_SORTED_COUNT: ${sortedApps.length}',
    );

    for (final app in sortedApps) {
      debugPrint(
        'HABITGUARD_DASHBOARD_APP: '
        'package=${app['packageName']} '
        'name=${app['appName']} '
        'minutes=${app['usageMinutes']}',
      );
    }

    sortedApps.sort(
      (a, b) => ((b['usageMinutes'] as num?)?.toInt() ?? 0).compareTo(
        (a['usageMinutes'] as num?)?.toInt() ?? 0,
      ),
    );

    if (sortedApps.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('No application usage data available.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.apps),
                SizedBox(width: 8),
                Text(
                  'Top App Usage',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...sortedApps.take(8).map((app) {
              final appName = app['appName']?.toString() ?? 'Unknown';
              final packageName = app['packageName']?.toString() ?? '';

              final category = CategoryService.getCategoryName(
                CategoryService.getCategory(packageName),
              );

              final minutes =
                  (app['usageMinutes'] as num?)?.toInt() ?? 0;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  child: Icon(Icons.smartphone),
                ),
                title: Text(
                  appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(category),
                trailing: Text(
                  _formatMinutes(minutes),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAccessCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.lock_outline, size: 50),
            const SizedBox(height: 16),
            const Text(
              'Usage Access Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'HabitGuard needs Usage Access permission '
              'to read your application usage statistics.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () async {
                await UsageService.openUsageAccessSettings();
              },
              icon: const Icon(Icons.settings),
              label: const Text('Open Usage Access Settings'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HabitGuard Dashboard'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WeeklyAnalyticsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Weekly Analytics',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InsightsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.insights),
            tooltip: 'Insights',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryScreen(),
                ),
              );
            },
            icon: const Icon(Icons.history),
            tooltip: 'History',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GuardianScreen(),
                ),
              );
            },
            icon: const Icon(Icons.shield_outlined),
            tooltip: 'Guardian Settings',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CoachScreen(),
                ),
              );
            },
            icon: const Icon(Icons.psychology_outlined),
            tooltip: 'Offline Wellbeing Coach',
          ),
          IconButton(
            onPressed: _isLoading ? null : _loadUsageData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUsageData,
        child: _isLoading
            ? ListView(
                children: const [
                  SizedBox(
                    height: 400,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ],
              )
            : !_hasUsageAccess
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const SizedBox(height: 40),
                      _buildNoAccessCard(),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildRiskCard(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'Screen Time',
                              value: _formatMinutes(_totalUsageMinutes),
                              icon: Icons.timer_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              title: 'Apps',
                              value: '${_usageData.length}',
                              icon: Icons.apps,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureImportanceCard(),
                      const SizedBox(height: 16),
                      _buildShapExplanationCard(),
                      const SizedBox(height: 16),
                      _buildCategoryCard(),
                      const SizedBox(height: 16),
                      _buildAppUsageCard(),
                      const SizedBox(height: 30),
                      const Center(
                        child: Text(
                          'HabitGuard - AI-powered Digital Wellbeing',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
      ),
    );
  }
}

