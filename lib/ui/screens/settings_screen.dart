import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapes/constants/app_colors.dart';
import 'package:tapes/ui/widgets/retro_screen_header.dart';
import 'package:tapes/services/notion/client.dart';
import 'package:tapes/viewmodels/notion_settings_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final NotionSettingsController _controller;
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _databaseController = TextEditingController();

  bool _obscureToken = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = context.read<NotionSettingsController>();
    _databaseController.text = _controller.databaseId;
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _databaseController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _controller.validateAndSave(
        token: _tokenController.text,
        rawDatabaseId: _databaseController.text,
      );
      _tokenController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Koneksi Notion berhasil')),
      );
    } on NotionApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = _messageFor(error));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Tidak dapat terhubung ke Notion');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _disconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Putuskan koneksi?'),
        content: const Text(
          'Token, pengaturan, dan cache skema Notion akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Putuskan'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _controller.disconnect();
    _tokenController.clear();
    _databaseController.clear();
    if (!mounted) return;
    setState(() => _error = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Koneksi Notion diputuskan')),
    );
  }

  String _messageFor(NotionApiException error) {
    return switch (error.statusCode) {
      401 => 'Token salah atau kedaluwarsa',
      403 => 'Integrasi Notion belum di-share ke database ini',
      404 => 'Database ID tidak ditemukan',
      429 => 'Terlalu banyak permintaan, coba lagi nanti',
      _ => error.message,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final connected = _controller.isConfigured && _controller.isConnected;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RetroScreenHeader(title: 'Setting Your Tape'),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    children: [
                      _StatusChip(
                        connected: connected,
                        hasError: _error != null,
                        databaseName: _controller.databaseName,
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.tapeGold,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _tokenController,
                              obscureText: _obscureToken,
                              decoration: InputDecoration(
                                labelText: 'Token Notion',
                                hintText: _controller.hasStoredToken
                                    ? 'Token tersimpan'
                                    : 'Masukkan token integrasi',
                                filled: true,
                                fillColor: AppColors.tapeInset,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureToken
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureToken = !_obscureToken,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _databaseController,
                              decoration: InputDecoration(
                                labelText: 'Database ID',
                                helperText: 'ID atau URL database Notion',
                                filled: true,
                                fillColor: AppColors.tapeInset,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _loading ? null : _testConnection,
                              child: _loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Test Connection & Sync Schema',
                                    ),
                            ),
                          ],
                        ),
                      ),
                      if (_controller.hasStoredToken ||
                          _controller.isConfigured)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: OutlinedButton(
                            onPressed: _loading ? null : _disconnect,
                            child: const Text('Putuskan Koneksi / Reset'),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool connected;
  final bool hasError;
  final String? databaseName;

  const _StatusChip({
    required this.connected,
    required this.hasError,
    required this.databaseName,
  });

  @override
  Widget build(BuildContext context) {
    final color = hasError
        ? Colors.red
        : connected
        ? Colors.green
        : Colors.grey;
    final label = hasError
        ? 'Error'
        : connected
        ? 'Terhubung${databaseName == null ? '' : ': $databaseName'}'
        : 'Belum Terhubung';

    return Row(
      children: [
        Icon(Icons.circle, size: 12, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
      ],
    );
  }
}
