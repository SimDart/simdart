import 'package:simdart/simdart.dart';
import 'package:test/test.dart';

import 'track_tester.dart';

Future<void> emptyEvent(SimContext context) async {}

void main() {
  group('Process', () {
    test('start', () async {
      SimDart sim = SimDart(includeTracks: true, secondarySortByName: true);
      sim.process(event: emptyEvent, name: 'a');
      SimResult result = await sim.run();
      TrackTester tt = TrackTester(result);
      tt.test(["[0][a][called]"]);

      sim = SimDart(includeTracks: true, secondarySortByName: true);
      sim.process(event: emptyEvent, start: 10, name: 'a');
      result = await sim.run();
      tt = TrackTester(result);
      tt.test(["[10][a][called]"]);
    });
    test('delay 1', () async {
      SimDart sim = SimDart(includeTracks: true, secondarySortByName: true);
      sim.process(event: emptyEvent, delay: 0, name: 'a');
      SimResult result = await sim.run();
      TrackTester tt = TrackTester(result);
      tt.test(["[0][a][called]"]);
    });
    test('delay 2', () async {
      SimDart sim = SimDart(includeTracks: true, secondarySortByName: true);
      sim.process(event: emptyEvent, delay: 10, name: 'a');
      SimResult result = await sim.run();
      TrackTester tt = TrackTester(result);
      tt.test(["[10][a][called]"]);
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
      tt.test(["[5][a][called]", "[15][b][called]"]);
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
        "[0][a][called]",
        "[2][c][called]",
        "[4][d][called]",
        "[10][b][called]"
      ]);
    });
  });
}
