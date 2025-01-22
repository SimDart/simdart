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
      expect(helper.trackList.length, 2);
      helper.testTrack(index: 0, name: 'A', status: Status.executed, time: 0);
      helper.testTrack(index: 1, name: 'A', status: Status.executed, time: 1);
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
      expect(helper.trackList.length, 4);
      helper.testTrack(index: 0, name: 'A', status: Status.executed, time: 0);
      helper.testTrack(index: 1, name: 'A', status: Status.resumed, time: 1);
      helper.testTrack(index: 2, name: 'A', status: Status.executed, time: 1);
      helper.testTrack(index: 3, name: 'A', status: Status.resumed, time: 2);
    });
  });
}
