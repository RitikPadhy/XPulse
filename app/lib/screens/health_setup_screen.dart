import 'package:flutter/material.dart';

import '../core/services/health_service.dart';
import '../core/services/storage_service.dart';
import '../core/services/sync_service.dart';

/// Dev/setup screen for HealthKit token + permissions + manual sync.
///
/// Temporary: surfaced as a tab while wiring is in development. Will be
/// folded into the home flow once foreground sync is proven end-to-end.
class HealthSetupScreen extends StatefulWidget {
  const HealthSetupScreen({super.key});

  @override
  State<HealthSetupScreen> createState() => _HealthSetupScreenState();
}

class _HealthSetupScreenState extends State<HealthSetupScreen> {
  final _storage = StorageService.instance;
  final _health = HealthService();
  late final _sync = SyncService(health: _health, storage: _storage);
  final _tokenController = TextEditingController();

  bool? _hasToken;
  bool? _hasPermissions;
  DateTime? _lastSync;
  String _status = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final token = await _storage.getApiToken();
    final perms = await _health.hasAllPermissions();
    final lastSync = await _storage.getLastSyncAt();
    if (!mounted) return;
    setState(() {
      _hasToken = token != null && token.isNotEmpty;
      _hasPermissions = perms;
      _lastSync = lastSync;
    });
  }

  Future<void> _saveToken() async {
    final t = _tokenController.text.trim();
    if (t.isEmpty) return;
    await _storage.setApiToken(t);
    _tokenController.clear();
    setState(() => _status = 'token saved');
    await _refresh();
  }

  Future<void> _clearToken() async {
    await _storage.clearApiToken();
    setState(() => _status = 'token cleared');
    await _refresh();
  }

  Future<void> _requestPermissions() async {
    setState(() => _busy = true);
    try {
      await _health.requestPermissions();
      setState(() => _status = 'permission sheet shown');
    } finally {
      if (mounted) setState(() => _busy = false);
      await _refresh();
    }
  }

  Future<void> _resetSyncState() async {
    await _storage.resetSyncState();
    setState(() => _status = 'sync state cleared — next sync will refetch last 24h');
    await _refresh();
  }

  Future<void> _syncNow() async {
    setState(() {
      _busy = true;
      _status = 'syncing…';
    });
    try {
      final result = await _sync.syncOnce();
      setState(() => _status = result.ok
          ? 'fetched ${result.fetched}, '
              'inserted ${result.inserted}, '
              'duplicates ${result.duplicates}'
          : 'fetched ${result.fetched}, queued ${result.queued} (error: ${result.error})');
    } catch (e) {
      setState(() => _status = 'error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Health setup', style: TextStyle(fontFamily: 'Courier', letterSpacing: 2)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _statusRow('API token', _hasToken == true ? 'configured' : 'missing'),
              if (_hasToken != true) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _tokenController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Paste API token',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: _saveToken, child: const Text('Save token')),
              ] else
                TextButton(onPressed: _clearToken, child: const Text('Clear token')),
              const Divider(height: 32),
              _statusRow(
                'HealthKit',
                _hasPermissions == true
                    ? 'granted (best-known)'
                    : _hasPermissions == false
                        ? 'not granted'
                        : 'unknown (iOS hides this)',
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _busy ? null : _requestPermissions,
                child: const Text('Request permissions'),
              ),
              const Divider(height: 32),
              _statusRow(
                'Last sync',
                _lastSync == null ? 'never' : _lastSync!.toLocal().toString(),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _busy ? null : _syncNow,
                child: const Text('Sync now'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : _resetSyncState,
                child: const Text('Reset sync state (refetch last 24h)'),
              ),
              const SizedBox(height: 24),
              Text(_status, style: const TextStyle(fontFamily: 'Courier')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Courier', letterSpacing: 2)),
        Text(value, style: const TextStyle(fontFamily: 'Courier')),
      ],
    );
  }
}
