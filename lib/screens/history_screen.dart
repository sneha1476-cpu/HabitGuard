
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/history_service.dart';
import '../services/category_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;

  List<Map<String, dynamic>> _usageData = [];
  Map<String, dynamic>? _dailyData;
  List<Map<String, dynamic>> _allDailyData = [];

  // Date selected for viewing saved app usage.
  DateTime _selectedUsageDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String _displayDate(DateTime date) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    if (_dateKey(date) == _dateKey(today)) {
      return 'Today';
    }

    if (_dateKey(date) == _dateKey(yesterday)) {
      return 'Yesterday';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _selectUsageDate() async {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedUsageDate,
      firstDate: DateTime(2020),
      lastDate: todayOnly,
      helpText: 'Select app usage date',
    );

    if (pickedDate == null || !mounted) return;

    setState(() {
      _selectedUsageDate = pickedDate;
      _isLoading = true;
    });

    await _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final today = _dateKey(DateTime.now());
      final selectedDate = _dateKey(_selectedUsageDate);

      // App usage comes from the date selected by the user.
      final usageData =
          await HistoryService.getUsageForDate(selectedDate);

      // Keep the risk summary for today.
      final dailyData =
          await HistoryService.getDailyUsage(today);

      // Load saved daily records for the risk trend.
      final allDailyData =
          await HistoryService.getAllDailyUsage();

      if (!mounted) return;

      setState(() {
        _usageData = usageData;
        _dailyData = dailyData;
        _allDailyData = allDailyData;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('History error: $e');

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

    final hours = minutes ~/ 60;
    final remaining = minutes % 60;

    if (remaining == 0) {
      return '$hours hr';
    }

    return '$hours hr $remaining min';
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
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  double _getRiskValue(String risk) {
    switch (risk.toUpperCase()) {
      case 'LOW':
        return 1;
      case 'MODERATE':
        return 2;
      case 'HIGH':
        return 3;
      case 'CRITICAL':
        return 4;
      default:
        return 0;
    }
  }

  String _getRiskLabel(double value) {
    switch (value.toInt()) {
      case 1:
        return 'LOW';
      case 2:
        return 'MOD';
      case 3:
        return 'HIGH';
      case 4:
        return 'CRIT';
      default:
        return '';
    }
  }

  Widget _buildRiskTrendChart() {
    if (_allDailyData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text('No risk history available yet.'),
          ),
        ),
      );
    }

    final chartData =
        List<Map<String, dynamic>>.from(_allDailyData);

    chartData.sort(
      (a, b) => a['date']
          .toString()
          .compareTo(b['date'].toString()),
    );

    final spots = <FlSpot>[];

    for (int i = 0; i < chartData.length; i++) {
      final risk =
          chartData[i]['risk_level']?.toString() ?? '';

      final riskValue = _getRiskValue(risk);

      if (riskValue > 0) {
        spots.add(FlSpot(i.toDouble(), riskValue));
      }
    }

    if (spots.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text('Risk data is not available yet.'),
          ),
        ),
      );
    }

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Risk Trend',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Daily digital wellbeing risk level',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 260,
              child: LineChart(
                LineChartData(
                  minY: 0.5,
                  maxY: 4.5,
                  minX: 0,
                  maxX: chartData.length > 1
                      ? (chartData.length - 1).toDouble()
                      : 1,
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 1,
                  ),
                  borderData: FlBorderData(show: true),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 55,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _getRiskLabel(value),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 35,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();

                          if (index < 0 ||
                              index >= chartData.length) {
                            return const SizedBox();
                          }

                          final date =
                              chartData[index]['date']
                                      ?.toString() ??
                                  '';

                          if (date.length < 10) {
                            return const SizedBox();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              date.substring(5),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Wrap(
              alignment: WrapAlignment.spaceAround,
              spacing: 12,
              runSpacing: 6,
              children: [
                Text('1 = Low', style: TextStyle(fontSize: 12)),
                Text('2 = Moderate', style: TextStyle(fontSize: 12)),
                Text('3 = High', style: TextStyle(fontSize: 12)),
                Text('4 = Critical', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppUsageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'App Usage History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.calendar_month),
            title: Text(_displayDate(_selectedUsageDate)),
            subtitle: Text(_dateKey(_selectedUsageDate)),
            trailing: const Icon(Icons.edit_calendar),
            onTap: _selectUsageDate,
          ),
        ),
        const SizedBox(height: 8),
        if (_usageData.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No saved app usage found for '
                  '${_displayDate(_selectedUsageDate).toLowerCase()}.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          ...(() {
            final grouped =
                <String, List<Map<String, dynamic>>>{};

            for (final app in _usageData) {
              final packageName =
                  app['package_name']?.toString() ?? '';

              final category = CategoryService.getCategoryName(
                CategoryService.getCategory(packageName),
              );

              grouped
                  .putIfAbsent(category, () => [])
                  .add(app);
            }

            final categories = grouped.keys.toList()..sort();

            return categories.map((category) {
              final apps = grouped[category]!;

              final categoryMinutes = apps.fold<int>(
                0,
                (sum, app) =>
                    sum +
                    ((app['usage_minutes'] as num?)?.toInt() ?? 0),
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ExpansionTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.folder_outlined),
                  ),
                  title: Text(
                    category,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Text(
                    _formatMinutes(categoryMinutes),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  children: apps.map((app) {
                    final appName =
                        app['app_name']?.toString() ?? 'Unknown App';

                    final minutes =
                        (app['usage_minutes'] as num?)?.toInt() ?? 0;

                    return ListTile(
                      leading: const Icon(Icons.smartphone),
                      title: Text(appName),
                      trailing: Text(_formatMinutes(minutes)),
                    );
                  }).toList(),
                ),
              );
            }).toList();
          })(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final riskLevel =
        _dailyData?['risk_level']?.toString() ?? 'N/A';

    final confidence =
        (_dailyData?['risk_confidence'] as num?)?.toDouble() ??
            0.0;

    final totalMinutes =
        (_dailyData?['total_minutes'] as num?)?.toInt() ?? 0;

    final riskColor = _getRiskColor(riskLevel);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usage History'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    "Today's Risk Summary",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor:
                                    riskColor.withValues(alpha: 0.15),
                                child: Icon(
                                  Icons.health_and_safety,
                                  color: riskColor,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Risk Level',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      riskLevel,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: riskColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Icon(Icons.timer, size: 28),
                                  const SizedBox(height: 5),
                                  Text(
                                    _formatMinutes(totalMinutes),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text('Screen Time'),
                                ],
                              ),
                              Column(
                                children: [
                                  const Icon(Icons.analytics, size: 28),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${(confidence * 100).toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text('Confidence'),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildRiskTrendChart(),
                  const SizedBox(height: 24),
                  _buildAppUsageSection(),
                ],
              ),
            ),
    );
  }
}