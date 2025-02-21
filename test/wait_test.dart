import 'package:simdart/simdart.dart';
import 'package:test/test.dart';

import 'track_tester.dart';

Future<void> emptyEvent(SimContext context) async {}

void main() {
  group('Wait', () {
    test('now', () async {
      late int now1, now2;
      SimDart sim = SimDart();
      sim.process(
          start: 1,
          event: (context) async {
            now1 = context.now;
            await context.wait(10);
            now2 = context.now;
          });

      await sim.run();
      expect(now1, 1);
      expect(now2, 11);
    });
    test('simple', () async {
      SimDart sim = SimDart(includeTracks: true, secondarySortByName: true);
      sim.process(
          event: (context) async {
            await context.wait(10);
          },
          name: 'a');

      SimResult result = await sim.run();

      TrackTester tt = TrackTester(result);
      tt.test(['[0][a][called]', '[0][a][yielded]', '[10][a][resumed]']);
    });
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
      tt.test([
        '[0][a][called]',
        '[0][a][yielded]',
        '[5][b][called]',
        '[10][a][resumed]'
      ]);
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
        '[0][a][called]',
        '[0][a][yielded]',
        '[5][b][called]',
        '[10][a][resumed]',
        '[11][c][called]'
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
      tt.test([
        '[0][a][called]',
        '[0][a][yielded]',
        '[5][b][called]',
        '[10][a][resumed]'
      ]);
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
        '[0][a][called]',
        '[0][a][yielded]',
        '[1][c][called]',
        '[5][b][called]',
        '[10][a][resumed]'
      ]);
    });
  });
}
