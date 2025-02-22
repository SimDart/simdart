[![](https://img.shields.io/pub/v/simdart.svg)](https://pub.dev/packages/simdart)
[![](https://img.shields.io/badge/%F0%9F%91%8D%20and%20%E2%AD%90-are%20free-yellow)](#)

![](https://simdart.github.io/simdart-assets/simdart-text-128h.png)

---

**SimDart** is a discrete event simulation (DES) framework written in Dart.
It is designed to model and simulate systems where events occur at discrete points in time,
allowing for the analysis of complex processes and workflows.

Explore and learn more by clicking [here](https://simdart.github.io/simdart-demo/).

## Why Dart?

[Dart](https://dart.dev/) was chosen for this project due to its fast execution, single-threaded nature, and ease of use.
Dart's single-threaded model makes it particularly well-suited for discrete event simulation (DES),
as it simplifies the process of managing and processing events in sequence.
Dart's efficient handling of asynchronous tasks and event queues ensures
high performance in managing and executing events with minimal overhead.

Additionally, Dart's strong integration with [Flutter](https://flutter.dev/) makes it an ideal choice for developing
frontend applications to visualize and interact with simulations.

## Main Features

### Event Scheduling and Queue Management

- **Event Queue**  
  The core mechanism for scheduling events within the simulation. Events are placed in the queue and executed in order of their scheduled time. When resources are involved, events may wait in a queue until capacity becomes available.

- **Schedule Event at Specific Time**  
  Schedule an event to occur at a specific time. This allows events to be set to occur at precise simulation times.

- **Schedule Event After Delay**  
  Schedule an event to occur after a certain delay. This introduces a time gap between events, simulating waiting periods or delays.

- **Schedule Event Based on Interval**  
  Schedule recurring events to occur at regular intervals. This allows events to be triggered periodically, which is useful for simulations requiring regular or timed actions, such as periodic updates or repeated actions in the system.

- **Event Pausing (Wait)**  
  Temporarily pause the execution of an event for a specified duration. This is useful for simulating waiting times or delays between events in a process.

### Resources

- **Capacity-Limited Resources**
  A resource with a defined capacity, which limits how many events can access it simultaneously. When the resource is fully utilized, additional events must wait until capacity becomes available.

### Intervals

A collection of different interval types used to control event timing in simulations.

- **Fixed Interval**  
  A fixed interval where the duration between events is constant and does not change during the simulation.

- **Random Interval**  
  An interval where the duration is determined by a user-defined random function, offering variability in event timing.

- **Conditional Interval**  
  An interval where the duration depends on the state of the simulation at each step, allowing for dynamic adjustments based on conditions.

- **Probabilistic Interval**  
  An interval based on probabilistic distributions, introducing randomness with different statistical models.

  - **Uniform Distribution**  
    An interval where the duration is uniformly distributed between a minimum and maximum value, ensuring equal probability for all values within the range.

  - **Exponential Distribution**  
    An interval based on an exponential distribution, often used to model time between events in processes with constant rates.

  - **Normal (Gaussian) Distribution**  
    An interval modeled with a normal distribution, where durations are centered around a mean with a specified standard deviation, reflecting natural variance.

## Examples

### Processing events

```dart
import 'package:simdart/simdart.dart';

void main() async {
  final SimDart sim = SimDart();

  sim.process(event: _a, name: 'A');
  sim.process(event: _b, start: 5, name: 'B');

  await sim.run();
}

Future<void> _a(SimContext context) async {
  print('[${context.now}][${context.eventName}] start');
  await context.wait(10);
  context.process(event: _c, delay: 1, name: 'C');
  print('[${context.now}][${context.eventName}] end');
}

Future<void> _b(SimContext context) async {
  print('[${context.now}][${context.eventName}] start');
  await context.wait(1);
  print('[${context.now}][${context.eventName}] end');
}

Future<void> _c(SimContext context) async {
  print('[${context.now}][${context.eventName}] start');
  await context.wait(10);
  print('[${context.now}][${context.eventName}] end');
}
```

Output:
```
[0][A] start
[5][B] start
[6][B] end
[10][A] end
[11][C] start
[21][C] end
```

### Resource capacity

```dart
import 'package:simdart/simdart.dart';

void main() async {
  final SimDart sim = SimDart();

  sim.resources.limited(id: 'resource', capacity: 1);

  sim.process(event: _eventResource, name: 'A');
  sim.process(event: _eventResource, name: 'B');

  await sim.run();
}

Future<void> _eventResource(SimContext context) async {
  print('[${context.now}][${context.eventName}] acquiring resource...');
  await context.resources.acquire('resource');
  print('[${context.now}][${context.eventName}] resource acquired');
  await context.wait(10);
  print('[${context.now}][${context.eventName}] releasing resource...');
  context.resources.release('resource');
}

```

Output:
```
[0][A] acquiring resource...
[0][A] resource acquired
[0][B] acquiring resource...
[10][A] releasing resource...
[10][B] resource acquired
[20][B] releasing resource...
```

### Repeating process

```dart
import 'package:simdart/simdart.dart';

void main() async {
  final SimDart sim = SimDart();

  sim.repeatProcess(
          event: _a,
          start: 1,
          name: (start) => 'A$start',
          interval: Interval.fixed(fixedInterval: 2, untilTime: 5));

  await sim.run();
}

Future<void> _a(SimContext context) async {
  print('[${context.now}][${context.eventName}]');
}
```

Output:
```
[1][A1]
[3][A3]
[5][A5]
```