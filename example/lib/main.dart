import 'package:flutter/material.dart';
import 'package:hardware_scanner_input/hardware_scanner_input.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HardwareScannerInput example',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const ScannerScreen(),
    );
  }
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _scans = <String>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hardware scanner demo')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Bottom layer always holds focus — invisible to the user.
          HardwareScannerInput(
            onScanned: (value) => setState(() => _scans.insert(0, value)),
          ),
          // Visible UI on top.
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.qr_code_scanner),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Trigger your hardware scanner — scans appear '
                            'below. The on-screen keyboard never opens.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _scans.isEmpty
                      ? const Center(child: Text('No scans yet.'))
                      : ListView.separated(
                          itemCount: _scans.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) => ListTile(
                            leading: const Icon(Icons.barcode_reader),
                            title: Text(_scans[i]),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
