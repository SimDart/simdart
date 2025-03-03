import 'package:meta/meta.dart';

@internal
abstract class DebugListener {
  void onAddCompleter();

  void onRemoveCompleter();
}
