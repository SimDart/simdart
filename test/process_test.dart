import 'package:simdart/simdart.dart';
import 'package:test/test.dart';

import 'track_tester.dart';

Future<void> emptyEvent(SimDart sim) async {}

void main() {
  group('Process', () {
    test('start', () async {
      SimDart sim = SimDart(includeTracks: true, secondarySortByName: true);
      sim.process(event: emptyEvent, name: 'a');
      SimResult result = await sim.run();
      TrackTester tt = TrackTester(result);
      tt.test(["[0][a][executed]"]);

      sim = SimDart(includeTracks: true, secondarySortByName: true);
      sim.process(event: emptyEvent, start: 10, name: 'a');
      result = await sim.run();
      tt = TrackTester(result);
      tt.test(["[10][a][executed]"]);
    });
    test('delay 1', () async {
      SimDart sim = SimDart(includeTracks: true, secondarySortByName: true);
      sim.process(event: emptyEvent, delay: 0, name: 'a');
      SimResult result = await sim.run();
      TrackTester tt = TrackTester(result);
      tt.test(["[0][a][executed]"]);
    });
    test('delay 2', () async {
      SimDart sim = SimDart(includeTracks: true, secondarySortByName: true);
      sim.process(event: emptyEvent, delay: 10, name: 'a');
      SimResult result = await sim.run();
      TrackTester tt = TrackTester(result);
      tt.test(["[10][a][executed]"]);
    });
    test('delay 3', () async {
      SimDart sim = SimDart(includeTracks: true, secondarySortByName: true);
      sim.process(
          event: (context) async {
            context.process(event: emptyEvent, delay: 10, name: 'b');
          },
          start: 5,
          name: 'a');
      SimResult result = await sim.run();
      TrackTester tt = TrackTester(result);
      tt.test(["[5][a][executed]", "[15][b][executed]"]);
    });
    test('delay 4', () async {
      SimDart sim = SimDart(includeTracks: true, secondarySortByName: true);
      sim.process(
          event: (context) async {
            context.process(event: emptyEvent, delay: 10, name: 'b');
          },
          start: 0,
          name: 'a');
      sim.process(
          event: (context) async {
            context.process(event: emptyEvent, delay: 2, name: 'd');
          },
          start: 2,
          name: 'c');
      SimResult result = await sim.run();
      TrackTester tt = TrackTester(result);
      tt.test([
        "[0][a][executed]",
        "[2][c][executed]",
        "[4][d][executed]",
        "[10][b][executed]"
      ]);
    });
  });
}
