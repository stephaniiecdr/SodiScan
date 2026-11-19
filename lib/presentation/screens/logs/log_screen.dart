import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/logging/app_log.dart';
import '../../../core/logging/log_entry.dart';
import '../../../core/logging/log_store.dart';
import '../../../core/utils/date_format.dart';
import '../../widgets/adaptive_layout.dart';
import '../../widgets/state_message.dart';

/// Menampilkan log aplikasi agar masalah saat aplikasi berjalan bisa
/// ditelusuri langsung di HP, lalu disalin untuk dikirim ke pengembang.
class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  static const String copiedText = 'Log disalin ke clipboard.';
  static const String clearedText = 'Log dihapus.';

  static Route<void> route(BuildContext context) {
    final store = context.read<LogStore>();
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/logs'),
      builder: (_) => Provider.value(value: store, child: const LogScreen()),
    );
  }

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  LogLevel _minLevel = LogLevel.debug;
  List<LogEntry> _entries = const [];

  LogStore get _store => context.read<LogStore>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reload();
  }

  void _reload() => setState(() => _entries = _store.readAll().reversed.toList());

  List<LogEntry> get _visible => _entries.where((entry) => entry.level.index >= _minLevel.index).toList();

  Future<void> _copy() async {
    final text = _visible.reversed.map((entry) => entry.format(withStackTrace: true)).join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    _showMessage(LogScreen.copiedText);
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus semua log?'),
        content: const Text('Log yang dihapus tidak dapat dikembalikan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _store.clear();
    AppLog.i('Log', 'Log dihapus oleh pengguna');
    _reload();
    _showMessage(LogScreen.clearedText);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Aplikasi'),
        actions: [
          IconButton(tooltip: 'Muat ulang', icon: const Icon(Icons.refresh), onPressed: _reload),
          IconButton(tooltip: 'Salin log', icon: const Icon(Icons.copy), onPressed: visible.isEmpty ? null : _copy),
          IconButton(tooltip: 'Hapus log', icon: const Icon(Icons.delete_outline), onPressed: _entries.isEmpty ? null : _clear),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: adaptivePadding(context, base: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final level in LogLevel.values)
                  ChoiceChip(
                    key: Key('logFilter_${level.name}'),
                    label: Text(level == LogLevel.debug ? 'Semua' : '≥ ${level.label}'),
                    selected: _minLevel == level,
                    onSelected: (_) => setState(() => _minLevel = level),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: visible.isEmpty
                ? const Center(
                    child: StateMessage(
                      icon: Icons.receipt_long_outlined,
                      title: 'Belum Ada Log',
                      message: 'Log aktivitas dan error aplikasi akan muncul di sini.',
                    ),
                  )
                : ListView.separated(
                    padding: adaptivePadding(context, base: 0),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, index) => _LogTile(entry: visible[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.entry});

  final LogEntry entry;

  Color _color(ColorScheme scheme) => switch (entry.level) {
        LogLevel.debug => scheme.outline,
        LogLevel.info => scheme.primary,
        LogLevel.warning => Colors.orange.shade800,
        LogLevel.error => scheme.error,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color(Theme.of(context).colorScheme);
    final detail = [if (entry.error != null) entry.error!, '${formatDateId(entry.time)} ${formatTimeId(entry.time)}'].join('\n');

    return ListTile(
      dense: true,
      leading: Text(entry.level.label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      title: Text('${entry.tag}: ${entry.message}'),
      subtitle: Text(detail),
    );
  }
}
