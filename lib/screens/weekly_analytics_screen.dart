import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/history_service.dart';

class WeeklyAnalyticsScreen extends StatefulWidget {
  const WeeklyAnalyticsScreen({super.key});

  @override
  State<WeeklyAnalyticsScreen> createState() =>
      _WeeklyAnalyticsScreenState();
}

class _WeeklyAnalyticsScreenState
    extends State<WeeklyAnalyticsScreen> {
  bool _isLoading = true;

  List<Map<String, dynamic>> _weeklyData = [];

  int _averageScreenTime = 0;
  int _highestScreenTime = 0;
  String _highestScreenTimeDate = '-';

  @override
  void initState() {
    super.initState();
    _loadWeeklyData();
  }

  Future<void> _loadWeeklyData() async {
    try {
      final data =
          await HistoryService.getLast7DaysUsage();

      int total = 0;
      int highest = 0;
      String highestDate = '-';

      for (final day in data) {
        final int minutes =
            (day['total_minutes'] ?? 0) as int;

        total += minutes;

        if (minutes > highest) {
          highest = minutes;
          highestDate =
              day['date']?.toString() ?? '-';
        }
      }

      final int average =
          data.isEmpty
              ? 0
              : (total / data.length).round();

      if (!mounted) return;

      setState(() {
        _weeklyData = data.reversed.toList();
        _averageScreenTime = average;
        _highestScreenTime = highest;
        _highestScreenTimeDate = highestDate;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'Weekly analytics error: $e',
      );

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

  double _getRiskValue(String risk) {
    switch (risk) {
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

  String _formatDate(String date) {
    try {
      final parts = date.split('-');

      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}';
      }
    } catch (_) {}

    return date;
  }

  Widget _buildSummaryCard({
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
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          Colors.grey.shade600,
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

  Widget _buildScreenTimeChart() {
    if (_weeklyData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Not enough data for screen-time trend.',
          ),
        ),
      );
    }

    double maxY = 60;

    for (final day in _weeklyData) {
      final int minutes =
          (day['total_minutes'] ?? 0)
              as int;

      if (minutes > maxY) {
        maxY = minutes.toDouble();
      }
    }

    maxY =
        ((maxY / 60).ceil() * 60).toDouble();

    if (maxY == 0) {
      maxY = 60;
    }

    final spots = <FlSpot>[];

    for (int i = 0;
        i < _weeklyData.length;
        i++) {
      final int minutes =
          (_weeklyData[i]['total_minutes'] ??
                  0)
              as int;

      spots.add(
        FlSpot(
          i.toDouble(),
          minutes.toDouble(),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          12,
          18,
          18,
          18,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Padding(
              padding:
                  EdgeInsets.only(left: 6),
              child: Text(
                'Screen Time Trend',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX:
                      (_weeklyData.length - 1)
                          .toDouble(),
                  minY: 0,
                  maxY: maxY,
                  gridData:
                      const FlGridData(
                    show: true,
                  ),
                  borderData:
                      FlBorderData(
                    show: true,
                  ),
                  titlesData:
                      FlTitlesData(
                    topTitles:
                        const AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles: false,
                      ),
                    ),
                    rightTitles:
                        const AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles: false,
                      ),
                    ),
                    leftTitles:
                        const AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                      ),
                    ),
                    bottomTitles:
                        AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        getTitlesWidget:
                            (value, meta) {
                          final int index =
                              value.toInt();

                          if (index < 0 ||
                              index >=
                                  _weeklyData
                                      .length) {
                            return const SizedBox();
                          }

                          final String date =
                              _weeklyData[index]
                                          ['date']
                                      ?.toString() ??
                                  '';

                          return Padding(
                            padding:
                                const EdgeInsets
                                    .only(
                              top: 8,
                            ),
                            child: Text(
                              _formatDate(
                                date,
                              ),
                              style:
                                  const TextStyle(
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 4,
                      dotData:
                          const FlDotData(
                        show: true,
                      ),
                      belowBarData:
                          BarAreaData(
                        show: true,
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

  Widget _buildRiskTrend() {
    if (_weeklyData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Not enough data for risk trend.',
          ),
        ),
      );
    }

    final spots = <FlSpot>[];

    for (int i = 0;
        i < _weeklyData.length;
        i++) {
      final String risk =
          _weeklyData[i]['risk_level']
                  ?.toString() ??
              '';

      final double value =
          _getRiskValue(risk);

      if (value > 0) {
        spots.add(
          FlSpot(
            i.toDouble(),
            value,
          ),
        );
      }
    }

    if (spots.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Risk information is not available yet.',
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          12,
          18,
          18,
          18,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Risk Trend',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 240,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX:
                      (_weeklyData.length - 1)
                          .toDouble(),
                  minY: 0.5,
                  maxY: 4.5,
                  gridData:
                      const FlGridData(
                    show: true,
                  ),
                  borderData:
                      FlBorderData(
                    show: true,
                  ),
                  titlesData:
                      FlTitlesData(
                    topTitles:
                        const AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles: false,
                      ),
                    ),
                    rightTitles:
                        const AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles: false,
                      ),
                    ),
                    leftTitles:
                        AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles: true,
                        reservedSize: 70,
                        getTitlesWidget:
                            (value, meta) {
                          String label = '';

                          if (value == 1) {
                            label = 'LOW';
                          } else if (value ==
                              2) {
                            label =
                                'MODERATE';
                          } else if (value ==
                              3) {
                            label = 'HIGH';
                          } else if (value ==
                              4) {
                            label =
                                'CRITICAL';
                          }

                          return Text(
                            label,
                            style:
                                const TextStyle(
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles:
                        AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        getTitlesWidget:
                            (value, meta) {
                          final int index =
                              value.toInt();

                          if (index < 0 ||
                              index >=
                                  _weeklyData
                                      .length) {
                            return const SizedBox();
                          }

                          final String date =
                              _weeklyData[index]
                                          ['date']
                                      ?.toString() ??
                                  '';

                          return Padding(
                            padding:
                                const EdgeInsets
                                    .only(
                              top: 8,
                            ),
                            child: Text(
                              _formatDate(
                                date,
                              ),
                              style:
                                  const TextStyle(
                                fontSize: 10,
                              ),
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
                      barWidth: 4,
                      dotData:
                          const FlDotData(
                        show: true,
                      ),
                      belowBarData:
                          BarAreaData(
                        show: true,
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

  Widget _buildWeeklySummary() {
    if (_weeklyData.isEmpty) {
      return const SizedBox();
    }

    String message;

    if (_averageScreenTime <= 120) {
      message =
          'Your average screen time is relatively low. Continue maintaining balanced digital habits.';
    } else if (_averageScreenTime <= 240) {
      message =
          'Your average screen time is moderate. Regular breaks can help maintain better digital wellbeing.';
    } else if (_averageScreenTime <= 360) {
      message =
          'Your average screen time is getting high. Consider reducing unnecessary app usage.';
    } else {
      message =
          'Your average screen time is high. Focus on reducing prolonged and unnecessary phone usage.';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.insights,
              size: 30,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weekly Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
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
        title: const Text(
          'Weekly Analytics',
        ),
        actions: [
          IconButton(
            onPressed: _loadWeeklyData,
            icon: const Icon(
              Icons.refresh,
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadWeeklyData,
              child: ListView(
                padding:
                    const EdgeInsets.all(16),
                children: [
                  _buildSummaryCard(
                    icon: Icons.av_timer,
                    title:
                        'Average Screen Time',
                    value: _formatMinutes(
                      _averageScreenTime,
                    ),
                    subtitle:
                        'Based on available days',
                  ),

                  _buildSummaryCard(
                    icon:
                        Icons.trending_up,
                    title:
                        'Highest Screen Time',
                    value: _formatMinutes(
                      _highestScreenTime,
                    ),
                    subtitle:
                        _highestScreenTimeDate,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  _buildScreenTimeChart(),

                  const SizedBox(
                    height: 12,
                  ),

                  _buildRiskTrend(),

                  const SizedBox(
                    height: 12,
                  ),

                  _buildWeeklySummary(),

                  const SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
    );
  }
}