import 'package:simdart/simdart.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

void main() {
  group('Process', () {
    test('start', () async {
      TestHelper helper = TestHelper();
      helper.sim.process(TestHelper.emptyEvent, name: 'a');
      await helper.sim.run();
      expect(helper.trackList.length, 1);
      helper.testTrack(index: 0, name: 'a', status: Status.executed, time: 0);

      helper = TestHelper();
      helper.sim.process(TestHelper.emptyEvent, start: 10, name: 'a');
      await helper.sim.run();
      expect(helper.trackList.length, 1);
      helper.testTrack(index: 0, name: 'a', status: Status.executed, time: 10);
    });
    test('delay', () async {
      TestHelper helper = TestHelper();
      helper.sim.process(TestHelper.emptyEvent, delay: 0, name: 'a');
      await helper.sim.run();
      expect(helper.trackList.length, 1);
      helper.testTrack(index: 0, name: 'a', status: Status.executed, time: 0);

      helper = TestHelper();
      helper.sim.process(TestHelper.emptyEvent, delay: 10, name: 'a');
      await helper.sim.run();
      expect(helper.trackList.length, 1);
      helper.testTrack(index: 0, name: 'a', status: Status.executed, time: 10);

      helper = TestHelper();
      helper.sim.process((context) async {
        context.sim.process(TestHelper.emptyEvent, delay: 10, name: 'b');
      }, start: 5, name: 'a');
      await helper.sim.run();
      expect(helper.trackList.length, 2);
      helper.testTrack(index: 0, name: 'a', status: Status.executed, time: 5);
      helper.testTrack(index: 1, name: 'b', status: Status.executed, time: 15);

      helper = TestHelper();
      helper.sim.process((context) async {
        context.sim.process(TestHelper.emptyEvent, delay: 10, name: 'b');
      }, start: 0, name: 'a');
      helper.sim.process((context) async {
        context.sim.process(TestHelper.emptyEvent, delay: 2, name: 'd');
      }, start: 2, name: 'c');
      await helper.sim.run();
      expect(helper.trackList.length, 4);
      helper.testTrack(index: 0, name: 'a', status: Status.executed, time: 0);
      helper.testTrack(index: 1, name: 'c', status: Status.executed, time: 2);
      helper.testTrack(index: 2, name: 'd', status: Status.executed, time: 4);
      helper.testTrack(index: 3, name: 'b', status: Status.executed, time: 10);
    });
  });
}
