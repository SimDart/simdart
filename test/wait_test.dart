import 'package:simdart/simdart.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

Future<void> emptyEvent(SimContext context) async {}

void main() {
  late SimDart sim;
  TestHelper helper = TestHelper();

  setUp(() {
    sim = SimDart(listener: helper);
  });

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
      sim.process(
          event: (context) async {
            await context.wait(10);
          },
          name: 'a');

      await sim.run();

      helper.testEvents([
        '[0][a][called]',
        '[0][a][yielded]',
        '[10][a][resumed]',
        '[10][a][finished]'
      ]);
    });
    test('with await', () async {
      sim.process(
          event: (context) async {
            await context.wait(10);
          },
          name: 'a');
      sim.process(event: emptyEvent, start: 5, name: 'b');

      await sim.run();
      helper.testEvents([
        '[0][a][called]',
        '[0][a][yielded]',
        '[5][b][called]',
        '[5][b][finished]',
        '[10][a][resumed]',
        '[10][a][finished]'
      ]);
    });
    test('with await 2', () async {
      sim.process(
          event: (context) async {
            await context.wait(10);
            sim.process(event: emptyEvent, delay: 1, name: 'c');
          },
          start: 0,
          name: 'a');
      sim.process(event: emptyEvent, delay: 5, name: 'b');

      await sim.run();
      helper.testEvents([
        '[0][a][called]',
        '[0][a][yielded]',
        '[5][b][called]',
        '[5][b][finished]',
        '[10][a][resumed]',
        '[10][a][finished]',
        '[11][c][called]',
        '[11][c][finished]'
      ]);
    });

    test('wait without await', () async {
      expect(
        () async {
          sim.process(
              event: (context) async {
                context.wait(10);
              },
              name: 'a');
          sim.process(event: emptyEvent, start: 5, name: 'b');

          await sim.run();
        },
          throwsA(isA<StateError>().having((e) => e.message, 'message', equals("Next event is being scheduled, but the current one is still paused waiting for continuation. Did you forget to use 'await'?")))
      );
    });

    test('multiple wait without await', () async {
      expect(
        () async {
          sim.process(
              event: (context) async {
                context.wait(10);
                context.wait(10);
              },
              name: 'a');
          await sim.run();
          print('depois');
        },
        throwsA(isA<StateError>().having((e) => e.message, 'message', equals("The event is already waiting. Did you forget to use 'await'?")))
      );
    });
  });
}
