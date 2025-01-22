import 'package:simdart/simdart.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

void main() {
  group('Repeat process', () {
    test('Simple', () async {
      TestHelper helper = TestHelper();

      helper.sim.repeatProcess(
          event: (context) {},
          name: 'A',
          interval: Interval.fixed(fixedInterval: 1, untilTime: 2));

      await helper.sim.run();
      expect(helper.trackList.length, 3);
      helper.testTrack(index: 0, name: 'A', status: Status.executed, time: 0);
      helper.testTrack(index: 1, name: 'A', status: Status.executed, time: 1);
      helper.testTrack(index: 2, name: 'A', status: Status.executed, time: 2);
    });

    test('Wait', () async {
      TestHelper helper = TestHelper();

      helper.sim.repeatProcess(
          event: (context) async {
            await context.wait(1);
          },
          name: 'A',
          interval: Interval.fixed(fixedInterval: 1, untilTime: 2));

      await helper.sim.run();
      expect(helper.trackList.length, 6);
      helper.testTrack(index: 0, name: 'A', status: Status.executed, time: 0);
      helper.testTrack(index: 1, name: 'A', status: Status.resumed, time: 1);
      helper.testTrack(index: 2, name: 'A', status: Status.executed, time: 1);
      helper.testTrack(index: 3, name: 'A', status: Status.resumed, time: 2);
      helper.testTrack(index: 4, name: 'A', status: Status.executed, time: 2);
      helper.testTrack(index: 5, name: 'A', status: Status.resumed, time: 3);
    });

    test('Resource - keep', () async {
      TestHelper helper = TestHelper();

      helper.sim.resources.limited(id: 'r');

      helper.sim.repeatProcess(
          event: (context) async {
            await context.wait(10);
          },
          name: 'A',
          resourceId: 'r',
          interval: Interval.fixed(fixedInterval: 1, untilTime: 2));

      await helper.sim.run();
      expect(helper.trackList.length, 9);
      helper.testTrack(index: 0, name: 'A', status: Status.executed, time: 0);
      helper.testTrack(index: 1, name: 'A', status: Status.rejected, time: 1);
      helper.testTrack(index: 2, name: 'A', status: Status.rejected, time: 2);
      helper.testTrack(index: 3, name: 'A', status: Status.resumed, time: 10);
      helper.testTrack(index: 4, name: 'A', status: Status.executed, time: 10);
      helper.testTrack(index: 5, name: 'A', status: Status.rejected, time: 10);
      helper.testTrack(index: 6, name: 'A', status: Status.resumed, time: 20);
      helper.testTrack(index: 7, name: 'A', status: Status.executed, time: 20);
      helper.testTrack(index: 8, name: 'A', status: Status.resumed, time: 30);
    });

    test('Resource - stop', () async {
      TestHelper helper = TestHelper();

      helper.sim.resources.limited(id: 'r');

      helper.sim.repeatProcess(
          event: (context) async {
            await context.wait(2);
          },
          name: 'A',
          resourceId: 'r',
          interval: Interval.fixed(fixedInterval: 1, untilTime: 50),
          rejectedEventPolicy: RejectedEventPolicy.stopRepeating);

      await helper.sim.run();
      expect(helper.trackList.length, 5);
      helper.testTrack(index: 0, name: 'A', status: Status.executed, time: 0);
      helper.testTrack(index: 1, name: 'A', status: Status.rejected, time: 1);
      helper.testTrack(index: 2, name: 'A', status: Status.resumed, time: 2);
      helper.testTrack(index: 3, name: 'A', status: Status.executed, time: 2);
      helper.testTrack(index: 4, name: 'A', status: Status.resumed, time: 4);
    });
  });
}
