import 'package:simdart/simdart.dart';
import 'package:simdart/src/internal/time_action.dart';
import 'package:simdart/src/simdart.dart';
import 'package:test/test.dart';

class TestAction extends TimeAction {
  TestAction({required super.start, required this.names, required this.name});

  final String name;
  final List<String> names;

  @override
  void execute() {
    names.add(name);
  }
}

void main() {
  group('TimeLoop', () {
    test('Loop', () async {
      SimDart sim = SimDart(
          includeTracks: true,
          executionPriority: 0,
          startTimeHandling: StartTimeHandling.throwErrorIfPast);

      List<String> names = [];

      SimDartHelper.addAction(
          sim: sim, action: TestAction(start: 0, name: 'A', names: names));
      SimDartHelper.addAction(
          sim: sim, action: TestAction(start: 1, name: 'B', names: names));
      SimDartHelper.addAction(
          sim: sim, action: TestAction(start: 10, name: 'C', names: names));
      SimDartHelper.addAction(
          sim: sim, action: TestAction(start: 5, name: 'D', names: names));
      SimDartHelper.addAction(
          sim: sim, action: TestAction(start: 2, name: 'E', names: names));
      SimDartHelper.addAction(
          sim: sim, action: TestAction(start: 9, name: 'F', names: names));

      await sim.run();

      expect(names, ['A', 'B', 'E', 'D', 'F', 'C']);
    });
  });
}
