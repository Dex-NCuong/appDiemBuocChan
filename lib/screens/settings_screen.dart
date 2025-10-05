import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_settings.dart';
import '../services/step_service.dart';

class SettingsScreen extends StatefulWidget {
  final UserSettings userSettings;
  final Function(UserSettings) onSettingsChanged;

  const SettingsScreen({
    super.key,
    required this.userSettings,
    required this.onSettingsChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _dailyGoalController;
  late TextEditingController _stepLengthController;

  @override
  void initState() {
    super.initState();
    _heightController = TextEditingController(text: widget.userSettings.height.toString());
    _weightController = TextEditingController(text: widget.userSettings.weight.toString());
    _dailyGoalController = TextEditingController(text: widget.userSettings.dailyGoal.toString());
    _stepLengthController = TextEditingController(text: widget.userSettings.stepLength.toString());
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _dailyGoalController.dispose();
    _stepLengthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Cài đặt',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Personal Information Section
            _buildSectionCard(
              title: 'Thông tin cá nhân',
              icon: Icons.person,
              children: [
                _buildInputField(
                  controller: _heightController,
                  label: 'Chiều cao (cm)',
                  icon: Icons.height,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _weightController,
                  label: 'Cân nặng (kg)',
                  icon: Icons.monitor_weight,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Goals Section
            _buildSectionCard(
              title: 'Mục tiêu',
              icon: Icons.flag,
              children: [
                _buildInputField(
                  controller: _dailyGoalController,
                  label: 'Mục tiêu bước chân hàng ngày',
                  icon: Icons.directions_walk,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _stepLengthController,
                  label: 'Chiều dài bước chân (m)',
                  icon: Icons.straighten,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: const Color(0xFF2196F3), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFF2196F3),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Chiều dài bước chân trung bình = Chiều cao × 0.43',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Quick Actions Section
            _buildSectionCard(
              title: 'Hành động nhanh',
              icon: Icons.speed,
              children: [
                _buildActionButton(
                  title: 'Tính chiều dài bước chân tự động',
                  subtitle: 'Dựa trên chiều cao hiện tại',
                  icon: Icons.auto_fix_high,
                  onTap: _calculateStepLength,
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  title: 'Đặt mục tiêu mặc định',
                  subtitle: '10,000 bước/ngày',
                  icon: Icons.restore,
                  onTap: _setDefaultGoal,
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  title: 'Test cảm biến bước chân',
                  subtitle: 'Kiểm tra xem cảm biến có hoạt động không',
                  icon: Icons.sensors,
                  onTap: _testSensor,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Danger Zone Section
            _buildSectionCard(
              title: 'Vùng nguy hiểm',
              icon: Icons.warning,
              children: [
                _buildActionButton(
                  title: 'Reset bước chân hôm nay',
                  subtitle: 'Đặt lại số bước chân về 0 cho ngày hôm nay',
                  icon: Icons.refresh,
                  onTap: _resetTodaySteps,
                  isDanger: false,
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  title: 'Xóa tất cả dữ liệu',
                  subtitle: 'Reset lại toàn bộ dữ liệu bước chân',
                  icon: Icons.delete_forever,
                  onTap: _clearAllData,
                  isDanger: true,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Lưu cài đặt',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20.0),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF4CAF50),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF4CAF50)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isDanger ? Colors.red[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: isDanger ? Colors.red[200]! : Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: isDanger ? Colors.red.withOpacity(0.1) : const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(
                icon,
                color: isDanger ? Colors.red : const Color(0xFF4CAF50),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isDanger ? Colors.red : const Color(0xFF4CAF50),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _calculateStepLength() {
    final height = double.tryParse(_heightController.text);
    if (height != null && height > 0) {
      final stepLength = UserSettings.calculateStepLength(height);
      _stepLengthController.text = stepLength.toStringAsFixed(2);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã tính chiều dài bước chân: ${stepLength.toStringAsFixed(2)}m'),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập chiều cao hợp lệ'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _setDefaultGoal() {
    _dailyGoalController.text = '10000';
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã đặt mục tiêu mặc định: 10,000 bước'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
  }

  void _testSensor() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Đang test cảm biến...'),
            ],
          ),
        );
      },
    );

    try {
      final stepService = StepService();
      final isWorking = await stepService.testSensor();
      
      Navigator.of(context).pop(); // Close loading dialog
      
      if (isWorking) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cảm biến hoạt động bình thường!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Cảm biến không hoạt động. Đang sử dụng chế độ mô phỏng.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi test cảm biến: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _saveSettings() {
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    final dailyGoal = int.tryParse(_dailyGoalController.text);
    final stepLength = double.tryParse(_stepLengthController.text);

    if (height == null || height <= 0) {
      _showError('Vui lòng nhập chiều cao hợp lệ');
      return;
    }

    if (weight == null || weight <= 0) {
      _showError('Vui lòng nhập cân nặng hợp lệ');
      return;
    }

    if (dailyGoal == null || dailyGoal <= 0) {
      _showError('Vui lòng nhập mục tiêu bước chân hợp lệ');
      return;
    }

    if (stepLength == null || stepLength <= 0) {
      _showError('Vui lòng nhập chiều dài bước chân hợp lệ');
      return;
    }

    final newSettings = UserSettings(
      height: height,
      weight: weight,
      dailyGoal: dailyGoal,
      stepLength: stepLength,
    );

    StepService().saveUserSettings(newSettings);
    widget.onSettingsChanged(newSettings);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu cài đặt thành công!'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );

    Navigator.pop(context);
  }

  void _resetTodaySteps() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận reset bước chân'),
          content: const Text(
            'Bạn có chắc chắn muốn reset số bước chân hôm nay về 0?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await StepService().resetTodaySteps();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã reset bước chân hôm nay thành công!'),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
              },
              child: const Text(
                'Reset',
                style: TextStyle(color: Color(0xFF4CAF50)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _clearAllData() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa dữ liệu'),
          content: const Text(
            'Bạn có chắc chắn muốn xóa tất cả dữ liệu bước chân? Hành động này không thể hoàn tác.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await StepService().clearAllData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa tất cả dữ liệu thành công!'),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
                // Navigate back to home to refresh
                Navigator.of(context).pop();
              },
              child: const Text(
                'Xóa',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
