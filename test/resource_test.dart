import 'package:simdart/simdart.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

void main() {
  late SimDart sim;
  TestHelper helper = TestHelper();

  setUp(() {
    sim = SimDart(listener: helper);
  });

  group('Resource', () {
    test('Capacity 1', () async {
      sim.resources.limited(name: 'r');

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

      await sim.run();

      helper.testEvents([
        '[0][A][called]',
        '[0][A][yielded]',
        '[0][B][called]',
        '[0][B][yielded]',
        '[0][C][called]',
        '[0][C][yielded]',
        '[1][A][resumed]',
        '[1][A][finished]',
        '[1][B][resumed]',
        '[1][B][yielded]',
        '[2][B][resumed]',
        '[2][B][finished]',
        '[2][C][resumed]',
        '[2][C][yielded]',
        '[3][C][resumed]',
        '[3][C][finished]'
      ]);
    });
    test('Capacity 2', () async {
      sim.resources.limited(name: 'r', capacity: 2);

      event(context) async {
        await context.resources.acquire('r');
        await context.wait(1);
        context.resources.release('r');
      }

      sim.process(event: event, name: 'A');
      sim.process(event: event, name: 'B');
      sim.process(event: event, name: 'C');

      await sim.run();

      helper.testEvents([
        '[0][A][called]',
        '[0][A][yielded]',
        '[0][B][called]',
        '[0][B][yielded]',
        '[0][C][called]',
        '[0][C][yielded]',
        '[1][A][resumed]',
        '[1][A][finished]',
        '[1][B][resumed]',
        '[1][B][finished]',
        '[1][C][resumed]',
        '[1][C][yielded]',
        '[2][C][resumed]',
        '[2][C][finished]'
      ]);
    });
    test('Avoid unnecessary re-executing', () async {
      sim.resources.limited(name: 'r', capacity: 2);

      eventResource(SimContext context) async {
        await context.resources.acquire('resource');
        await context.wait(10);
        context.resources.release('resource');
      }

      event(SimContext context) async {}

      sim.resources.limited(name: 'resource', capacity: 2);

      sim.process(event: eventResource, name: 'A');
      sim.process(event: eventResource, name: 'B', start: 1);
      sim.process(event: eventResource, name: 'C', start: 2);
      sim.process(event: event, name: 'D', start: 3);

      await sim.run();

      helper.testEvents([
        '[0][A][called]',
        '[0][A][yielded]',
        '[1][B][called]',
        '[1][B][yielded]',
        '[2][C][called]',
        '[2][C][yielded]',
        '[3][D][called]',
        '[3][D][finished]',
        '[10][A][resumed]',
        '[10][A][finished]',
        '[10][C][resumed]',
        '[10][C][yielded]',
        '[11][B][resumed]',
        '[11][B][finished]',
        '[20][C][resumed]',
        '[20][C][finished]'
      ]);
    });

    test('without await', () async {
      expect(() async {
        sim.resources.limited(name: 'r', capacity: 1);
        sim.process(
            event: (context) async {
              context.resources.acquire('r'); // acquired
              context.resources.acquire('r'); // should await
              context.resources.acquire('r'); // error
            },
            name: 'a');
        sim.process(event: (context) async {});
        await sim.run();
      },
          throwsA(isA<StateError>().having(
              (e) => e.message,
              'message',
              equals(
                  "This event should be waiting. Did you forget to use 'await'?"))));
    });
  });
}
