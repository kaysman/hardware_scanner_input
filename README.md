# hardware_scanner_input

[![pub package](https://img.shields.io/pub/v/hardware_scanner_input.svg)](https://pub.dev/packages/hardware_scanner_input)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A Flutter widget that captures input from **HID-mode hardware barcode scanners**
on Android without surfacing the software keyboard.

## Why does this package exist?

Most industrial Android tablets (iData P1, Zebra TC, Honeywell CT, etc.) ship
paired with a hardware barcode scanner running in **HID / Focus mode**. In that
mode the scanner is _not_ a USB serial device — it injects each scanned
character into the currently focused Android `InputConnection` via
`commitText()`, then sends an Enter key. **The only way to receive scans is to
keep a focused text input alive.**

Naively dropping a `TextField` on the page is wrong:

1. The on-screen keyboard pops up, covering your UI.
2. Some scanner models omit the trailing Enter — `onSubmitted` never fires and
   the value is stuck in the controller.

`HardwareScannerInput` fixes both, in 110 lines:

- `keyboardType: TextInputType.none` keeps the soft keyboard hidden while the
  field retains a live `InputConnection`.
- A configurable silence timeout (default **150 ms**) flushes the buffered
  text once the scanner stops streaming characters, with or without Enter.
- The text is rendered transparent and 1 px tall so the widget stacks
  invisibly behind your real scan-indicator UI.

## Install

```sh
flutter pub add hardware_scanner_input
```

## Usage

Stack it behind your visual scan indicator:

```dart
import 'package:flutter/material.dart';
import 'package:hardware_scanner_input/hardware_scanner_input.dart';

class ScanStep extends StatelessWidget {
  const ScanStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        HardwareScannerInput(
          onScanned: (value) => debugPrint('scanned: $value'),
        ),
        const IgnorePointer(child: _ScanReadyIndicator()),
      ],
    );
  }
}
```

For a full-page scan screen, place `HardwareScannerInput` as the bottom-most
child of the page `Stack` so it always holds focus.

### API

| Parameter | Type | Default | Notes |
|---|---|---|---|
| `onScanned` | `void Function(String)` | — | Fires once per complete scan. Trimmed; empty scans are dropped. |
| `focusNode` | `FocusNode?` | `null` | Inject your own when managing focus yourself. |
| `autofocus` | `bool` | `true` | Whether the field claims focus on insert. |
| `silenceTimeout` | `Duration` | `150 ms` | How long to wait after the last character before flushing. |

## How it works under the hood

```
Scanner trigger
   │
   ▼
Android InputMethodManager.commitText()
   │
   ▼
TextField.onChanged (per character)
   │
   └─► reset 150 ms timer ─► onSubmitted (Enter received)? flush.
                          └─► timer fires? flush.
```

`TextInputType.none` maps to `TYPE_NULL` on the Android side, which is the
documented way to suppress the IME while keeping a working
`InputConnection`. Tested on Android 11–14.

## Testing

The widget is exercised with `WidgetTester.enterText` and the test pump
clock — see [`test/hardware_scanner_input_test.dart`](test/hardware_scanner_input_test.dart).

```sh
flutter test
```

## Example app

The [`example/`](example) directory contains a runnable demo screen.

```sh
cd example
flutter run
```

## License

MIT — see [LICENSE](LICENSE).
