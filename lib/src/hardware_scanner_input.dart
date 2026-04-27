import 'dart:async';

import 'package:flutter/material.dart';

/// A full-size transparent text field that captures hardware barcode-scanner
/// input on Android without surfacing the software keyboard.
///
/// ## Why this exists
///
/// Many industrial Android tablets ship paired with a hardware barcode scanner
/// running in **HID / Focus mode** (e.g. iData P1, Zebra TC, Honeywell CT).
/// In this mode the scanner is not a USB serial device — it injects barcode
/// characters into the currently focused Android `InputConnection` via
/// `commitText()`, then sends an Enter key. There is no SDK to listen on:
/// the only way to receive scans is to keep a focused text input alive.
///
/// Naively dropping a `TextField` on the page causes two problems:
/// 1. The on-screen keyboard appears whenever the field has focus, covering
///    the UI.
/// 2. Some scanner models omit the trailing Enter, so `onSubmitted` never
///    fires and the value sits in the controller indefinitely.
///
/// [HardwareScannerInput] solves both:
/// - `keyboardType: TextInputType.none` keeps the soft keyboard hidden while
///   the field still holds a real `InputConnection`.
/// - A 150 ms silence timeout flushes the buffered text when no more
///   characters arrive, regardless of whether the scanner sent Enter.
/// - The text is rendered transparent and sized 1 px so the widget can be
///   stacked invisibly behind your scan-indicator UI.
///
/// ## Typical usage
///
/// Stack it behind your visual scan indicator:
///
/// ```dart
/// SizedBox(
///   height: 150,
///   child: Stack(
///     fit: StackFit.expand,
///     children: [
///       HardwareScannerInput(onScanned: (v) => debugPrint('scanned: $v')),
///       const IgnorePointer(child: ScanReadyIndicator()),
///     ],
///   ),
/// )
/// ```
///
/// For full-bleed pages place it as the bottom-most layer of the page
/// [Stack] so it always holds focus.
class HardwareScannerInput extends StatefulWidget {
  /// Creates a [HardwareScannerInput].
  const HardwareScannerInput({
    required this.onScanned,
    this.focusNode,
    this.autofocus = true,
    this.silenceTimeout = const Duration(milliseconds: 150),
    super.key,
  });

  /// Called with the decoded string value when a scan completes.
  ///
  /// Whitespace is trimmed before this callback fires. Empty scans are
  /// dropped and never delivered.
  final void Function(String value) onScanned;

  /// Optional external focus node. When provided the widget uses it directly;
  /// otherwise an internal node is created and managed automatically.
  final FocusNode? focusNode;

  /// Whether this field should claim focus immediately when inserted.
  ///
  /// Defaults to `true`. Set to `false` when you manage focus yourself
  /// (e.g. switching focus between several scanner inputs).
  final bool autofocus;

  /// How long to wait after the last received character before flushing the
  /// buffered value to [onScanned].
  ///
  /// Defaults to 150 ms, which is comfortably longer than the inter-character
  /// gap of every scanner the author has tested. Increase if your scanner
  /// streams characters slowly; decrease if you need faster scan turnaround
  /// and your scanner reliably sends Enter.
  final Duration silenceTimeout;

  @override
  State<HardwareScannerInput> createState() => _HardwareScannerInputState();
}

class _HardwareScannerInputState extends State<HardwareScannerInput> {
  final _controller = TextEditingController();
  FocusNode? _internalFocusNode;
  Timer? _timer;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _timer?.cancel();
    _timer = Timer(widget.silenceTimeout, () => _flush(_controller.text));
  }

  void _onSubmitted(String value) {
    _timer?.cancel();
    _flush(value);
  }

  void _flush(String raw) {
    final value = raw.trim();
    _controller.clear();
    if (value.isEmpty) return;
    widget.onScanned(value);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      // TYPE_NULL on Android: keeps the InputConnection alive but never
      // surfaces the software keyboard.
      keyboardType: TextInputType.none,
      showCursor: false,
      enableInteractiveSelection: false,
      style: const TextStyle(color: Colors.transparent, fontSize: 1),
      decoration: const InputDecoration.collapsed(hintText: ''),
      onChanged: _onChanged,
      onSubmitted: _onSubmitted,
    );
  }
}
