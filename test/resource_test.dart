import 'package:simdart/simdart.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

void main() {
  group('Resource', () {
    test('Capacity 1', () async {
      TestHelper helper = TestHelper();
      helper.sim.resources.limited(id: 'r');

      fA(context) async {
        await context.wait(1);
      }

      fB(context) async {
        await context.wait(1);
      }

      fC(context) async {
        await context.wait(1);
      }

      helper.sim.process(event: fA, name: 'A', resourceId: 'r');
      helper.sim.process(event: fB, name: 'B', resourceId: 'r');
      helper.sim.process(event: fC, name: 'C', resourceId: 'r');
      await helper.sim.run();
      expect(helper.trackList.length, 9);
      helper.testTrack(index: 0, name: 'A', status: Status.executed, time: 0);
      helper.testTrack(index: 1, name: 'B', status: Status.rejected, time: 0);
      helper.testTrack(index: 2, name: 'C', status: Status.rejected, time: 0);

      helper.testTrack(index: 3, name: 'A', status: Status.resumed, time: 1);
      helper.testTrack(index: 4, name: 'B', status: Status.executed, time: 1);
      helper.testTrack(index: 5, name: 'C', status: Status.rejected, time: 1);
      helper.testTrack(index: 6, name: 'B', status: Status.resumed, time: 2);
      helper.testTrack(index: 7, name: 'C', status: Status.executed, time: 2);
      helper.testTrack(index: 8, name: 'C', status: Status.resumed, time: 3);
    });
    test('Capacity 2', () async {
      TestHelper helper = TestHelper();
      helper.sim.resources.limited(id: 'r', capacity: 2);

      fA(context) async {
        await context.wait(1);
      }

      fB(context) async {
        await context.wait(1);
      }

      fC(context) async {
        await context.wait(1);
      }

      helper.sim.process(event: fA, name: 'A', resourceId: 'r');
      helper.sim.process(event: fB, name: 'B', resourceId: 'r');
      helper.sim.process(event: fC, name: 'C', resourceId: 'r');
      await helper.sim.run();
      expect(helper.trackList.length, 7);
      helper.testTrack(index: 0, name: 'A', status: Status.executed, time: 0);
      helper.testTrack(index: 1, name: 'B', status: Status.executed, time: 0);
      helper.testTrack(index: 2, name: 'C', status: Status.rejected, time: 0);

      helper.testTrack(index: 3, name: 'A', status: Status.resumed, time: 1);
      helper.testTrack(index: 4, name: 'C', status: Status.executed, time: 1);
      helper.testTrack(index: 5, name: 'B', status: Status.resumed, time: 1);
      helper.testTrack(index: 6, name: 'C', status: Status.resumed, time: 2);
    });
    test('Avoid unnecessary re-executing', () async {
      TestHelper helper = TestHelper();
      helper.sim.resources.limited(id: 'r', capacity: 2);

      eventA(EventContext context) async {
        await context.wait(10);
      }

      eventB(EventContext context) async {}

      SimDart sim = helper.sim;

      sim.resources.limited(id: 'resource', capacity: 2);

      sim.process(event: eventA, name: 'A1', resourceId: 'resource');
      sim.process(event: eventA, name: 'A2', start: 1, resourceId: 'resource');
      sim.process(event: eventA, name: 'A3', start: 2, resourceId: 'resource');
      sim.process(event: eventB, name: 'B', start: 3);

      await helper.sim.run();
      expect(helper.trackList.length, 8);
      helper.testTrack(index: 0, name: 'A1', status: Status.executed, time: 0);
      helper.testTrack(index: 1, name: 'A2', status: Status.executed, time: 1);
      helper.testTrack(index: 2, name: 'A3', status: Status.rejected, time: 2);
      helper.testTrack(index: 3, name: 'B', status: Status.executed, time: 3);
      helper.testTrack(index: 4, name: 'A1', status: Status.resumed, time: 10);
      helper.testTrack(index: 5, name: 'A3', status: Status.executed, time: 10);
      helper.testTrack(index: 6, name: 'A2', status: Status.resumed, time: 11);
      helper.testTrack(index: 7, name: 'A3', status: Status.resumed, time: 20);
    });
  });
}
