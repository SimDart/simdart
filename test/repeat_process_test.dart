import 'package:simdart/simdart.dart';
import 'package:test/test.dart';

import 'track_tester.dart';

void main() {
  group('Repeat process', () {
    test('Simple', () async {
      SimDart sim = SimDart(includeTracks: true, secondarySortByName: true);

      sim.repeatProcess(
          event: (context) {},
          name: 'A',
          interval: Interval.fixed(fixedInterval: 1, untilTime: 2));

      SimResult result = await sim.run();
      TrackTester tt = TrackTester(result);
      tt.test(["[0][A][executed]", "[1][A][executed]", "[2][A][executed]"]);
    });

    test('Wait', () async {
      SimDart sim = SimDart(includeTracks: true, secondarySortByName: true);

      sim.repeatProcess(
          event: (context) async {
            await context.wait(1);
          },
          name: 'A',
          interval: Interval.fixed(fixedInterval: 1, untilTime: 2));

      SimResult result = await sim.run();

      TrackTester tt = TrackTester(result);
      tt.test([
        "[0][A][executed]",
        "[1][A][resumed]",
        "[1][A][executed]",
        "[2][A][resumed]",
        "[2][A][executed]",
        "[3][A][resumed]"
      ]);
    });

    test('Resource - keep', () async {
      SimDart sim = SimDart(includeTracks: true, secondarySortByName: true);

      sim.resources.limited(id: 'r');

      sim.repeatProcess(
          event: (context) async {
            await context.wait(10);
          },
          name: 'A',
          resourceId: 'r',
          interval: Interval.fixed(fixedInterval: 1, untilTime: 2));

      SimResult result = await sim.run();

      TrackTester tt = TrackTester(result);
      tt.test([
        "[0][A][executed]",
        "[1][A][rejected]",
        "[2][A][rejected]",
        "[10][A][resumed]",
        "[10][A][executed]",
        "[10][A][rejected]",
        "[20][A][resumed]",
        "[20][A][executed]",
        "[30][A][resumed]"
      ]);
    });

    test('Resource - stop', () async {
      SimDart sim = SimDart(includeTracks: true, secondarySortByName: true);

      sim.resources.limited(id: 'r');

      sim.repeatProcess(
          event: (context) async {
            await context.wait(2);
          },
          name: 'A',
          resourceId: 'r',
          interval: Interval.fixed(fixedInterval: 1, untilTime: 50),
          rejectedEventPolicy: RejectedEventPolicy.stopRepeating);

      SimResult result = await sim.run();

      TrackTester tt = TrackTester(result);
      tt.test([
        "[0][A][executed]",
        "[1][A][rejected]",
        "[2][A][resumed]",
        "[2][A][executed]",
        "[4][A][resumed]"
      ]);
    });
  });
}
