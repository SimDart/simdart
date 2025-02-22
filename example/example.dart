import 'package:simdart/simdart.dart';

void main() async {
  final SimDart sim = SimDart(includeTracks: true);

  sim.process(event: _eventA, name: 'A');

  SimResult result = await sim.run();

  result.tracks?.forEach((track) => print(track));
  print('startTime: ${result.startTime}');
  print('duration: ${result.duration}');
}

Future<void> _eventA(SimContext context) async {
  await context.wait(2);
  context.process(event: _eventB, delay: 2, name: 'B');
}

Future<void> _eventB(SimContext context) async {}
