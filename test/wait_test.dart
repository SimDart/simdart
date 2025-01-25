import 'package:simdart/simdart.dart';
import 'package:simdart/src/sim_result.dart';
import 'package:test/test.dart';

import 'track_tester.dart';

Future<void> emptyEvent(EventContext context) async {}

void main() {
  group('Wait', () {
    test('with await', () async {
      SimDart sim = SimDart(includeTracks: true, secondarySortByName: true);
      sim.process(
          event: (context) async {
            await context.wait(10);
          },
          name: 'a');
      sim.process(event: emptyEvent, start: 5, name: 'b');

      SimResult result = await sim.run();

      TrackTester tt = TrackTester(result);
      tt.test(["[0][a][executed]", "[5][b][executed]", "[10][a][resumed]"]);
    });
    test('with await 2', () async {
      SimDart sim = SimDart(includeTracks: true, secondarySortByName: true);
      sim.process(
          event: (context) async {
            await context.wait(10);
            sim.process(event: emptyEvent, delay: 1, name: 'c');
          },
          start: 0,
          name: 'a');
      sim.process(event: emptyEvent, delay: 5, name: 'b');

      SimResult result = await sim.run();

      TrackTester tt = TrackTester(result);
      tt.test([
        "[0][a][executed]",
        "[5][b][executed]",
        "[10][a][resumed]",
        "[11][c][executed]"
      ]);
    });

    test('without await', () async {
      SimDart sim = SimDart(includeTracks: true, secondarySortByName: true);
      sim.process(
          event: (context) async {
            context.wait(10);
          },
          name: 'a');
      sim.process(event: emptyEvent, start: 5, name: 'b');

      SimResult result = await sim.run();

      TrackTester tt = TrackTester(result);
      tt.test(["[0][a][executed]", "[5][b][executed]", "[10][a][resumed]"]);
    });

    test('without await 2', () async {
      SimDart sim = SimDart(includeTracks: true, secondarySortByName: true);
      sim.process(
          event: (context) async {
            context.wait(10);
            sim.process(event: emptyEvent, delay: 1, name: 'c');
          },
          start: 0,
          name: 'a');
      sim.process(event: emptyEvent, delay: 5, name: 'b');

      SimResult result = await sim.run();

      TrackTester tt = TrackTester(result);
      tt.test([
        "[0][a][executed]",
        "[1][c][executed]",
        "[5][b][executed]",
        "[10][a][resumed]"
      ]);
    });
  });
}
