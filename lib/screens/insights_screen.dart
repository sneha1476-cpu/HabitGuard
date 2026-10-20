import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/usage_service.dart';
import '../services/category_service.dart';
import '../services/history_service.dart';
import '../services/wellness_service.dart';
import '../services/trend_service.dart';
import '../services/anomaly_service.dart';
import '../services/intervention_service.dart';

class InsightsScreen extends StatefulWidget {
const InsightsScreen({super.key});

@override
State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
bool _isLoading = true;

List<Map<String, dynamic>> _apps = [];

int _totalScreenTime = 0;
int _sessions = 0;
int _lateNightUsage = 0;

String _riskLevel = 'N/A';
double _confidence = 0.0;

int _wellnessScore = 0;
String _wellnessLabel = '';
String _wellnessMessage = '';

Map<String, int> _categoryUsage = {};

// 7-day trend data
List<Map<String, dynamic>> _usageTrend = [];

double _averageScreenTime = 0.0;
double _maximumScreenTime = 0.0;
double _minimumScreenTime = 0.0;
double _screenTimeChange = 0.0;

List<String> _riskTrend = [];

// Anomaly detection data
Map<String, dynamic> _anomalyData = {};

// Adaptive intervention data
List<Map<String, dynamic>> _interventions = [];

@override
void initState() {
super.initState();
_loadInsights();
}

Future<void> _loadInsights() async {
try {
final usageData = await UsageService.getUsageStats();

  final List<Map<String, dynamic>> apps =
      List<Map<String, dynamic>>.from(
    usageData.map(
      (app) => Map<String, dynamic>.from(app),
    ),
  );

  int totalMinutes = 0;

  final Map<String, int> categories = {};

  for (final app in apps) {
    final int minutes = (app['usageMinutes'] ?? 0) as int;

    totalMinutes += minutes;

    final String category = CategoryService.getCategoryName(
      CategoryService.getCategory(
        app['packageName']?.toString() ?? '',
      ),
    );

    categories[category] =
        (categories[category] ?? 0) + minutes;
  }

  final metrics = await UsageService.getUsageMetrics();

  final int sessions =
      (metrics['number_of_sessions'] ?? 0) as int;

  final int lateNight =
      (metrics['late_night_usage'] ?? 0) as int;

  final today =
      DateTime.now().toIso8601String().split('T')[0];

  final dailyData =
      await HistoryService.getDailyUsage(today);

  final String risk =
      dailyData?['risk_level']?.toString() ?? 'N/A';

  final double confidence =
      (dailyData?['risk_confidence'] as num?)?.toDouble() ??
          0.0;

  // Calculate Digital Wellness Score
  final int wellnessScore =
      WellnessService.calculateScore(
    totalScreenTime: totalMinutes,
    lateNightUsage: lateNight,
    numberOfSessions: sessions,
    numberOfApps: apps.length,
    riskLevel: risk,
  );

  final String wellnessLabel =
      WellnessService.getLabel(wellnessScore);

  final String wellnessMessage =
      WellnessService.getMessage(wellnessScore);

  // Load 7-day trend data
  final trendData =
      await TrendService.getUsageTrend();

  final double averageScreenTime =
      TrendService.calculateAverageScreenTime(
    trendData,
  );

  final double maximumScreenTime =
      TrendService.calculateMaximumScreenTime(
    trendData,
  );

  final double minimumScreenTime =
      TrendService.calculateMinimumScreenTime(
    trendData,
  );

  final double screenTimeChange =
      TrendService.calculateScreenTimeChange(
    trendData,
  );

  final List<String> riskTrend =
      TrendService.getRiskTrend(trendData);

  // Load anomaly detection data
  final Map<String, dynamic> anomalyData =
      await AnomalyService.detectTodayAnomaly();

  // ---------------------------------------------------------
  // Calculate category-specific usage
  // ---------------------------------------------------------
  final int socialMediaTime =
      categories['Social Media'] ?? 0;

  final int entertainmentTime =
      categories['Entertainment'] ?? 0;

  final int gamingTime =
      categories['Games'] ?? 0;

  // ---------------------------------------------------------
  // Calculate screen-time change percentage
  // ---------------------------------------------------------
  double screenTimeChangePercentage = 0.0;

  if (trendData.length >= 2) {
    final double firstDayMinutes =
        (trendData.first['total_minutes'] as num?)
                ?.toDouble() ??
            0.0;

    if (firstDayMinutes > 0) {
      screenTimeChangePercentage =
          (screenTimeChange / firstDayMinutes) * 100;

      if (screenTimeChangePercentage < 0) {
        screenTimeChangePercentage = 0;
      }
    }
  }

  // ---------------------------------------------------------
  // Read anomaly status
  // ---------------------------------------------------------
  final bool isAnomaly =
      anomalyData['is_anomaly'] == true;

  // ---------------------------------------------------------
  // Generate adaptive interventions
  // ---------------------------------------------------------
  final List<Map<String, dynamic>> interventions =
      InterventionService.generateInterventions(
    riskLevel: risk,
    totalScreenTime: totalMinutes,
    lateNightUsage: lateNight,
    numberOfSessions: sessions,
    socialMediaTime: socialMediaTime,
    entertainmentTime: entertainmentTime,
    gamingTime: gamingTime,
    isAnomaly: isAnomaly,
    screenTimeChangePercentage:
        screenTimeChangePercentage,
  );

  if (!mounted) return;

  setState(() {
    _apps = apps;
    _totalScreenTime = totalMinutes;
    _sessions = sessions;
    _lateNightUsage = lateNight;
    _categoryUsage = categories;

    _riskLevel = risk;
    _confidence = confidence;

    _wellnessScore = wellnessScore;
    _wellnessLabel = wellnessLabel;
    _wellnessMessage = wellnessMessage;

    // Trend data
    _usageTrend = trendData;
    _averageScreenTime = averageScreenTime;
    _maximumScreenTime = maximumScreenTime;
    _minimumScreenTime = minimumScreenTime;
    _screenTimeChange = screenTimeChange;
    _riskTrend = riskTrend;

    // Anomaly data
    _anomalyData = anomalyData;

    // Adaptive interventions
    _interventions = interventions;

    _isLoading = false;
  });
} catch (e) {
  debugPrint('Insights error: $e');

  if (!mounted) return;

  setState(() {
    _isLoading = false;
  });
}

}

String _formatMinutes(int minutes) {
if (minutes < 60) {
return '$minutes min';
}

final int hours = minutes ~/ 60;
final int remaining = minutes % 60;

if (remaining == 0) {
  return '${hours}h';
}

return '${hours}h ${remaining}m';

}

String _formatDoubleMinutes(double minutes) {
return TrendService.formatMinutes(minutes);
}

Color _getRiskColor(String risk) {
switch (risk.toUpperCase()) {
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

Color _getWellnessColor(int score) {
if (score >= 80) {
return Colors.green;
}

if (score >= 60) {
  return Colors.lightGreen;
}

if (score >= 40) {
  return Colors.orange;
}

return Colors.red;

}

Color _getPriorityColor(String priority) {
switch (priority.toLowerCase()) {
case 'high':
return Colors.red;

  case 'medium':
    return Colors.orange;

  case 'low':
    return Colors.green;

  default:
    return Colors.blue;
}

}

IconData _getInterventionIcon(String type) {
switch (type) {
case 'late_night':
return Icons.nightlight_round;

  case 'frequent_sessions':
    return Icons.touch_app;

  case 'social_media':
    return Icons.people;

  case 'entertainment':
    return Icons.movie;

  case 'gaming':
    return Icons.sports_esports;

  case 'increasing_trend':
    return Icons.trending_up;

  case 'anomaly':
    return Icons.warning_amber_rounded;

  case 'overall_risk':
    return Icons.health_and_safety_outlined;

  case 'moderate_risk':
    return Icons.balance;

  case 'positive':
    return Icons.check_circle_outline;

  default:
    return Icons.lightbulb_outline;
}

}

String _getInsightMessage() {
if (_totalScreenTime >= 360) {
return 'Your total screen time is high. Try taking regular digital breaks.';
}

if (_lateNightUsage >= 60) {
  return 'You have significant late-night usage. Consider reducing phone usage before sleep.';
}

if (_sessions >= 150) {
  return 'You have frequent app sessions. Try reducing unnecessary phone checking.';
}

if (_riskLevel == 'LOW') {
  return 'Your current usage pattern looks relatively balanced. Keep maintaining healthy digital habits.';
}

if (_riskLevel == 'MODERATE') {
  return 'Some usage patterns need attention. Small daily changes can improve your digital wellbeing.';
}

if (_riskLevel == 'HIGH') {
  return 'Several usage patterns indicate elevated risk. Consider reducing high-usage activities.';
}

if (_riskLevel == 'CRITICAL') {
  return 'Your current usage pattern is very high. Consider taking stronger steps to reduce excessive usage.';
}

return 'Continue monitoring your digital usage to understand your habits better.';

}

Widget _buildWellnessScoreCard() {
final Color scoreColor =
_getWellnessColor(_wellnessScore);

return Card(
  elevation: 2,
  child: Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.spa_outlined,
              color: scoreColor,
              size: 28,
            ),
            const SizedBox(width: 10),
            const Text(
              'Digital Wellness Score',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: CircularProgressIndicator(
                value: _wellnessScore / 100,
                strokeWidth: 14,
                backgroundColor: Colors.grey.shade200,
                color: scoreColor,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_wellnessScore',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
                const Text(
                  '/ 100',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          _wellnessLabel,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: scoreColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _wellnessMessage,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade700,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: scoreColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Digital wellbeing indicator â€¢ Not a medical diagnosis',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
            ),
          ),
        ),
      ],
    ),
  ),
);

}

Widget _buildMetricCard({
required IconData icon,
required String title,
required String value,
required String subtitle,
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
const SizedBox(width: 14),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
title,
style: const TextStyle(
fontWeight: FontWeight.w600,
),
),
const SizedBox(height: 4),
Text(
value,
style: const TextStyle(
fontSize: 22,
fontWeight: FontWeight.bold,
),
),
Text(
subtitle,
style: TextStyle(
color: Colors.grey.shade600,
fontSize: 12,
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
final color = _getRiskColor(_riskLevel);

return Card(
  child: Padding(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: color,
            ),
            const SizedBox(width: 8),
            const Text(
              'Current Risk',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                _riskLevel,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            Text(
              '${(_confidence * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Model confidence',
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    ),
  ),
);

}

Widget _buildTrendAnalysisCard() {
if (_usageTrend.isEmpty) {
return Card(
child: Padding(
padding: const EdgeInsets.all(18),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
const Icon(Icons.show_chart),
const SizedBox(width: 8),
const Text(
'7-Day Trend Analysis',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),
],
),
const SizedBox(height: 12),
Text(
'Not enough historical data available yet.',
style: TextStyle(
color: Colors.grey.shade600,
),
),
const SizedBox(height: 6),
Text(
'Continue using HabitGuard to build your usage history.',
style: TextStyle(
fontSize: 12,
color: Colors.grey.shade500,
),
),
],
),
),
);
}

final bool usageIncreased = _screenTimeChange > 0;
final bool usageDecreased = _screenTimeChange < 0;

final Color changeColor = usageIncreased
    ? Colors.red
    : usageDecreased
        ? Colors.green
        : Colors.grey;

final IconData changeIcon = usageIncreased
    ? Icons.trending_up
    : usageDecreased
        ? Icons.trending_down
        : Icons.remove;

final String changeText = _screenTimeChange.abs() < 1
    ? 'No significant change'
    : usageIncreased
        ? 'Screen time increased'
        : 'Screen time decreased';

return Card(
  elevation: 2,
  child: Padding(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.show_chart,
              size: 26,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                '7-Day Trend Analysis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Behavioral usage trend based on saved daily history.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _buildTrendStat(
                'Average',
                _formatDoubleMinutes(
                  _averageScreenTime,
                ),
                Icons.analytics_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTrendStat(
                'Highest',
                _formatDoubleMinutes(
                  _maximumScreenTime,
                ),
                Icons.arrow_upward,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildTrendStat(
                'Lowest',
                _formatDoubleMinutes(
                  _minimumScreenTime,
                ),
                Icons.arrow_downward,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTrendStat(
                'Days',
                '${_usageTrend.length}',
                Icons.calendar_today_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: changeColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: changeColor.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    changeColor.withValues(alpha: 0.12),
                child: Icon(
                  changeIcon,
                  color: changeColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      changeText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: changeColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _screenTimeChange.abs() < 1
                          ? 'Compared with the first available day'
                          : '${_formatDoubleMinutes(_screenTimeChange.abs())} difference from the first available day',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Risk Trend',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        if (_riskTrend.isEmpty)
          Text(
            'No risk history available.',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _riskTrend.asMap().entries.map(
              (entry) {
                final int index = entry.key;
                final String risk = entry.value;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _getRiskColor(risk).withValues(
                      alpha: 0.1,
                    ),
                    borderRadius:
                        BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          _getRiskColor(risk).withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                  child: Text(
                    'Day ${index + 1}: $risk',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getRiskColor(risk),
                    ),
                  ),
                );
              },
            ).toList(),
          ),
        const SizedBox(height: 14),
        Text(
          'Trend analysis is based on your recorded usage history and is not a medical assessment.',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    ),
  ),
);

}

Widget _buildTrendStat(
String title,
String value,
IconData icon,
) {
return Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: Colors.grey.shade100,
borderRadius: BorderRadius.circular(12),
),
child: Row(
children: [
Icon(
icon,
size: 20,
),
const SizedBox(width: 8),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
title,
style: TextStyle(
fontSize: 11,
color: Colors.grey.shade600,
),
),
const SizedBox(height: 2),
Text(
value,
style: const TextStyle(
fontWeight: FontWeight.bold,
fontSize: 15,
),
),
],
),
),
],
),
);
}

Widget _buildScreenTimeChart() {
if (_usageTrend.isEmpty) {
return const SizedBox.shrink();
}

final List<FlSpot> spots = [];

for (int i = 0; i < _usageTrend.length; i++) {
  final double minutes =
      (_usageTrend[i]['total_minutes'] as num?)
              ?.toDouble() ??
          0.0;

  spots.add(
    FlSpot(
      i.toDouble(),
      minutes,
    ),
  );
}

double maxY = 0;

for (final spot in spots) {
  if (spot.y > maxY) {
    maxY = spot.y;
  }
}

if (maxY < 60) {
  maxY = 60;
}

maxY += 30;

return Card(
  elevation: 2,
  child: Padding(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '7-Day Screen Time Trend',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Daily screen time based on recorded usage history.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 250,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: true),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 35,
                    getTitlesWidget:
                        (value, meta) {
                      final int index = value.toInt();

                      if (index < 0 ||
                          index >=
                              _usageTrend.length) {
                        return const SizedBox.shrink();
                      }

                      final String date =
                          _usageTrend[index]['date']
                                  ?.toString() ??
                              '';

                      String label = date;

                      if (date.length >= 10) {
                        label = date.substring(5);
                      }

                      return Padding(
                        padding:
                            const EdgeInsets.only(top: 8),
                        child: Text(
                          label,
                          style:
                              const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    getTitlesWidget:
                        (value, meta) {
                      return Text(
                        '${value.toInt()}m',
                        style:
                            const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  barWidth: 3,
                  dotData:
                      const FlDotData(show: true),
                  belowBarData:
                      BarAreaData(show: true),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Higher values indicate more daily screen time.',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    ),
  ),
);

}

Widget _buildAnomalyCard() {
if (_anomalyData.isEmpty) {
return const SizedBox.shrink();
}

final bool isAnomaly =
    _anomalyData['is_anomaly'] == true;

final double todayMinutes =
    (_anomalyData['today_minutes'] as num?)
            ?.toDouble() ??
        0.0;

final double averageMinutes =
    (_anomalyData['average_minutes'] as num?)
            ?.toDouble() ??
        0.0;

final double differenceMinutes =
    (_anomalyData['difference_minutes'] as num?)
            ?.toDouble() ??
        0.0;

final double deviationPercentage =
    AnomalyService.calculateDeviationPercentage(
  todayMinutes,
  averageMinutes,
);

final Color cardColor =
    isAnomaly ? Colors.orange : Colors.green;

final IconData icon =
    isAnomaly
        ? Icons.warning_amber_rounded
        : Icons.check_circle_outline;

final String title =
    isAnomaly
        ? 'Unusual Usage Detected'
        : 'Usage Pattern Looks Normal';

return Card(
  elevation: 2,
  child: Padding(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: cardColor,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cardColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _anomalyData['message']?.toString() ?? '',
          style: const TextStyle(
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTrendStat(
                'Today',
                AnomalyService.formatMinutes(
                  todayMinutes,
                ),
                Icons.today,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTrendStat(
                'Recent Avg',
                AnomalyService.formatMinutes(
                  averageMinutes,
                ),
                Icons.analytics_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (averageMinutes > 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              differenceMinutes >= 0
                  ? '${deviationPercentage.abs().toStringAsFixed(1)}% higher than recent average'
                  : '${deviationPercentage.abs().toStringAsFixed(1)}% lower than recent average',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cardColor,
              ),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          'Anomaly detection compares your current usage with your recent personal usage pattern.',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    ),
  ),
);

}

// ---------------------------------------------------------
// Adaptive Intervention Card
// ---------------------------------------------------------
Widget _buildInterventionCard() {
if (_interventions.isEmpty) {
return const SizedBox.shrink();
}

return Card(
  elevation: 2,
  child: Padding(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 27,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Adaptive Recommendations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Personalized suggestions based on your current usage behavior.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        ..._interventions.map(
          (intervention) {
            final String type =
                intervention['type']?.toString() ?? '';

            final String priority =
                intervention['priority']?.toString() ?? 'low';

            final String title =
                intervention['title']?.toString() ??
                    'Digital wellbeing suggestion';

            final String message =
                intervention['message']?.toString() ?? '';

            final String action =
                intervention['action']?.toString() ?? '';

            final Color priorityColor =
                _getPriorityColor(priority);

            return Container(
              margin:
                  const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:
                    priorityColor.withValues(alpha: 0.06),
                borderRadius:
                    BorderRadius.circular(14),
                border: Border.all(
                  color:
                      priorityColor.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 21,
                        backgroundColor:
                            priorityColor.withValues(
                          alpha: 0.12,
                        ),
                        child: Icon(
                          _getInterventionIcon(type),
                          color: priorityColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style:
                                        const TextStyle(
                                      fontSize: 15,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color: priorityColor
                                        .withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      12,
                                    ),
                                  ),
                                  child: Text(
                                    priority
                                        .toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight:
                                          FontWeight.bold,
                                      color:
                                          priorityColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              message,
                              style: const TextStyle(
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.tips_and_updates_outlined,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            action,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          'These recommendations support digital wellbeing and are not medical advice.',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    ),
  ),
);

}

Widget _buildCategorySection() {
final entries =
_categoryUsage.entries.toList();

entries.sort(
  (a, b) => b.value.compareTo(a.value),
);

if (entries.isEmpty) {
  return const Card(
    child: Padding(
      padding: EdgeInsets.all(20),
      child: Text(
        'No category usage data available.',
      ),
    ),
  );
}

return Card(
  child: Padding(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Category Usage',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        ...entries.map(
          (entry) {
            final double percentage =
                _totalScreenTime == 0
                    ? 0
                    : entry.value / _totalScreenTime;

            return Padding(
              padding:
                  const EdgeInsets.only(bottom: 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        _getCategoryIcon(entry.key),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        _formatMinutes(entry.value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  LinearProgressIndicator(
                    value: percentage,
                    minHeight: 7,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    ),
  ),
);

}

IconData _getCategoryIcon(String category) {
switch (category) {
case 'Social Media':
return Icons.people;

  case 'Entertainment':
    return Icons.movie;

  case 'Communication':
    return Icons.chat;

  case 'Education':
    return Icons.school;

  case 'Games':
    return Icons.sports_esports;

  case 'Productivity':
    return Icons.work;

  case 'Finance':
    return Icons.account_balance;

  case 'Shopping':
    return Icons.shopping_cart;

  case 'Browser':
    return Icons.language;

  case 'Utilities':
    return Icons.build;

  default:
    return Icons.apps;
}

}

Widget _buildTopAppsSection() {
final sortedApps =
List<Map<String, dynamic>>.from(_apps);

sortedApps.sort(
  (a, b) =>
      ((b['usageMinutes'] ?? 0) as int).compareTo(
    (a['usageMinutes'] ?? 0) as int,
  ),
);

final topApps =
    sortedApps.take(5).toList();

if (topApps.isEmpty) {
  return const Card(
    child: Padding(
      padding: EdgeInsets.all(20),
      child: Text(
        'No app usage data available.',
      ),
    ),
  );
}

return Card(
  child: Padding(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Most Used Apps',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...topApps.asMap().entries.map(
          (entry) {
            final int index = entry.key;
            final Map<String, dynamic> app =
                entry.value;

            final String appName =
                app['appName']?.toString() ??
                    'Unknown';

            final int minutes =
                (app['usageMinutes'] ?? 0) as int;

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                child: Text('${index + 1}'),
              ),
              title: Text(appName),
              subtitle: Text(
                app['category']?.toString() ??
                    'Other',
              ),
              trailing: Text(
                _formatMinutes(minutes),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ],
    ),
  ),
);

}

Widget _buildRecommendationCard() {
return Card(
child: Padding(
padding: const EdgeInsets.all(18),
child: Row(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
const Icon(
Icons.lightbulb_outline,
size: 30,
),
const SizedBox(width: 14),
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
const Text(
'HabitGuard Insight',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 8),
Text(
_getInsightMessage(),
style: const TextStyle(
height: 1.4,
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

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('Insights'),
actions: [
IconButton(
onPressed: _loadInsights,
icon: const Icon(Icons.refresh),
tooltip: 'Refresh',
),
],
),
body: _isLoading
? const Center(
child: CircularProgressIndicator(),
)
: RefreshIndicator(
onRefresh: _loadInsights,
child: ListView(
padding: const EdgeInsets.all(16),
children: [
_buildWellnessScoreCard(),

              const SizedBox(height: 12),

              _buildRiskCard(),

              const SizedBox(height: 12),

              _buildTrendAnalysisCard(),

              const SizedBox(height: 12),

              _buildAnomalyCard(),

              const SizedBox(height: 12),

              _buildInterventionCard(),

              const SizedBox(height: 12),

              _buildScreenTimeChart(),

              const SizedBox(height: 12),

              _buildMetricCard(
                icon: Icons.phone_android,
                title: 'Screen Time',
                value:
                    _formatMinutes(_totalScreenTime),
                subtitle:
                    'Total usage today',
              ),

              _buildMetricCard(
                icon: Icons.touch_app,
                title: 'App Sessions',
                value: '$_sessions',
                subtitle:
                    'Total sessions today',
              ),

              _buildMetricCard(
                icon: Icons.nightlight_round,
                title: 'Late Night Usage',
                value:
                    _formatMinutes(_lateNightUsage),
                subtitle:
                    'Usage during late hours',
              ),

              const SizedBox(height: 12),

              _buildCategorySection(),

              const SizedBox(height: 12),

              _buildTopAppsSection(),

              const SizedBox(height: 12),

              _buildRecommendationCard(),

              const SizedBox(height: 20),
            ],
          ),
        ),
);

}
}

