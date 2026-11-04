import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../presentation/queue_presentation.dart';

KeyEventResult handleQueueShortcut(KeyEvent event, {required QueueBloc bloc}) {
  if (event is! KeyDownEvent) return KeyEventResult.ignored;
  if (FocusManager.instance.primaryFocus?.context?.widget is EditableText) {
    return KeyEventResult.ignored;
  }
  final snapshot = bloc.state.snapshot;
  if (snapshot == null || bloc.state.busy) return KeyEventResult.ignored;
  final key = event.logicalKey;
  final ctrl = HardwareKeyboard.instance.isControlPressed;
  if (ctrl && key == LogicalKeyboardKey.keyR) {
    bloc.add(const LoadQueue());
    return KeyEventResult.handled;
  }
  final entries = queueEntriesForDisplay(snapshot);
  final selected = entries
      .where((e) => e.id == bloc.state.selectedId)
      .firstOrNull;
  if (ctrl && key == LogicalKeyboardKey.enter && selected != null) {
    final target = primaryActionForEntry(selected, bloc.actor);
    if (target != null) bloc.add(ChangeEntry(selected, target));
    return KeyEventResult.handled;
  }
  if (key == LogicalKeyboardKey.arrowDown ||
      key == LogicalKeyboardKey.arrowUp) {
    if (entries.isEmpty) return KeyEventResult.handled;
    final current = entries.indexWhere((e) => e.id == bloc.state.selectedId);
    final next = current < 0
        ? 0
        : (current + (key == LogicalKeyboardKey.arrowDown ? 1 : -1)).clamp(
            0,
            entries.length - 1,
          );
    bloc.add(SelectEntry(entries[next].id));
    return KeyEventResult.handled;
  }
  if (key == LogicalKeyboardKey.enter &&
      selected == null &&
      entries.isNotEmpty) {
    bloc.add(SelectEntry(entries.first.id));
    return KeyEventResult.handled;
  }
  if (key == LogicalKeyboardKey.escape) {
    bloc.add(const SelectEntry(null));
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
}
