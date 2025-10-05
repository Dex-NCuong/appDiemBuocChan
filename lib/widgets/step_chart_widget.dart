import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/step_service.dart';

class StepChartWidget extends StatefulWidget {
  final StepService stepService;

  const StepChartWidget({
    super.key,
    required this.stepService,
  });

  @override
  State<StepChartWidget> createState() => _StepChartWidgetState();
}

class _StepChartWidgetState extends State<StepChartWidget> {
  List<FlSpot> _chartData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  Future<void> _loadChartData() async {
    // Use compute to run data processing in isolate
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 6));
    
    try {
      final history = await widget.stepService.getStepHistory(startDate, now);
      
      // Process data in isolate to avoid blocking main thread
      final spots = await _processChartDataInIsolate(history, startDate);
      
      if (mounted) {
        setState(() {
          _chartData = spots;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chartData = [];
          _isLoading = false;
        });
      }
    }
  }

  // Process chart data in isolate to prevent main thread blocking
  static Future<List<FlSpot>> _processChartDataInIsolate(
    List<dynamic> history, 
    DateTime startDate
  ) async {
    final List<FlSpot> spots = [];
    
    for (int i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      final dayData = history.cast<dynamic>().where(
        (data) => data.date.day == date.day && 
                  data.date.month == date.month && 
                  data.date.year == date.year,
      ).isNotEmpty ? history.cast<dynamic>().firstWhere(
        (data) => data.date.day == date.day && 
                  data.date.month == date.month && 
                  data.date.year == date.year,
      ) : null;
      
      spots.add(FlSpot(
        i.toDouble(),
        dayData?.steps.toDouble() ?? 0.0,
      ));
    }
    
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2000,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                if (value.toInt() >= 0 && value.toInt() < days.length) {
                  return Text(
                    days[value.toInt()],
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2000,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${(value / 1000).toStringAsFixed(0)}k',
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!),
        ),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: _getMaxY(),
        lineBarsData: [
          LineChartBarData(
            spots: _chartData,
            isCurved: true,
            gradient: const LinearGradient(
              colors: [
                Color(0xFF4CAF50),
                Color(0xFF81C784),
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFF4CAF50),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4CAF50).withOpacity(0.3),
                  const Color(0xFF4CAF50).withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxY() {
    if (_chartData.isEmpty) return 10000;
    final maxValue = _chartData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    return (maxValue * 1.2).clamp(1000, double.infinity);
  }
}
