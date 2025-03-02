import 'package:meta/meta.dart';
import 'package:simdart/src/internal/time_action.dart';
import 'package:simdart/src/simdart.dart';

@internal
class StopAction extends TimeAction{

  StopAction({required super.start, super.order=-1, required this.sim});

  final SimDart sim;

  @override
  void execute() {
    print('entrou no stopAction');
    SimDartHelper.stop(sim: sim);
    SimDartHelper.scheduleNextAction(sim: sim);
  }

}