import 'package:daybook/core/network/mock/mock_settings.dart';
import 'package:flutter/material.dart';

class DevToolsPage extends StatefulWidget {
  const DevToolsPage({super.key, required this.settings});

  final MockSettings settings;

  @override
  State<DevToolsPage> createState() => _DevToolsPageState();
}

class _DevToolsPageState extends State<DevToolsPage> {
  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    return Scaffold(
      appBar: AppBar(title: const Text('Developer tools')),
      body: RadioGroup<ForcedError>(
        groupValue: s.forcedError,
        onChanged: (v) => setState(() => s.forcedError = v!),
        child: ListView(
          children: [
            ListTile(title: Text('Latency: ${s.latency.inMilliseconds} ms')),
            Slider(
              max: 3000,
              divisions: 30,
              value: s.latency.inMilliseconds.toDouble(),
              onChanged: (v) =>
                  setState(() => s.latency = Duration(milliseconds: v.round())),
            ),
            for (final e in ForcedError.values)
              RadioListTile<ForcedError>(title: Text(e.name), value: e),
          ],
        ),
      ),
    );
  }
}
