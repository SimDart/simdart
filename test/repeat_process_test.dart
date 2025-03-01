import 'package:simdart/simdart.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

void main() {
  late SimDart sim;
  TestHelper helper = TestHelper();

  setUp(() {
    sim = SimDart(observer: helper);
  });

  group('Repeat process', () {
    test('Simple', () async {
      sim.repeatProcess(
          event: (context) async {},
          name: (start) => 'A$start',
          interval: Interval.fixed(fixedInterval: 1, untilTime: 2));

      await sim.run();
      helper.test([
        '[0][A0][called]',
        '[0][A0][finished]',
        '[1][A1][called]',
        '[1][A1][finished]',
        '[2][A2][called]',
        '[2][A2][finished]'
      ]);
    });

    test('Wait', () async {
      sim.repeatProcess(
          event: (context) async {
            await context.wait(1);
          },
          name: (start) => 'A$start',
          interval: Interval.fixed(fixedInterval: 1, untilTime: 2));

      await sim.run();
      helper.test([
        '[0][A0][called]',
        '[0][A0][yielded]',
        '[1][A0][resumed]',
        '[1][A0][finished]',
        '[1][A1][called]',
        '[1][A1][yielded]',
        '[2][A1][resumed]',
        '[2][A1][finished]',
        '[2][A2][called]',
        '[2][A2][yielded]',
        '[3][A2][resumed]',
        '[3][A2][finished]'
      ]);
    });

    test('Resource - acquire and wait', () async {
      sim.resources.limited(name: 'r');

      sim.process(
          event: (context) async {
            await context.resources.acquire('r');
            await context.wait(10);
            context.resources.release('r');
          },
          name: 'A');
      sim.process(
          event: (context) async {
            await context.resources.acquire('r');
            context.resources.release('r');
          },
          name: 'B');

      await sim.run();

      helper.test([
        '[0][A][called]',
        '[0][A][yielded]',
        '[0][B][called]',
        '[0][B][yielded]',
        '[10][A][resumed]',
        '[10][A][finished]',
        '[10][B][resumed]',
        '[10][B][finished]'
      ]);
    });

    test('Resource', () async {
      sim.resources.limited(name: 'r');

      sim.repeatProcess(
          event: (context) async {
            await context.resources.acquire('r');
            await context.wait(10);
            context.resources.release('r');
          },
          name: (start) => 'A$start',
          interval: Interval.fixed(fixedInterval: 1, untilTime: 2));

      await sim.run();

      helper.test([
        '[0][A0][called]',
        '[0][A0][yielded]',
        '[1][A1][called]',
        '[1][A1][yielded]',
        '[2][A2][called]',
        '[2][A2][yielded]',
        '[10][A0][resumed]',
        '[10][A0][finished]',
        '[10][A1][resumed]',
        '[10][A1][yielded]',
        '[20][A1][resumed]',
        '[20][A1][finished]',
        '[20][A2][resumed]',
        '[20][A2][yielded]',
        '[30][A2][resumed]',
        '[30][A2][finished]'
      ]);
    });

    test('Resource - stop', () async {
      sim.resources.limited(name: 'r');

      sim.repeatProcess(
          event: (context) async {
            await context.resources.acquire('r');
            await context.wait(2);
            context.resources.release('r');
          },
          name: (start) => 'A$start',
          stopCondition: (s) => !s.resources.isAvailable('r'),
          interval: Interval.fixed(fixedInterval: 1, untilTime: 50));

      await sim.run();

      helper.test([
        '[0][A0][called]',
        '[0][A0][yielded]',
        '[2][A0][resumed]',
        '[2][A0][finished]'
      ]);
    });
  });
}
