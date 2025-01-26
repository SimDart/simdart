import 'package:simdart/simdart.dart';
import 'package:simdart/src/internal/time_action.dart';
import 'package:simdart/src/internal/time_loop.dart';
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
      TimeLoop loop = TimeLoop(
          includeTracks: true,
          now: null,
          executionPriorityCounter: 0,
          beforeRun: () {},
          startTimeHandling: StartTimeHandling.throwErrorIfPast);

      List<String> names = [];

      loop.addAction(TestAction(start: 0, name: 'A', names: names));
      loop.addAction(TestAction(start: 1, name: 'B', names: names));
      loop.addAction(TestAction(start: 10, name: 'C', names: names));
      loop.addAction(TestAction(start: 5, name: 'D', names: names));
      loop.addAction(TestAction(start: 2, name: 'E', names: names));
      loop.addAction(TestAction(start: 9, name: 'F', names: names));

      await loop.run();

      expect(names, ['A', 'B', 'E', 'D', 'F', 'C']);
    });
  });
}
