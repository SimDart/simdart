import 'package:simdart/simdart.dart';
import 'package:test/test.dart';

import 'track_tester.dart';

void main() {
  group('Resource', () {
    test('Capacity 1', () async {
      SimDart sim = SimDart(includeTracks: true, secondarySortByName: true);
      sim.resources.limited(id: 'r');

      fA(context) async {
        await context.resources.acquire('r');
        await context.wait(1);
        context.resources.release('r');
      }

      fB(context) async {
        await context.resources.acquire('r');
        await context.wait(1);
        context.resources.release('r');
      }

      fC(context) async {
        await context.resources.acquire('r');
        await context.wait(1);
        context.resources.release('r');
      }

      sim.process(event: fA, name: 'A');
      sim.process(event: fB, name: 'B');
      sim.process(event: fC, name: 'C');

      SimResult result = await sim.run();

      TrackTester tt = TrackTester(result);
      tt.test([
        '[0][A][called]',
        '[0][A][yielded]',
        '[0][B][called]',
        '[0][B][yielded]',
        '[0][C][called]',
        '[0][C][yielded]',
        '[1][A][resumed]',
        '[1][B][resumed]',
        '[1][B][yielded]',
        '[2][B][resumed]',
        '[2][C][resumed]',
        '[2][C][yielded]',
        '[3][C][resumed]'
      ]);
    });
    test('Capacity 2', () async {
      SimDart sim = SimDart(includeTracks: true, secondarySortByName: true);
      sim.resources.limited(id: 'r', capacity: 2);

      event(context) async {
        await context.resources.acquire('r');
        await context.wait(1);
        context.resources.release('r');
      }

      sim.process(event: event, name: 'A');
      sim.process(event: event, name: 'B');
      sim.process(event: event, name: 'C');

      SimResult result = await sim.run();

      TrackTester tt = TrackTester(result);
      tt.test([
        '[0][A][called]',
        '[0][A][yielded]',
        '[0][B][called]',
        '[0][B][yielded]',
        '[0][C][called]',
        '[0][C][yielded]',
        '[1][A][resumed]',
        '[1][C][resumed]',
        '[1][C][yielded]',
        '[1][B][resumed]',
        '[2][C][resumed]'
      ]);
    });
    test('Avoid unnecessary re-executing', () async {
      SimDart sim = SimDart(includeTracks: true, secondarySortByName: true);
      sim.resources.limited(id: 'r', capacity: 2);

      eventA(SimContext context) async {
        await context.resources.acquire('resource');
        await context.wait(10);
        context.resources.release('resource');
      }

      eventB(SimContext context) async {}

      sim.resources.limited(id: 'resource', capacity: 2);

      sim.process(event: eventA, name: 'A1');
      sim.process(event: eventA, name: 'A2', start: 1);
      sim.process(event: eventA, name: 'A3', start: 2);
      sim.process(event: eventB, name: 'B', start: 3);

      SimResult result = await sim.run();

      TrackTester tt = TrackTester(result);
      tt.test([
        '[0][A1][called]',
        '[0][A1][yielded]',
        '[1][A2][called]',
        '[1][A2][yielded]',
        '[2][A3][called]',
        '[2][A3][yielded]',
        '[3][B][called]',
        '[10][A1][resumed]',
        '[10][A3][resumed]',
        '[10][A3][yielded]',
        '[11][A2][resumed]',
        '[20][A3][resumed]'
      ]);
    });
  });
}
