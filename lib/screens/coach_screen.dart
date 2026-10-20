import 'package:flutter/material.dart';

import '../services/usage_service.dart';
import '../services/intervention_service.dart';
import '../services/feature_service.dart';
import '../services/ml_service.dart';
import '../services/anomaly_service.dart';
import '../services/history_service.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  bool _loading = true;
  String _risk = 'UNKNOWN';
  double? _confidence;
  int _total = 0;
  int _sessions = 0;
  int _lateNight = 0;
  List<Map<String, dynamic>> _suggestions = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCoach();
  }

  Future<void> _loadCoach() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final usage = await UsageService.getUsageStats();
      final metrics = await UsageService.getUsageMetrics();

      final sessions =
          (metrics['number_of_sessions'] as num?)?.toInt() ?? 0;
      final lateNight =
          (metrics['late_night_usage'] as num?)?.toInt() ?? 0;

      final features = FeatureService.extractFeatures(
        usage,
        numberOfSessions: sessions,
        lateNightUsage: lateNight,
      );

      final prediction = await MLService.predictRisk(
        features: features,
      );

      final risk = prediction['risk_level']?.toString() ?? 'UNKNOWN';
      final probabilities =
          prediction['probabilities'] as Map<String, dynamic>? ?? {};
      final confidence =
          (probabilities[risk] as num?)?.toDouble();

      final total = (features['total_screen_time'] as num?)?.toInt() ?? 0;
      final social =
          (features['social_media_time'] as num?)?.toInt() ?? 0;
      final entertainment =
          (features['entertainment_time'] as num?)?.toInt() ?? 0;
      final gaming = (features['gaming_time'] as num?)?.toInt() ?? 0;

      // Keep today's history current before comparing it with previous days.
      // A local database failure must not prevent the coach from giving guidance.
      final today = DateTime.now().toIso8601String().substring(0, 10);
      try {
        await HistoryService.saveUsage(
          date: today,
          apps: usage,
          riskLevel: risk,
          riskConfidence: confidence,
        );
      } catch (e) {
        debugPrint('Coach could not refresh usage history: $e');
      }

      // Anomaly data is optional: if history is not yet sufficient, keep the
      // coach usable and generate ordinary usage-based suggestions.
      bool isAnomaly = false;
      double screenTimeChangePercentage = 0;
      try {
        final anomaly = await AnomalyService.detectTodayAnomaly();
        isAnomaly = anomaly['is_anomaly'] == true;
        final todayMinutes =
            (anomaly['today_minutes'] as num?)?.toDouble() ?? 0.0;
        final averageMinutes =
            (anomaly['average_minutes'] as num?)?.toDouble() ?? 0.0;
        screenTimeChangePercentage =
            AnomalyService.calculateDeviationPercentage(
          todayMinutes,
          averageMinutes,
        );
      } catch (e) {
        debugPrint('Coach anomaly check unavailable: $e');
      }

      final suggestions = InterventionService.generateInterventions(
        riskLevel: risk,
        totalScreenTime: total,
        lateNightUsage: lateNight,
        numberOfSessions: sessions,
        socialMediaTime: social,
        entertainmentTime: entertainment,
        gamingTime: gaming,
        isAnomaly: isAnomaly,
        screenTimeChangePercentage: screenTimeChangePercentage,
      );

      if (!mounted) return;
      setState(() {
        _total = total;
        _sessions = sessions;
        _lateNight = lateNight;
        _risk = risk;
        _confidence = confidence;
        _suggestions = suggestions;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Offline coach prediction error: $e');
      if (!mounted) return;
      setState(() {
        _error =
            'Could not generate a risk prediction. Check that the ML API '
            'is running and the phone connection is configured, then refresh.';
        _risk = 'UNKNOWN';
        _confidence = null;
        _suggestions = [];
        _loading = false;
      });
    }
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    if (hours == 0) return '$remaining min';
    if (remaining == 0) return '${hours}h';
    return '${hours}h ${remaining}m';
  }

  Color _riskColor() {
    switch (_risk.toUpperCase()) {
      case 'CRITICAL':
        return Colors.red;
      case 'HIGH':
        return Colors.deepOrange;
      case 'MODERATE':
        return Colors.orange;
      case 'LOW':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Wellbeing Coach'),
        actions: [
          IconButton(
            tooltip: 'Refresh usage',
            onPressed: _loading ? null : _loadCoach,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCoach,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.shield_moon, size: 28),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Your digital wellbeing guide',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Risk is predicted using your recorded phone usage '
                            'and the HabitGuard ML model. Suggestions are '
                            'rule-based and work without a GenAI API key.',
                          ),
                          const SizedBox(height: 14),
                          Chip(
                            avatar: Icon(
                              Icons.health_and_safety,
                              color: _riskColor(),
                            ),
                            label: Text('Current ML risk: $_risk'),
                          ),
                          if (_confidence != null)
                            Text(
                              'Model confidence: '
                              '${(_confidence! * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Today at a glance',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _metric(
                            Icons.phone_android,
                            'Screen time',
                            _formatMinutes(_total),
                          ),
                          _metric(
                            Icons.touch_app,
                            'App sessions',
                            '$_sessions',
                          ),
                          _metric(
                            Icons.nightlight_round,
                            'Late-night usage',
                            _formatMinutes(_lateNight),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your suggested actions',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_error != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_error!),
                      ),
                    )
                  else if (_suggestions.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No specific suggestions are available yet. '
                          'Refresh after usage data has been recorded.',
                        ),
                      ),
                    )
                  else
                    ..._suggestions.map((item) {
                      final priority =
                          item['priority']?.toString() ?? 'low';
                      final color = priority == 'high'
                          ? Colors.deepOrange
                          : priority == 'medium'
                              ? Colors.orange
                              : Colors.green;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    color: color,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item['title']?.toString() ??
                                          'Wellbeing suggestion',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(item['message']?.toString() ?? ''),
                              const SizedBox(height: 8),
                              Text(
                                'Try this: ${item['action'] ?? ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 12),
                  const Text(
                    'This coach provides digital-wellbeing guidance, '
                    'not a medical diagnosis. Suggestions are rule-based, '
                    'not generated by a conversational AI model.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _metric(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
