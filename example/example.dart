import 'package:simdart/simdart.dart';

void main() async {
  final SimDart sim = SimDart(onTrack: (track) => print(track));

  sim.process(event: _a, name: 'A');

  await sim.run(until: 10);
}

void _a(EventContext context) async {
  await context.wait(2);
  context.sim.process(event: _a, delay: 2, name: 'A');
}
