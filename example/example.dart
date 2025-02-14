import 'package:simdart/simdart.dart';

void main() async {
  final SimDart sim = SimDart(includeTracks: true);

  sim.process(event: _a, name: 'A');

  SimResult result = await sim.run(until: 10);

  result.tracks?.forEach((track) => print(track));
  print('startTime: ${result.startTime}');
  print('duration: ${result.duration}');
}

void _a(SimDart sim) async {
  await sim.wait(2);
  sim.process(event: _a, delay: 2, name: 'A');
}
