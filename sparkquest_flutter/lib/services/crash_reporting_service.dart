import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'storage_service.dart';
import 'supabase_service.dart';

/// Captures uncaught Flutter framework errors, async platform errors, and manual
/// diagnostic breadcrumbs, queuing them locally in SharedPreferences and
/// flushing structured telemetry to Supabase `public.analytics_events`.
class CrashReportingService {
  static final CrashReportingService instance = CrashReportingService._internal();
  CrashReportingService._internal();

  bool _initialized = false;
  bool _isRecording = false;
  int _sessionErrorCount = 0;
  DateTime? _lastRecordedAt;

  bool get isInitialized => _initialized;
  int get sessionErrorCount => _sessionErrorCount;

  /// Installs global FlutterError, PlatformDispatcher, and ErrorWidget handlers,
  /// then attempts to flush any crash reports queued during prior offline runs.
  Future<void> initialize({bool installGlobalHandlers = true}) async {
    if (_initialized) return;
    _initialized = true;

    await StorageService.instance.init();

    final isTestBinding =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');

    if (installGlobalHandlers && !isTestBinding) {
      final previousFlutterHandler = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        previousFlutterHandler?.call(details);
        unawaited(recordError(
          details.exception,
          details.stack,
          source: 'flutter_framework',
          fatal: !details.silent,
          context: {
            if (details.library != null) 'library': details.library,
            if (details.context != null)
              'context': details.context!.toDescription(),
          },
        ));
      };

      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        unawaited(recordError(
          error,
          stack,
          source: 'platform_dispatcher',
          fatal: true,
        ));
        return true;
      };

      ErrorWidget.builder = buildErrorFallbackWidget;
    }

    if (!isTestBinding) {
      unawaited(flushPendingReports());
    }
  }

  /// Records a structured diagnostic or crash payload locally and sends it to
  /// Supabase `analytics_events` (`event_name: 'crash_report'`).
  Future<bool> recordError(
    Object error,
    StackTrace? stack, {
    String source = 'manual',
    bool fatal = false,
    Map<String, dynamic>? context,
    bool skipUpload = false,
  }) async {
    if (_isRecording) return false;
    final now = DateTime.now().toUtc();
    if (_lastRecordedAt != null &&
        now.difference(_lastRecordedAt!).inMilliseconds < 250 &&
        _sessionErrorCount > 10) {
      return false;
    }

    _isRecording = true;
    _lastRecordedAt = now;
    _sessionErrorCount++;

    try {
      await StorageService.instance.init();

      final stackLines = (stack ?? StackTrace.current)
          .toString()
          .split('\n')
          .take(12)
          .join('\n');

      final entry = <String, dynamic>{
        'timestamp': now.toIso8601String(),
        'source': source,
        'fatal': fatal,
        'error': _truncate(error.toString(), 400),
        'stack': _truncate(stackLines, 1600),
        'platform': defaultTargetPlatform.name,
        'build_mode': kReleaseMode
            ? 'release'
            : (kProfileMode ? 'profile' : 'debug'),
        'app_version': '2.1.0+17',
        'synced': false,
        if (context != null && context.isNotEmpty) 'context': context,
      };

      bool uploaded = false;
      if (!skipUpload) {
        uploaded = await SupabaseService.instance.logAnalyticsEvent(
          eventName: 'crash_report',
          properties: {
            ...entry,
            'synced': true,
          },
        );
      }

      entry['synced'] = uploaded;
      await StorageService.instance.appendCrashLog(entry);
      return uploaded;
    } finally {
      _isRecording = false;
    }
  }

  /// Sends a non-fatal diagnostic breadcrumb so users/reviewers can verify telemetry.
  Future<bool> sendTestDiagnosticPing() async {
    return recordError(
      'SparkQuest Diagnostic Health Check (Manual Ping)',
      StackTrace.current,
      source: 'diagnostics_ping',
      fatal: false,
      context: {'trigger': 'settings_diagnostics_viewer'},
    );
  }

  /// Attempts to upload any locally queued crash reports that have not been synced.
  Future<int> flushPendingReports() async {
    await StorageService.instance.init();
    final logs = StorageService.instance.getCrashLogs();
    final unsynced = logs.where((item) => item['synced'] != true).toList();
    if (unsynced.isEmpty) return 0;

    int flushed = 0;
    for (final entry in unsynced) {
      final ok = await SupabaseService.instance.logAnalyticsEvent(
        eventName: 'crash_report',
        properties: {
          ...entry,
          'flushed_retry': true,
        },
      );
      if (ok) {
        flushed++;
      }
    }

    if (flushed > 0) {
      await StorageService.instance.markCrashLogsSynced();
    }
    return flushed;
  }

  List<Map<String, dynamic>> getRecentLogs() =>
      StorageService.instance.getCrashLogs();

  Future<void> clearLogs() => StorageService.instance.clearCrashLogs();

  static String _truncate(String value, int maxLen) =>
      value.length <= maxLen ? value : value.substring(0, maxLen);

  /// Recovery widget rendered when an individual widget subtree throws during build.
  static Widget buildErrorFallbackWidget(FlutterErrorDetails details) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF15192B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFF3D68).withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shield_outlined,
            color: Color(0xFFFF3D68),
            size: 28,
          ),
          const SizedBox(height: 8),
          const Text(
            'SparkQuest Shield Caught a Glitch',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            kDebugMode
                ? details.exceptionAsString()
                : 'This card hit an unexpected render issue and was isolated safely.',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF9EA6C3),
              fontSize: 12,
              fontWeight: FontWeight.normal,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}
