import 'package:simdart/src/simdart.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

void main() {
  late SimDart sim;
  TestHelper helper = TestHelper();

  setUp(() {
    sim = SimDart(listener: helper);
    SimDartHelper.setDebugListener(sim: sim, listener: helper);
  });

  group('Stop', () {
    test('Simple', () async {
      sim.process(
          event: (context) async {
            print('vai chamr stop');
            context.stop();
          },
          name: 'a');
      sim.process(event: (context) async {}, name: 'b');

      await sim.run();
      helper.testEvents(['[0][a][called]', '[0][a][finished]']);
      helper.testTracks([
        'scheduleNextAction',
        'nextAction',
        'executeAction',
        'scheduleNextAction',
        'nextAction',
        'executeAction',
        'stop',
        'scheduleNextAction',
        'nextAction'
      ]);
      expect(helper.completerCount, 0);
    });

    test('Wait', () async {
      sim.process(
          event: (context) async {
            context.counter('counter').inc();
            await context.wait(10);
            print('NAO FOI INTERROMPIDO');
            context.counter('counter').inc();
          },
          name: 'a');
      sim.process(
          delay: 1,
          event: (context) async {
            context.stop();
          },
          name: 'b');
      sim.process(delay: 2, event: (context) async {}, name: 'c');
      await sim.run();

      helper.testEvents([
        '[0][a][called]',
        '[0][a][yielded]',
        '[1][b][called]',
        '[1][b][finished]',
        '[1][a][interrupted]'
      ]);
      helper.testTracks([
        'scheduleNextAction',
        'nextAction',
        'executeAction',
        'scheduleNextAction',
        'nextAction',
        'executeAction',
        'scheduleNextAction',
        'nextAction',
        'executeAction',
        'stop',
        'scheduleNextAction',
        'scheduleNextAction',
        'nextAction'
      ]);
      expect(sim.counter('counter').value, 1);
      expect(helper.completerCount, 0);
    });

    test('Resource', () async {
      sim.resources.limited(name: 'resource');
      sim.process(
          event: (context) async {
            await context.resources.acquire('resource');
            context.counter('counter1').inc();
            await context.wait(10);
            context.counter('counter1').inc();
            context.resources.release('resource');
          },
          name: 'a');
      sim.process(
          delay: 1,
          event: (context) async {
            context.counter('counter2').inc();
            await context.resources.acquire('resource');
            context.counter('counter2').inc();
          },
          name: 'b');
      sim.process(
          delay: 2,
          event: (context) async {
            context.stop();
          },
          name: 'c');
      sim.process(delay: 3, event: (context) async {}, name: 'd');
      await sim.run();

      helper.testEvents([
        '[0][a][called]',
        '[0][a][yielded]',
        '[1][b][called]',
        '[1][b][yielded]',
        '[2][c][called]',
        '[2][c][finished]'
      ]);
      helper.testTracks([
        'scheduleNextAction',
        'nextAction',
        'executeAction',
        'scheduleNextAction',
        'nextAction',
        'executeAction',
        'scheduleNextAction',
        'nextAction',
        'executeAction',
        'stop',
        'scheduleNextAction',
        'nextAction'
      ]);
      expect(sim.counter('counter1').value, 1);
      expect(sim.counter('counter2').value, 1);
      expect(helper.completerCount, 0);
    });
  });
}
