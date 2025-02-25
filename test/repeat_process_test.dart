import 'package:simdart/simdart.dart';
import 'package:test/test.dart';

import 'track_tester.dart';

void main() {
  group('Repeat process', () {
    test('Simple', () async {
      SimDart sim = SimDart(includeTracks: true);

      sim.repeatProcess(
          event: (context) async {},
          name: (start) => 'A$start',
          interval: Interval.fixed(fixedInterval: 1, untilTime: 2));

      SimResult result = await sim.run();
      TrackTester tt = TrackTester(result);
      tt.test(['[0][A0][called]', '[1][A1][called]', '[2][A2][called]']);
    });

    test('Wait', () async {
      SimDart sim = SimDart(includeTracks: true);

      sim.repeatProcess(
          event: (context) async {
            await context.wait(1);
          },
          name: (start) => 'A$start',
          interval: Interval.fixed(fixedInterval: 1, untilTime: 2));

      SimResult result = await sim.run();

      TrackTester tt = TrackTester(result);
      tt.test([
        '[0][A0][called]',
        '[0][A0][yielded]',
        '[1][A0][resumed]',
        '[1][A1][called]',
        '[1][A1][yielded]',
        '[2][A1][resumed]',
        '[2][A2][called]',
        '[2][A2][yielded]',
        '[3][A2][resumed]'
      ]);
    });

    test('Resource - acquire and wait', () async {
      SimDart sim = SimDart(includeTracks: true);

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

      SimResult result = await sim.run();

      TrackTester tt = TrackTester(result);
      tt.test([
        '[0][A][called]',
        '[0][A][yielded]',
        '[0][B][called]',
        '[0][B][yielded]',
        '[10][A][resumed]',
        '[10][B][resumed]'
      ]);
    });

    test('Resource', () async {
      SimDart sim = SimDart(includeTracks: true);

      sim.resources.limited(name: 'r');

      sim.repeatProcess(
          event: (context) async {
            await context.resources.acquire('r');
            await context.wait(10);
            context.resources.release('r');
          },
          name: (start) => 'A$start',
          interval: Interval.fixed(fixedInterval: 1, untilTime: 2));

      SimResult result = await sim.run();

      TrackTester tt = TrackTester(result);
      tt.test([
        '[0][A0][called]',
        '[0][A0][yielded]',
        '[1][A1][called]',
        '[1][A1][yielded]',
        '[2][A2][called]',
        '[2][A2][yielded]',
        '[10][A0][resumed]',
        '[10][A1][resumed]',
        '[10][A1][yielded]',
        '[20][A1][resumed]',
        '[20][A2][resumed]',
        '[20][A2][yielded]',
        '[30][A2][resumed]'
      ]);
    });

    test('Resource - stop', () async {
      SimDart sim = SimDart(includeTracks: true);

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

      SimResult result = await sim.run();

      TrackTester tt = TrackTester(result);
      tt.test(['[0][A0][called]', '[0][A0][yielded]', '[2][A0][resumed]']);
    });
  });
}
