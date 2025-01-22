import 'package:simdart/simdart.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

void main() {
  group('Wait', () {
    test('with await', () async {
      TestHelper helper = TestHelper();
      helper.sim.process(
          event: (context) async {
            await context.wait(10);
          },
          name: 'a');
      helper.sim.process(event: TestHelper.emptyEvent, start: 5, name: 'b');
      await helper.sim.run();
      expect(helper.trackList.length, 3);
      helper.testTrack(index: 0, name: 'a', status: Status.executed, time: 0);
      helper.testTrack(index: 1, name: 'b', status: Status.executed, time: 5);
      helper.testTrack(index: 2, name: 'a', status: Status.resumed, time: 10);

      helper = TestHelper();
      helper.sim.process(
          event: (context) async {
            await context.wait(10);
            helper.sim
                .process(event: TestHelper.emptyEvent, delay: 1, name: 'c');
          },
          start: 0,
          name: 'a');
      helper.sim.process(event: TestHelper.emptyEvent, delay: 5, name: 'b');
      await helper.sim.run();
      expect(helper.trackList.length, 4);
      helper.testTrack(index: 0, name: 'a', status: Status.executed, time: 0);
      helper.testTrack(index: 1, name: 'b', status: Status.executed, time: 5);
      helper.testTrack(index: 2, name: 'a', status: Status.resumed, time: 10);
      helper.testTrack(index: 3, name: 'c', status: Status.executed, time: 11);
    });

    test('without await', () async {
      TestHelper helper = TestHelper();
      helper.sim.process(
          event: (context) async {
            context.wait(10);
          },
          name: 'a');
      helper.sim.process(event: TestHelper.emptyEvent, start: 5, name: 'b');
      await helper.sim.run();
      expect(helper.trackList.length, 3);
      helper.testTrack(index: 0, name: 'a', status: Status.executed, time: 0);
      helper.testTrack(index: 1, name: 'b', status: Status.executed, time: 5);
      helper.testTrack(index: 2, name: 'a', status: Status.resumed, time: 10);

      helper = TestHelper();
      helper.sim.process(
          event: (context) async {
            context.wait(10);
            helper.sim
                .process(event: TestHelper.emptyEvent, delay: 1, name: 'c');
          },
          start: 0,
          name: 'a');
      helper.sim.process(event: TestHelper.emptyEvent, delay: 5, name: 'b');
      await helper.sim.run();
      expect(helper.trackList.length, 4);
      helper.testTrack(index: 0, name: 'a', status: Status.executed, time: 0);
      helper.testTrack(index: 1, name: 'c', status: Status.executed, time: 1);
      helper.testTrack(index: 2, name: 'b', status: Status.executed, time: 5);
      helper.testTrack(index: 3, name: 'a', status: Status.resumed, time: 10);
    });
  });
}
