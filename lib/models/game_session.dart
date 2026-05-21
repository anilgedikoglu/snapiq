import 'test_result.dart';

class GameSession {
  TestResult? result;
  int currentTestIndex = 0;

  bool get isComplete => result != null;

  static const int totalTests = 29;
}
