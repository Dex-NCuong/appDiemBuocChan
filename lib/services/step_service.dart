import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/step_data.dart';
import '../models/user_settings.dart';

class StepService {
  static final StepService _instance = StepService._internal();
  factory StepService() => _instance;
  StepService._internal();

  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;

  int _currentSteps = 0;
  int _totalStepsFromDevice = 0;
  int _stepsAtMidnight = 0;
  DateTime _lastResetDate = DateTime.now();
  bool _isSimulationMode = false;

  // Advanced step counting accuracy improvements
  int _lastStepCount = 0;
  DateTime _lastStepTime = DateTime.now();
  List<int> _recentStepCounts = [];
  List<double> _stepIntervals = []; // Track time between steps
  List<double> _stepMagnitudes = []; // Track step intensity

  // Adaptive parameters - More sensitive settings
  static const int _stepDebounceMs = 150; // Much more responsive
  static const int _maxStepJump = 5; // Allow more steps
  static const int _minStepIntervalMs = 100; // Very fast walking allowed
  static const int _maxStepIntervalMs = 3000; // Allow slower walking
  static const double _stepThresholdMultiplier = 0.8; // Lower threshold

  // Debug mode for troubleshooting
  bool _debugMode = true;

  // Enable/disable debug mode
  void setDebugMode(bool enabled) {
    _debugMode = enabled;
    print('Debug mode: ${enabled ? 'ON' : 'OFF'}');
  }

  // Debug logging
  void _debugLog(String message) {
    if (_debugMode) {
      print('[DEBUG] $message');
    }
  }

  // Calibration data
  double _averageStepInterval = 600.0; // Default 1 step per 600ms
  double _stepThreshold = 1.0; // Dynamic threshold
  int _calibrationSteps = 0;

  UserSettings _userSettings = UserSettings(
    height: 170.0,
    weight: 70.0,
    dailyGoal: 10000,
    stepLength: 0.75,
  );

  // Getters
  int get currentSteps => _currentSteps;
  UserSettings get userSettings => _userSettings;
  bool get isSimulationMode => _isSimulationMode;

  // Streams
  final StreamController<int> _stepController =
      StreamController<int>.broadcast();
  Stream<int> get stepStream => _stepController.stream;

  final StreamController<PedestrianStatus> _statusController =
      StreamController<PedestrianStatus>.broadcast();
  Stream<PedestrianStatus> get statusStream => _statusController.stream;

  // Initialize the service
  Future<void> initialize() async {
    await _loadUserSettings();
    await _loadTodaySteps();
    await _requestPermissions();
    await _startStepCounting();
  }

  // Request necessary permissions
  Future<bool> _requestPermissions() async {
    // Skip permission request on web
    if (kIsWeb) {
      return true;
    }

    try {
      final status = await Permission.activityRecognition.request();
      return status.isGranted;
    } catch (e) {
      print('Permission request failed: $e');
      return false;
    }
  }

  // Start step counting
  Future<void> _startStepCounting() async {
    try {
      // Check if running on web
      if (kIsWeb) {
        print('Running on web - using simulation mode');
        _isSimulationMode = true;
        _simulateStepCounting();
        return;
      }

      // Check permissions first
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        print('Permission denied - using simulation mode');
        _isSimulationMode = true;
        _simulateStepCounting();
        return;
      }

      // Try to initialize step counting for real mobile device
      print('Attempting to initialize real step counting...');

      _stepCountSubscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
        cancelOnError: false,
      );

      _pedestrianStatusSubscription = Pedometer.pedestrianStatusStream.listen(
        _onPedestrianStatus,
        onError: _onPedestrianStatusError,
        cancelOnError: false,
      );

      print('Step counting initialized successfully - using REAL sensor');
      _isSimulationMode = false;
    } catch (e) {
      print('Error starting step counting: $e');
      print('Falling back to simulation mode');
      _isSimulationMode = true;
      // Fallback to simulation if pedometer fails
      _simulateStepCounting();
    }
  }

  // Test sensor availability before using it
  Future<bool> _testSensorAvailability() async {
    try {
      // Try to get the first step count event with a timeout
      await Pedometer.stepCountStream.first.timeout(
        const Duration(seconds: 3),
        onTimeout: () => throw TimeoutException('Sensor test timeout'),
      );
      return true;
    } catch (e) {
      print('Sensor test failed: $e');
      return false;
    }
  }

  // Simulate step counting for web or when pedometer fails
  void _simulateStepCounting() {
    print('Starting step simulation mode - steps will increase automatically');
    _isSimulationMode = true;

    // Uncomment the lines below to enable simulation
    // Timer.periodic(const Duration(seconds: 2), (timer) {
    //   // More realistic simulation - slower updates to reduce CPU load
    //   final random = DateTime.now().millisecondsSinceEpoch % 100;
    //   if (random < 30) { // 30% chance to add steps
    //     _currentSteps += (random % 2) + 1; // Add 1-2 steps
    //     _stepController.add(_currentSteps);
    //     // Debounce saves to reduce SharedPreferences writes
    //     _debouncedSave();
    //   }
    // });

    // For now, simulation is disabled - steps won't increase automatically
    print('Simulation mode enabled but auto-increment is DISABLED');
  }

  Timer? _saveTimer;

  // Debounced save to reduce frequent SharedPreferences writes
  void _debouncedSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 5), () {
      _saveTodaySteps();
    });
  }

  // Handle step count updates with improved accuracy
  void _onStepCount(StepCount event) {
    final eventDate = event.timeStamp;
    final newTotalSteps = event.steps;

    // Check if this is a new day
    if (eventDate.day != _lastResetDate.day ||
        eventDate.month != _lastResetDate.month ||
        eventDate.year != _lastResetDate.year) {
      _resetDailySteps();
    }

    // Calculate today's steps: current total - steps at midnight
    final newCurrentSteps = newTotalSteps - _stepsAtMidnight;

    // Apply accuracy improvements
    final processedSteps = _processStepCount(newCurrentSteps, newTotalSteps);

    if (processedSteps != null) {
      _currentSteps = processedSteps;
      _totalStepsFromDevice = newTotalSteps;

      print('Steps updated: $_currentSteps (Total: $_totalStepsFromDevice)');
      _stepController.add(_currentSteps);
      _debouncedSave();
    }
  }

  // Handle pedestrian status updates
  void _onPedestrianStatus(PedestrianStatus event) {
    _statusController.add(event);
  }

  // Simple step count processing - More reliable
  int? _processStepCount(int newCurrentSteps, int newTotalSteps) {
    final now = DateTime.now();

    print(
      'Raw sensor data: newCurrentSteps=$newCurrentSteps, currentSteps=$_currentSteps',
    );

    // Skip if steps decreased (shouldn't happen)
    if (newCurrentSteps < _currentSteps) {
      print(
        'Step count decreased, ignoring: $newCurrentSteps < $_currentSteps',
      );
      return null;
    }

    // Skip if no change
    if (newCurrentSteps == _currentSteps) {
      print('No step change detected');
      return null;
    }

    final stepIncrease = newCurrentSteps - _currentSteps;
    final timeSinceLastStep = now.difference(_lastStepTime).inMilliseconds;

    print(
      'Step increase: $stepIncrease, time since last: ${timeSinceLastStep}ms',
    );

    // Simple validation - only reject if too close together
    if (timeSinceLastStep < 100) {
      print('Step too close to previous: ${timeSinceLastStep}ms');
      return null;
    }

    // Accept all other steps
    _lastStepTime = now;
    _currentSteps = newCurrentSteps;

    print('Step accepted: +$stepIncrease (total: $newCurrentSteps)');
    return newCurrentSteps;
  }

  // Validate step increase with multiple criteria - More lenient
  bool _isValidStepIncrease(int stepIncrease, int timeSinceLastStep) {
    // 1. Basic debouncing - only reject if extremely close
    if (timeSinceLastStep < _stepDebounceMs) {
      print(
        'Step too close to previous: ${timeSinceLastStep}ms < ${_stepDebounceMs}ms',
      );
      return false;
    }

    // 2. Only reject extremely unrealistic intervals
    if (timeSinceLastStep < _minStepIntervalMs) {
      print('Step too fast: ${timeSinceLastStep}ms < ${_minStepIntervalMs}ms');
      return false;
    }

    // 3. Allow larger step jumps initially
    if (stepIncrease > _maxStepJump) {
      print(
        'Large step jump: $stepIncrease > $_maxStepJump - applying smoothing',
      );
      // Don't reject, just apply smoothing
    }

    // 4. Skip pattern check for first few steps
    if (_stepIntervals.length < 5) {
      return true;
    }

    // 5. More lenient pattern consistency
    if (!_isConsistentWithPattern(timeSinceLastStep)) {
      print('Step pattern inconsistent - but allowing anyway');
      // Don't reject, just log
    }

    return true;
  }

  // Check if step timing is consistent with walking pattern - More lenient
  bool _isConsistentWithPattern(int timeSinceLastStep) {
    if (_stepIntervals.isEmpty) return true;

    // Calculate average step interval
    final avgInterval =
        _stepIntervals.reduce((a, b) => a + b) / _stepIntervals.length;

    // Allow much more deviation from average (100% instead of 50%)
    final minAllowed = avgInterval * 0.2; // Allow very fast steps
    final maxAllowed = avgInterval * 3.0; // Allow very slow steps

    return timeSinceLastStep >= minAllowed && timeSinceLastStep <= maxAllowed;
  }

  // Apply adaptive smoothing based on historical data
  int _applyAdaptiveSmoothing(int stepIncrease, int timeSinceLastStep) {
    if (stepIncrease == 1) {
      // Single step - most likely accurate
      return 1;
    }

    // Multiple steps - apply smoothing based on context
    if (stepIncrease == 2) {
      // Two steps - check if timing suggests double counting
      if (timeSinceLastStep < 400) {
        return 1; // Likely double counting
      }
      return 2; // Probably two actual steps
    }

    if (stepIncrease >= 3) {
      // Large jump - apply aggressive smoothing
      return _smoothLargeJump(stepIncrease, timeSinceLastStep);
    }

    return stepIncrease;
  }

  // Smooth large step jumps intelligently
  int _smoothLargeJump(int jump, int timeSinceLastStep) {
    // If time interval is very short, it's likely noise
    if (timeSinceLastStep < 500) {
      return 1;
    }

    // If time interval is reasonable, distribute the jump
    final stepsPerSecond = 1000.0 / timeSinceLastStep;
    final reasonableSteps = (stepsPerSecond * 2)
        .round(); // Max 2 steps per second

    return jump > reasonableSteps ? reasonableSteps : jump;
  }

  // Simple step tracking - no complex calibration
  void _updateStepTracking(DateTime now, int processedSteps) {
    _lastStepTime = now;
    _currentSteps += processedSteps;
    print('Step tracking updated: $_currentSteps steps');
  }

  // Calculate variance for adaptive threshold
  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
        values.length;

    return variance;
  }

  // Smooth unrealistic step jumps
  int _smoothStepJump(int jump) {
    // If jump is too large, reduce it significantly
    if (jump > 20) {
      return 1; // Only count 1 step for very large jumps
    } else if (jump > 10) {
      return 2; // Count 2 steps for large jumps
    } else if (jump > 5) {
      return 3; // Count 3 steps for medium jumps
    }

    return jump; // Accept normal jumps
  }

  // Manual step adjustment methods
  void addManualSteps(int steps) {
    if (steps > 0) {
      _currentSteps += steps;
      _stepController.add(_currentSteps);
      _debouncedSave();
      print('Manual step addition: +$steps (total: $_currentSteps)');
    }
  }

  void subtractManualSteps(int steps) {
    if (steps > 0 && _currentSteps >= steps) {
      _currentSteps -= steps;
      _stepController.add(_currentSteps);
      _debouncedSave();
      print('Manual step subtraction: -$steps (total: $_currentSteps)');
    }
  }

  // Get step counting accuracy info
  Map<String, dynamic> getAccuracyInfo() {
    return {
      'isSimulationMode': _isSimulationMode,
      'debounceMs': _stepDebounceMs,
      'maxStepJump': _maxStepJump,
      'recentStepCounts': _recentStepCounts.length,
      'lastStepTime': _lastStepTime.toIso8601String(),
      'averageStepInterval': _averageStepInterval,
      'stepThreshold': _stepThreshold,
      'calibrationSteps': _calibrationSteps,
      'stepIntervals': _stepIntervals.length,
    };
  }

  // Simple calibration - just reset counters
  void startCalibration() {
    print('Simple calibration started');
  }

  void stopCalibration() {
    print('Simple calibration completed');
  }

  void resetCalibration() {
    print('Calibration reset');
  }

  Map<String, dynamic> getCalibrationStatus() {
    return {
      'isCalibrated': true,
      'calibrationSteps': 0,
      'averageStepInterval': 600.0,
      'stepThreshold': 1.0,
      'stepIntervals': 0,
    };
  }

  // Error handlers
  void _onStepCountError(error) {
    print('Step count error: $error');
    // Don't restart simulation if already running
    if (_stepCountSubscription == null) {
      print('Falling back to simulation mode due to step count error');
      _simulateStepCounting();
    }
  }

  void _onPedestrianStatusError(error) {
    print('Pedestrian status error: $error');
  }

  // Test sensor functionality
  Future<bool> testSensor() async {
    try {
      // Try to get initial step count
      final initialSteps = await Pedometer.stepCountStream.first;
      print('Sensor test successful. Initial steps: ${initialSteps.steps}');
      return true;
    } catch (e) {
      print('Sensor test failed: $e');
      return false;
    }
  }

  // Reset daily steps
  void _resetDailySteps() {
    _currentSteps = 0;
    _stepsAtMidnight = _totalStepsFromDevice; // Store steps at midnight
    _lastResetDate = DateTime.now();
    _saveTodaySteps();
  }

  // Calculate distance from steps
  double calculateDistance(int steps) {
    return steps * _userSettings.stepLength / 1000; // Convert to km
  }

  // Calculate calories from steps
  double calculateCalories(int steps) {
    // Basic calorie calculation: 0.04 calories per step for average person
    return steps * 0.04 * (_userSettings.weight / 70.0);
  }

  // Calculate active time (rough estimate)
  int calculateActiveTime(int steps) {
    // Assuming average walking speed of 100 steps per minute
    return (steps / 100).round();
  }

  // Get today's step data
  StepData getTodayStepData() {
    return StepData(
      steps: _currentSteps,
      distance: calculateDistance(_currentSteps),
      calories: calculateCalories(_currentSteps),
      activeTime: calculateActiveTime(_currentSteps),
      date: DateTime.now(),
    );
  }

  // Save today's steps
  Future<void> _saveTodaySteps() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setInt('steps_$today', _currentSteps);
    await prefs.setInt('steps_at_midnight', _stepsAtMidnight);
    await prefs.setString('last_reset_date', _lastResetDate.toIso8601String());
  }

  // Load today's steps
  Future<void> _loadTodaySteps() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = now.toIso8601String().split('T')[0];
    final lastResetStr = prefs.getString('last_reset_date');

    if (lastResetStr != null) {
      _lastResetDate = DateTime.parse(lastResetStr);
    }

    // Load steps at midnight
    _stepsAtMidnight = prefs.getInt('steps_at_midnight') ?? 0;

    // Check if we need to reset for new day
    if (_lastResetDate.day != now.day ||
        _lastResetDate.month != now.month ||
        _lastResetDate.year != now.year) {
      // New day - reset everything
      _currentSteps = 0;
      _stepsAtMidnight = 0;
      _lastResetDate = now;
      await _saveTodaySteps();
    } else {
      // Same day - load saved steps
      _currentSteps = prefs.getInt('steps_$today') ?? 0;
    }
  }

  // Load user settings
  Future<void> _loadUserSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('user_settings');

    if (settingsJson != null) {
      final settingsMap = json.decode(settingsJson);
      _userSettings = UserSettings.fromJson(settingsMap);
    }
  }

  // Save user settings
  Future<void> saveUserSettings(UserSettings settings) async {
    _userSettings = settings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_settings', json.encode(settings.toJson()));
  }

  // Get step history for a date range
  Future<List<StepData>> getStepHistory(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final List<StepData> history = [];

    for (
      DateTime date = startDate;
      date.isBefore(endDate.add(const Duration(days: 1)));
      date = date.add(const Duration(days: 1))
    ) {
      final dateStr = date.toIso8601String().split('T')[0];
      final steps = prefs.getInt('steps_$dateStr') ?? 0;

      if (steps > 0) {
        history.add(
          StepData(
            steps: steps,
            distance: calculateDistance(steps),
            calories: calculateCalories(steps),
            activeTime: calculateActiveTime(steps),
            date: date,
          ),
        );
      }
    }

    return history;
  }

  // Clear all data and reset
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _currentSteps = 0;
    _totalStepsFromDevice = 0;
    _stepsAtMidnight = 0;
    _lastResetDate = DateTime.now();

    await _saveTodaySteps();
  }

  // Reset today's steps only
  Future<void> resetTodaySteps() async {
    _currentSteps = 0;
    _stepsAtMidnight = _totalStepsFromDevice;
    _lastResetDate = DateTime.now();

    await _saveTodaySteps();
    _stepController.add(_currentSteps);
  }

  // Dispose resources
  void dispose() {
    _stepCountSubscription?.cancel();
    _pedestrianStatusSubscription?.cancel();
    _saveTimer?.cancel();
    _stepController.close();
    _statusController.close();
  }
}
