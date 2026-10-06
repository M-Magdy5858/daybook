import 'package:daybook/core/network/mock/mock_server_state.dart';
import 'package:daybook/core/network/mock/mock_settings.dart';
import 'package:daybook/shared/extensions/context_extensions.dart';
import 'package:flutter/material.dart';

class DevToolsPage extends StatefulWidget {
  const DevToolsPage({super.key, required this.settings, required this.server});

  final MockSettings settings;
  final MockServerState server;

  @override
  State<DevToolsPage> createState() => _DevToolsPageState();
}

class _DevToolsPageState extends State<DevToolsPage> {
  /// Lets you pick a server task and changes it "on another device".
  Future<void> _simulateServerEdit() async {
    final tasks = widget.server.tasks.values.toList()
      ..sort((a, b) => '${b['updatedAt']}'.compareTo('${a['updatedAt']}'));
    final id = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Edit which task on the server?'),
        children: [
          for (final t in tasks.take(20))
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, t['id'] as String),
              child: Text('${t['title']}  (v${t['version']})'),
            ),
        ],
      ),
    );
    if (id == null || !mounted) return;
    widget.server.simulateServerEdit(id);
    context.showSnack('Changed on the server. Edit it in the app to conflict.');
  }

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
            SwitchListTile(
              title: const Text('Offline'),
              subtitle: const Text('Every request fails to connect'),
              value: s.offline,
              onChanged: (v) => setState(() => s.offline = v),
            ),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Simulate server edit'),
              subtitle: const Text('Change a task as if from another device'),
              onTap: _simulateServerEdit,
            ),
            const Divider(),
            const ListTile(title: Text('Forced error')),
            for (final e in ForcedError.values)
              RadioListTile<ForcedError>(title: Text(e.name), value: e),
          ],
        ),
      ),
    );
  }
}
