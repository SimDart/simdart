import 'package:simdart/simdart.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

Future<void> emptyEvent(SimContext context) async {}

void main() {
  late SimDart sim;
  TestHelper helper = TestHelper();

  setUp(() {
    // priority to allow test timeout
    sim = SimDart(executionPriority: 5, listener: helper);
  });

  group('Process', () {
    test('start 1', () async {
      sim.process(event: emptyEvent, name: 'a');
      await sim.run();
      helper.testEvents(['[0][a][called]', '[0][a][finished]']);
    });
    test('start 2', () async {
      sim.process(event: emptyEvent, start: 10, name: 'a');
      await sim.run();
      helper.testEvents(['[10][a][called]', '[10][a][finished]']);
    });
    test('delay 1', () async {
      sim.process(event: emptyEvent, delay: 0, name: 'a');
      await sim.run();
      helper.testEvents(['[0][a][called]', '[0][a][finished]']);
    });
    test('delay 2', () async {
      sim.process(event: emptyEvent, delay: 10, name: 'a');
      await sim.run();
      helper.testEvents(['[10][a][called]', '[10][a][finished]']);
    });
    test('delay 3', () async {
      sim.process(
          event: (context) async {
            context.process(event: emptyEvent, delay: 10, name: 'b');
          },
          start: 5,
          name: 'a');
      await sim.run();
      helper.testEvents([
        '[5][a][called]',
        '[5][a][finished]',
        '[15][b][called]',
        '[15][b][finished]'
      ]);
    });
    test('delay 4', () async {
      sim.process(
          event: (context) async {
            context.process(event: emptyEvent, delay: 10, name: 'b');
          },
          start: 0,
          name: 'a');
      sim.process(
          event: (context) async {
            context.process(event: emptyEvent, delay: 2, name: 'd');
          },
          start: 2,
          name: 'c');
      await sim.run();
      helper.testEvents([
        '[0][a][called]',
        '[0][a][finished]',
        '[2][c][called]',
        '[2][c][finished]',
        '[4][d][called]',
        '[4][d][finished]',
        '[10][b][called]',
        '[10][b][finished]'
      ]);
    });
  });
}
