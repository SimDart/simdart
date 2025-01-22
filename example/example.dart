import 'package:simdart/simdart.dart';

void main() async {
  final SimDart sim = SimDart(onTrack: (track) => print(track));

  sim.process(event: _a, name: 'A');
  sim.process(event: _b, start: 5, name: 'B');

  await sim.run();
}

void _a(EventContext context) async {
  await context.wait(10);
  context.sim.process(event: _c, delay: 1, name: 'C');
}

void _b(EventContext context) async {
  await context.wait(1);
}

void _c(EventContext context) async {
  await context.wait(10);
}
