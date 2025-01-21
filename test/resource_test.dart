import 'package:simdart/simdart.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

void main() {
  group('Resource', () {
    test('Capacity 1', () async {
      TestHelper helper = TestHelper();
      helper.sim.addResource(LimitedResource(id: 'r'));

      fA(context) async {
        await context.wait(1);
      }

      fB(context) async {
        await context.wait(1);
      }

      fC(context) async {
        await context.wait(1);
      }

      helper.sim.process(fA, name: 'A', resourceId: 'r');
      helper.sim.process(fB, name: 'B', resourceId: 'r');
      helper.sim.process(fC, name: 'C', resourceId: 'r');
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
      helper.sim.addResource(LimitedResource(id: 'r', capacity: 2));

      fA(context) async {
        await context.wait(1);
      }

      fB(context) async {
        await context.wait(1);
      }

      fC(context) async {
        await context.wait(1);
      }

      helper.sim.process(fA, name: 'A', resourceId: 'r');
      helper.sim.process(fB, name: 'B', resourceId: 'r');
      helper.sim.process(fC, name: 'C', resourceId: 'r');
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
  });
}
