import 'package:simdart/src/sim_counter.dart';
import 'package:simdart/src/sim_num.dart';
import 'package:test/test.dart';

void main() {
  group('SimCounter', () {
    late SimCounter counter;

    setUp(() {
      counter = SimCounter(name: 'Test Counter');
    });

    test('Initial count should be 0', () {
      expect(counter.value, 0);
    });

    test('Increment should increase count by 1', () {
      counter.inc();
      expect(counter.value, 1);
    });

    test('Increment by value should increase count by specified amount', () {
      counter.incBy(5);
      expect(counter.value, 5);
    });

    test('Increment by negative value should not change count', () {
      counter.incBy(-3);
      expect(counter.value, 0);
    });

    test('Reset should set count to 0', () {
      counter.incBy(10);
      counter.reset();
      expect(counter.value, 0);
    });
  });
  group('SimNum', () {
    late SimNum metric;

    setUp(() {
      metric = SimNum(name: 'Test Metric');
    });

    test('Initial value should be null', () {
      expect(metric.value, isNull);
    });

    test('Setting value should update current value', () {
      metric.value = 10.0;
      expect(metric.value, 10.0);
    });

    test('Setting null value should not update min, max, or average', () {
      metric.value = 10.0;
      metric.value = null;
      expect(metric.min, 10.0);
      expect(metric.max, 10.0);
      expect(metric.average, 10.0);
    });

    test('Min and max should track smallest and largest values', () {
      metric.value = 10.0;
      metric.value = 5.0;
      metric.value = 15.0;
      expect(metric.min, 5.0);
      expect(metric.max, 15.0);
    });

    test('Average should calculate correctly', () {
      metric.value = 10.0;
      metric.value = 20.0;
      metric.value = 30.0;
      expect(metric.average, 20.0);
    });

    test('Variance should calculate correctly', () {
      metric.value = 10.0;
      metric.value = 20.0;
      metric.value = 30.0;
      expect(metric.variance, closeTo(66.666, 0.001));
    });

    test('Standard deviation should calculate correctly', () {
      metric.value = 10.0;
      metric.value = 20.0;
      metric.value = 30.0;
      expect(metric.standardDeviation, closeTo(8.164, 0.001));
    });

    test('Rate', () {
      metric.value = 10.0;
      expect(0.1, metric.rate(100));
    });

    test('Reset should clear all values', () {
      metric.value = 10.0;
      metric.reset();
      expect(metric.value, isNull);
      expect(metric.min, isNull);
      expect(metric.max, isNull);
      expect(metric.average, isNull);
    });
  });
}
