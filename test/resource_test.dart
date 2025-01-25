import 'package:simdart/simdart.dart';
import 'package:simdart/src/sim_result.dart';
import 'package:test/test.dart';

import 'track_tester.dart';

void main() {
  group('Resource', () {
    test('Capacity 1', () async {
      SimDart sim = SimDart(includeTracks: true, secondarySortByName: true);
      sim.resources.limited(id: 'r');

      fA(context) async {
        await context.wait(1);
      }

      fB(context) async {
        await context.wait(1);
      }

      fC(context) async {
        await context.wait(1);
      }

      sim.process(event: fA, name: 'A', resourceId: 'r');
      sim.process(event: fB, name: 'B', resourceId: 'r');
      sim.process(event: fC, name: 'C', resourceId: 'r');

      SimResult result = await sim.run();

      TrackTester tt = TrackTester(result);
      tt.test([
        "[0][A][executed]",
        "[0][B][rejected]",
        "[0][C][rejected]",
        "[1][A][resumed]",
        "[1][B][executed]",
        "[1][C][rejected]",
        "[2][B][resumed]",
        "[2][C][executed]",
        "[3][C][resumed]"
      ]);
    });
    test('Capacity 2', () async {
      SimDart sim = SimDart(includeTracks: true, secondarySortByName: true);
      sim.resources.limited(id: 'r', capacity: 2);

      fA(context) async {
        await context.wait(1);
      }

      fB(context) async {
        await context.wait(1);
      }

      fC(context) async {
        await context.wait(1);
      }

      sim.process(event: fA, name: 'A', resourceId: 'r');
      sim.process(event: fB, name: 'B', resourceId: 'r');
      sim.process(event: fC, name: 'C', resourceId: 'r');

      SimResult result = await sim.run();

      TrackTester tt = TrackTester(result);
      tt.test([
        "[0][A][executed]",
        "[0][B][executed]",
        "[0][C][rejected]",
        "[1][A][resumed]",
        "[1][C][executed]",
        "[1][B][resumed]",
        "[2][C][resumed]"
      ]);
    });
    test('Avoid unnecessary re-executing', () async {
      SimDart sim = SimDart(includeTracks: true, secondarySortByName: true);
      sim.resources.limited(id: 'r', capacity: 2);

      eventA(EventContext context) async {
        await context.wait(10);
      }

      eventB(EventContext context) async {}

      sim.resources.limited(id: 'resource', capacity: 2);

      sim.process(event: eventA, name: 'A1', resourceId: 'resource');
      sim.process(event: eventA, name: 'A2', start: 1, resourceId: 'resource');
      sim.process(event: eventA, name: 'A3', start: 2, resourceId: 'resource');
      sim.process(event: eventB, name: 'B', start: 3);

      SimResult result = await sim.run();

      TrackTester tt = TrackTester(result);
      tt.test([
        "[0][A1][executed]",
        "[1][A2][executed]",
        "[2][A3][rejected]",
        "[3][B][executed]",
        "[10][A1][resumed]",
        "[10][A3][executed]",
        "[11][A2][resumed]",
        "[20][A3][resumed]"
      ]);
    });
  });
}
