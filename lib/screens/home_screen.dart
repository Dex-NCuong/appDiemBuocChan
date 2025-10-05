import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../services/step_service.dart';
import '../models/user_settings.dart';
import '../widgets/progress_ring_widget.dart';
import '../widgets/stats_card_widget.dart';
import '../widgets/step_chart_widget.dart';
import 'settings_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final StepService _stepService = StepService();
  int _currentSteps = 0;
  UserSettings _userSettings = UserSettings(
    height: 170.0,
    weight: 70.0,
    dailyGoal: 10000,
    stepLength: 0.75,
  );
  bool _isLoading = true;
  StreamSubscription<int>? _stepSubscription;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await _stepService.initialize();
      if (mounted) {
        setState(() {
          _currentSteps = _stepService.currentSteps;
          _userSettings = _stepService.userSettings;
          _isLoading = false;
        });
      }

      // Listen to step updates with debouncing to reduce UI updates
      _stepSubscription = _stepService.stepStream.listen((steps) {
        if (mounted && _currentSteps != steps) {
          _debounceTimer?.cancel();
          _debounceTimer = Timer(const Duration(milliseconds: 100), () {
            if (mounted) {
              setState(() {
                _currentSteps = steps;
              });
            }
          });
        }
      });
    } catch (e) {
      print('Error initializing app: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _stepSubscription?.cancel();
    _debounceTimer?.cancel();
    _stepService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final stepData = _stepService.getTodayStepData();
    final progress = (_currentSteps / _userSettings.dailyGoal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Bước Chân Hôm Nay',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => _navigateToSettings(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date and current steps
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.0),
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
                    _getFormattedDate(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$_currentSteps',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'bước',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Progress ring
            Center(
              child: ProgressRingWidget(
                progress: progress,
                dailyGoal: _userSettings.dailyGoal,
                currentSteps: _currentSteps,
              ),
            ),

            const SizedBox(height: 24),

            // Stats cards
            Row(
              children: [
                Expanded(
                  child: StatsCardWidget(
                    title: 'Quãng đường',
                    value: '${stepData.distance.toStringAsFixed(1)} km',
                    icon: Icons.directions_walk,
                    color: const Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatsCardWidget(
                    title: 'Calo',
                    value: '${stepData.calories.toStringAsFixed(0)} kcal',
                    icon: Icons.local_fire_department,
                    color: const Color(0xFFFF9800),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: StatsCardWidget(
                    title: 'Thời gian',
                    value: '${stepData.activeTime} phút',
                    icon: Icons.timer,
                    color: const Color(0xFF9C27B0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatsCardWidget(
                    title: 'Mục tiêu',
                    value: '${_userSettings.dailyGoal} bước',
                    icon: Icons.flag,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Chart section
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Biểu đồ 7 ngày qua',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: StepChartWidget(stepService: _stepService),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // History button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToHistory(),
                icon: const Icon(Icons.history, color: Colors.white),
                label: const Text(
                  'Xem lịch sử',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 2,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Motivation message
            if (progress < 1.0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: const Color(0xFF2196F3), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: Color(0xFF2196F3),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bạn còn ${_userSettings.dailyGoal - _currentSteps} bước nữa để đạt mục tiêu hôm nay!',
                        style: const TextStyle(
                          color: Color(0xFF1976D2),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E8),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: const Color(0xFF4CAF50), width: 1),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.celebration, color: Color(0xFF4CAF50), size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Chúc mừng! Bạn đã hoàn thành mục tiêu hôm nay! 🎉',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Step accuracy notice and controls
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: const Color(0xFF2196F3), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.tune,
                        color: Color(0xFF2196F3),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Điều chỉnh độ chính xác',
                          style: TextStyle(
                            color: Color(0xFF1976D2),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Nếu số bước không chính xác, bạn có thể điều chỉnh thủ công:',
                    style: TextStyle(color: Color(0xFF1976D2), fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showManualAdjustDialog(),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Điều chỉnh'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showAccuracyInfo(),
                          icon: const Icon(Icons.info, size: 18),
                          label: const Text('Thông tin'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showCalibrationDialog(),
                          icon: const Icon(Icons.tune, size: 18),
                          label: const Text('Hiệu chỉnh'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF9800),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _toggleDebugMode(),
                          icon: const Icon(Icons.bug_report, size: 18),
                          label: const Text('Debug'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9C27B0),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _resetStepCount(),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Reset'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF44336),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _testSensor(),
                          icon: const Icon(Icons.sensors, size: 18),
                          label: const Text('Test'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF607D8B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Simulation mode notice
            if (_stepService.isSimulationMode)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 16.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: const Color(0xFFFF9800), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFFFF9800),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        kIsWeb
                            ? 'Đang chạy trên web - Dữ liệu bước chân được mô phỏng. Để sử dụng thực tế, hãy chạy trên thiết bị di động.'
                            : 'Đang chạy ở chế độ mô phỏng - Số bước sẽ tự động tăng. Để sử dụng sensor thật, hãy chạy trên thiết bị di động thật và cấp quyền.',
                        style: const TextStyle(
                          color: Color(0xFFE65100),
                          fontWeight: FontWeight.w500,
                        ),
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

  String _getFormattedDate() {
    final now = DateTime.now();
    final weekdays = [
      'Chủ nhật',
      'Thứ hai',
      'Thứ ba',
      'Thứ tư',
      'Thứ năm',
      'Thứ sáu',
      'Thứ bảy',
    ];
    final months = [
      'Tháng 1',
      'Tháng 2',
      'Tháng 3',
      'Tháng 4',
      'Tháng 5',
      'Tháng 6',
      'Tháng 7',
      'Tháng 8',
      'Tháng 9',
      'Tháng 10',
      'Tháng 11',
      'Tháng 12',
    ];

    return '${weekdays[now.weekday % 7]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          userSettings: _userSettings,
          onSettingsChanged: (newSettings) {
            setState(() {
              _userSettings = newSettings;
            });
          },
        ),
      ),
    );
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HistoryScreen()),
    );
  }

  bool _isRunningOnEmulator() {
    // Simple emulator detection - you can enhance this
    // For now, we'll use a simple check
    return false; // Let the step service handle the detection
  }

  void _showManualAdjustDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int adjustValue = 0;
        return AlertDialog(
          title: const Text('Điều chỉnh số bước'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Số bước hiện tại: $_currentSteps'),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số bước điều chỉnh',
                  hintText: 'Nhập số dương để cộng, số âm để trừ',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  adjustValue = int.tryParse(value) ?? 0;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (adjustValue > 0) {
                  _stepService.addManualSteps(adjustValue);
                } else if (adjustValue < 0) {
                  _stepService.subtractManualSteps(-adjustValue);
                }
                Navigator.of(context).pop();
                setState(() {
                  _currentSteps = _stepService.currentSteps;
                });
              },
              child: const Text('Áp dụng'),
            ),
          ],
        );
      },
    );
  }

  void _showAccuracyInfo() {
    final accuracyInfo = _stepService.getAccuracyInfo();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Thông tin độ chính xác'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chế độ: ${accuracyInfo['isSimulationMode'] ? 'Mô phỏng' : 'Sensor thật'}',
              ),
              Text('Debounce: ${accuracyInfo['debounceMs']}ms'),
              Text('Bước nhảy tối đa: ${accuracyInfo['maxStepJump']}'),
              Text(
                'Khoảng cách bước TB: ${accuracyInfo['averageStepInterval']?.toStringAsFixed(1) ?? 'N/A'}ms',
              ),
              Text(
                'Ngưỡng: ${accuracyInfo['stepThreshold']?.toStringAsFixed(2) ?? 'N/A'}',
              ),
              Text('Bước hiệu chỉnh: ${accuracyInfo['calibrationSteps'] ?? 0}'),
              const SizedBox(height: 16),
              const Text(
                'Cải tiến độ chính xác:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• Adaptive Filtering: Lọc thích ứng'),
              const Text('• Pattern Recognition: Nhận dạng mẫu đi bộ'),
              const Text('• Calibration: Hiệu chỉnh cá nhân'),
              const Text('• Smart Smoothing: Làm mịn thông minh'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  void _showCalibrationDialog() {
    final calibrationStatus = _stepService.getCalibrationStatus();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hiệu chỉnh cảm biến'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trạng thái: ${calibrationStatus['isCalibrated'] ? 'Đã hiệu chỉnh' : 'Chưa hiệu chỉnh'}',
              ),
              Text('Bước hiệu chỉnh: ${calibrationStatus['calibrationSteps']}'),
              Text(
                'Khoảng cách TB: ${calibrationStatus['averageStepInterval']?.toStringAsFixed(1) ?? 'N/A'}ms',
              ),
              Text(
                'Ngưỡng: ${calibrationStatus['stepThreshold']?.toStringAsFixed(2) ?? 'N/A'}',
              ),
              const SizedBox(height: 16),
              const Text(
                'Hướng dẫn hiệu chỉnh:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('1. Nhấn "Bắt đầu"'),
              const Text('2. Đi bộ bình thường 20 bước'),
              const Text('3. Nhấn "Kết thúc"'),
              const Text('4. Ứng dụng sẽ học mẫu đi bộ của bạn'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                _stepService.startCalibration();
                Navigator.of(context).pop();
                _showCalibrationProgressDialog();
              },
              child: const Text('Bắt đầu'),
            ),
          ],
        );
      },
    );
  }

  void _showCalibrationProgressDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Đang hiệu chỉnh...'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Hãy đi bộ bình thường 20 bước'),
              const Text('Ứng dụng đang học mẫu đi bộ của bạn'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                _stepService.stopCalibration();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hiệu chỉnh hoàn thành!')),
                );
              },
              child: const Text('Kết thúc'),
            ),
          ],
        );
      },
    );
  }

  void _resetStepCount() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset số bước'),
          content: const Text('Bạn có chắc muốn reset số bước về 0?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                _stepService.resetTodaySteps();
                setState(() {
                  _currentSteps = _stepService.currentSteps;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã reset số bước')),
                );
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  void _toggleDebugMode() {
    // This would need to be implemented in StepService
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Debug mode toggled - check console logs')),
    );
  }

  void _testSensor() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Test cảm biến'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Để test cảm biến:'),
              const SizedBox(height: 8),
              const Text('1. Đi vài bước'),
              const Text('2. Kiểm tra console logs'),
              const Text('3. Xem số bước có tăng không'),
              const SizedBox(height: 16),
              const Text(
                'Nếu không tăng, có thể:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• Cảm biến bị lỗi'),
              const Text('• Permission chưa được cấp'),
              const Text('• Thuật toán quá nghiêm ngặt'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }
}
