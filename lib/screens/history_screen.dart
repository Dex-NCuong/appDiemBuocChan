import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/step_service.dart';
import '../models/step_data.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final StepService _stepService = StepService();
  List<StepData> _historyData = [];
  bool _isLoading = true;
  String _selectedPeriod = 'week'; // week, month, year

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  Future<void> _loadHistoryData() async {
    setState(() {
      _isLoading = true;
    });

    final now = DateTime.now();
    DateTime startDate;
    
    switch (_selectedPeriod) {
      case 'week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case 'year':
        startDate = now.subtract(const Duration(days: 365));
        break;
      default:
        startDate = now.subtract(const Duration(days: 7));
    }

    final history = await _stepService.getStepHistory(startDate, now);
    
    setState(() {
      _historyData = history.reversed.toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Lịch sử bước chân',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
              _loadHistoryData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'week',
                child: Text('7 ngày qua'),
              ),
              const PopupMenuItem(
                value: 'month',
                child: Text('30 ngày qua'),
              ),
              const PopupMenuItem(
                value: 'year',
                child: Text('1 năm qua'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _historyData.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildStatsSummary(),
                    Expanded(
                      child: _buildHistoryList(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có dữ liệu lịch sử',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy bắt đầu đi bộ để tạo dữ liệu!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary() {
    if (_historyData.isEmpty) return const SizedBox.shrink();

    final totalSteps = _historyData.fold(0, (sum, data) => sum + data.steps);
    final totalDistance = _historyData.fold(0.0, (sum, data) => sum + data.distance);
    final totalCalories = _historyData.fold(0.0, (sum, data) => sum + data.calories);
    final avgSteps = totalSteps / _historyData.length;

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _getPeriodTitle(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'Tổng bước',
                '${NumberFormat('#,###').format(totalSteps)}',
                Icons.directions_walk,
              ),
              _buildSummaryItem(
                'Quãng đường',
                '${totalDistance.toStringAsFixed(1)} km',
                Icons.straighten,
              ),
              _buildSummaryItem(
                'Calo',
                '${totalCalories.toStringAsFixed(0)}',
                Icons.local_fire_department,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Trung bình: ${NumberFormat('#,###').format(avgSteps.round())} bước/ngày',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: _historyData.length,
      itemBuilder: (context, index) {
        final data = _historyData[index];
        return _buildHistoryItem(data);
      },
    );
  }

  Widget _buildHistoryItem(StepData data) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final weekdayFormat = DateFormat('EEEE', 'vi');
    final isToday = data.date.day == DateTime.now().day &&
                   data.date.month == DateTime.now().month &&
                   data.date.year == DateTime.now().year;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: isToday
            ? Border.all(color: const Color(0xFF4CAF50), width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Date section
          Container(
            width: 60,
            child: Column(
              children: [
                Text(
                  data.date.day.toString(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isToday ? const Color(0xFF4CAF50) : const Color(0xFF333333),
                  ),
                ),
                Text(
                  weekdayFormat.format(data.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: isToday ? const Color(0xFF4CAF50) : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isToday)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Hôm nay',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Steps info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.directions_walk,
                      color: const Color(0xFF4CAF50),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${NumberFormat('#,###').format(data.steps)} bước',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.straighten,
                      '${data.distance.toStringAsFixed(1)} km',
                      const Color(0xFF2196F3),
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      Icons.local_fire_department,
                      '${data.calories.toStringAsFixed(0)} cal',
                      const Color(0xFFFF9800),
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      Icons.timer,
                      '${data.activeTime} phút',
                      const Color(0xFF9C27B0),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getPeriodTitle() {
    switch (_selectedPeriod) {
      case 'week':
        return '7 ngày qua';
      case 'month':
        return '30 ngày qua';
      case 'year':
        return '1 năm qua';
      default:
        return '7 ngày qua';
    }
  }
}
