import 'dart:async';

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

  group('Error', () {
    test('Simple', () async {
      sim.process(
          event: (context) async {
            throw 'ERROR';
          },
          name: 'a');
      sim.process(event: (context) async {}, name: 'b');

      await expectLater(sim.run(), throwsA(equals('ERROR')));

      helper.testEvents(['[0][a][called]']);
      expect(helper.completerCount, 0);
    });

    test('Wait', () async {
      sim.process(
          event: (context) async {
            context.counter('counter').inc();
            await context.wait(10);
            context.counter('counter').inc();
          },
          name: 'a');
      sim.process(
          delay: 1,
          event: (context) async {
            throw 'ERROR';
          },
          name: 'b');
      sim.process(delay: 2, event: (context) async {}, name: 'c');

      await expectLater(sim.run(), throwsA(equals('ERROR')));

      helper
          .testEvents(['[0][a][called]', '[0][a][yielded]', '[1][b][called]']);
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
            throw 'ERROR';
          },
          name: 'c');
      sim.process(delay: 3, event: (context) async {}, name: 'd');

      await expectLater(sim.run(), throwsA(equals('ERROR')));

      helper.testEvents([
        '[0][a][called]',
        '[0][a][yielded]',
        '[1][b][called]',
        '[1][b][yielded]',
        '[2][c][called]'
      ]);
      expect(sim.counter('counter1').value, 1);
      expect(sim.counter('counter2').value, 1);
      expect(helper.completerCount, 0);
    });
  });
}
