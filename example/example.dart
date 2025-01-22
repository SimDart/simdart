import 'package:simdart/simdart.dart';

void main() async {
  final SimDart sim = SimDart(onTrack: (track) => print(track));

  //sim.addEventScheduler(EventScheduler(start: 0, interval: Interval.fixed(fixedInterval: 1, untilTime: 3), event: eventA, name: 'S', eventName: 'A'));
  //sim.process(eventA, name: 'A');
  //sim.process(eventB, start: 5, name: 'B');

  await sim.run();
}

void eventA(EventContext context) async {
  // await context.wait(10);
  // context.sim.process(eventC, delay: 1, name: 'C');
}

void eventB(EventContext context) async {
  await context.wait(1);
}

void eventC(EventContext context) async {
  await context.wait(10);
}
