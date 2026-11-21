import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';

import 'app_update_http_stub.dart'
    if (dart.library.io) 'app_update_http_io.dart';

class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  bool _isChecking = false;
  bool _isDownloading = false;

  /// Guard: OTA updates are strictly supported on native Android
  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Semantic version comparison (v1 vs v2).
  /// Returns:
  ///   > 0 if v1 > v2
  ///   < 0 if v1 < v2
  ///   = 0 if v1 == v2
  static int compareVersions(String v1, String v2) {
    final cleanV1 = v1.trim().replaceFirst(RegExp(r'^[vV]'), '');
    final cleanV2 = v2.trim().replaceFirst(RegExp(r'^[vV]'), '');
    final parts1 = cleanV1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = cleanV2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final maxLength =
        parts1.length > parts2.length ? parts1.length : parts2.length;
    for (int i = 0; i < maxLength; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 != p2) return p1.compareTo(p2);
    }
    return 0;
  }

  /// Checks for application updates from GitHub Releases.
  /// [isManual]: When true, user-facing feedback is displayed for all outcomes.
  /// When false (quiet mode on startup), feedback is only displayed if an update is available.
  Future<void> checkForUpdates(
    BuildContext context, {
    required String currentVersion,
    bool isManual = false,
  }) async {
    if (!isSupported) return;
    if (_isChecking || _isDownloading) return;

    _isChecking = true;

    if (isManual && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Buscando actualización..."),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    try {
      final jsonStr = await fetchLatestReleaseJson();
      if (!context.mounted) return;

      if (jsonStr == null || jsonStr.isEmpty) {
        if (isManual) {
          _showMessageDialog(
            context,
            title: "Sin actualizaciones",
            message:
                "No se encontraron nuevas versiones disponibles o no fue posible conectar con el servidor.",
          );
        }
        return;
      }

      final Map<String, dynamic> releaseData =
          jsonDecode(jsonStr) as Map<String, dynamic>;
      final String rawTag =
          (releaseData['tag_name'] as String? ?? '').trim();
      final String remoteVersion =
          rawTag.replaceFirst(RegExp(r'^[vV]'), '');

      if (remoteVersion.isEmpty) {
        if (isManual) {
          _showMessageDialog(
            context,
            title: "Sin actualizaciones",
            message:
                "No se encontró información de versión en la última entrega.",
          );
        }
        return;
      }

      final int comparison = compareVersions(remoteVersion, currentVersion);
      if (comparison <= 0) {
        if (isManual) {
          _showMessageDialog(
            context,
            title: "App actualizada",
            message:
                "Tienes la versión más reciente instalada ($currentVersion).",
          );
        }
        return;
      }

      // Find APK asset
      final List<dynamic> assets =
          releaseData['assets'] as List<dynamic>? ?? [];
      String? apkUrl;
      for (final asset in assets) {
        if (asset is Map<String, dynamic>) {
          final name = (asset['name'] as String? ?? '').toLowerCase();
          final downloadUrl = asset['browser_download_url'] as String?;
          if (name.endsWith('.apk') &&
              downloadUrl != null &&
              downloadUrl.isNotEmpty) {
            apkUrl = downloadUrl;
            break;
          }
        }
      }

      if (apkUrl == null || apkUrl.isEmpty) {
        if (isManual) {
          _showMessageDialog(
            context,
            title: "Actualización detectada",
            message:
                "Se detectó la versión v$remoteVersion, pero el paquete de instalación para Android aún no está disponible para descarga.",
          );
        }
        return;
      }

      final releaseBody = (releaseData['body'] as String? ?? '').trim();

      _showUpdateAvailableDialog(
        context,
        remoteVersion: remoteVersion,
        currentVersion: currentVersion,
        releaseNotes: releaseBody,
        apkUrl: apkUrl,
      );
    } catch (e) {
      debugPrint("Error checking for updates: $e");
      if (isManual && context.mounted) {
        _showMessageDialog(
          context,
          title: "Error al verificar",
          message: "No se pudo verificar si hay actualizaciones: $e",
        );
      }
    } finally {
      _isChecking = false;
    }
  }

  void _showMessageDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
            width: 1.5,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.orange : const Color(0xFFC2410C),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: isDark ? Colors.white70 : const Color(0xFF334155),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              "Aceptar",
              style: TextStyle(
                color: isDark ? Colors.orange : const Color(0xFFC2410C),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateAvailableDialog(
    BuildContext context, {
    required String remoteVersion,
    required String currentVersion,
    required String releaseNotes,
    required String apkUrl,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
            width: 1.5,
          ),
        ),
        title: Row(
          children: [
            const Icon(Icons.system_update_rounded,
                color: Colors.orange, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Actualización disponible",
                style: TextStyle(
                  color: isDark ? Colors.orange : const Color(0xFFC2410C),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Nueva versión v$remoteVersion disponible.",
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Tu versión actual es v$currentVersion. ¿Deseas descargar e instalar la nueva versión ahora?",
                style: TextStyle(
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                  fontSize: 14,
                ),
              ),
              if (releaseNotes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black26
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: SingleChildScrollView(
                    child: Text(
                      releaseNotes,
                      style: TextStyle(
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              "Más tarde",
              style: TextStyle(
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _startOtaDownload(
                context,
                apkUrl: apkUrl,
                remoteVersion: remoteVersion,
              );
            },
            child: const Text(
              "Actualizar",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _startOtaDownload(
    BuildContext context, {
    required String apkUrl,
    required String remoteVersion,
  }) {
    if (!isSupported) return;

    _isDownloading = true;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        double progress = 0.0;
        String percentText = "0%";
        String statusMessage = "Iniciando descarga...";
        bool isError = false;
        bool isInstalling = false;
        StreamSubscription<OtaEvent>? subscription;

        return StatefulBuilder(
          builder: (builderCtx, setDialogState) {
            void cancelAndClose() {
              subscription?.cancel();
              _isDownloading = false;
              Navigator.of(dialogCtx).pop();
            }

            subscription ??= OtaUpdate().execute(
              apkUrl,
              destinationFilename: 'mi-nomina-pro.apk',
            ).listen(
              (OtaEvent event) {
                switch (event.status) {
                  case OtaStatus.DOWNLOADING:
                    final double? parsedVal =
                        double.tryParse(event.value ?? '0');
                    final double clamped =
                        ((parsedVal ?? 0.0) / 100.0).clamp(0.0, 1.0);
                    setDialogState(() {
                      progress = clamped;
                      percentText = "${(clamped * 100).toInt()}%";
                      statusMessage = "Descargando paquete de actualización...";
                    });
                    break;
                  case OtaStatus.INSTALLING:
                    setDialogState(() {
                      progress = 1.0;
                      percentText = "100%";
                      isInstalling = true;
                      statusMessage = "Preparando e iniciando instalador...";
                    });
                    break;
                  case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
                    setDialogState(() {
                      isError = true;
                      statusMessage =
                          "Permiso denegado: debes permitir la instalación de aplicaciones desconocidas en los Ajustes del sistema.";
                    });
                    _isDownloading = false;
                    break;
                  case OtaStatus.ALREADY_RUNNING_ERROR:
                    setDialogState(() {
                      isError = true;
                      statusMessage = "Ya hay una descarga en curso.";
                    });
                    _isDownloading = false;
                    break;
                  case OtaStatus.DOWNLOAD_ERROR:
                    setDialogState(() {
                      isError = true;
                      statusMessage =
                          "Error al descargar la actualización (${event.value ?? 'Fallo de red'}).";
                    });
                    _isDownloading = false;
                    break;
                  case OtaStatus.CHECKSUM_ERROR:
                    setDialogState(() {
                      isError = true;
                      statusMessage =
                          "Error de suma de verificación en el archivo descargado.";
                    });
                    _isDownloading = false;
                    break;
                  case OtaStatus.INTERNAL_ERROR:
                    setDialogState(() {
                      isError = true;
                      statusMessage =
                          "Error interno en la actualización: ${event.value ?? ''}";
                    });
                    _isDownloading = false;
                    break;
                  case OtaStatus.CANCELED:
                    setDialogState(() {
                      isError = true;
                      statusMessage = "La descarga fue cancelada.";
                    });
                    _isDownloading = false;
                    break;
                }
              },
              onError: (dynamic error) {
                setDialogState(() {
                  isError = true;
                  statusMessage = "Error inesperado durante la descarga: $error";
                });
                _isDownloading = false;
              },
              onDone: () {
                _isDownloading = false;
              },
            );

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
              ),
              title: Row(
                children: [
                  const Icon(Icons.downloading_rounded,
                      color: Colors.orange, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isInstalling
                          ? "Instalando..."
                          : (isError
                              ? "Aviso de actualización"
                              : "Actualizando App"),
                      style: TextStyle(
                        color: isDark ? Colors.orange : const Color(0xFFC2410C),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Versión v$remoteVersion",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!isError) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: isInstalling ? null : progress,
                        minHeight: 10,
                        backgroundColor: Colors.orange.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            statusMessage,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white60
                                  : const Color(0xFF64748B),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (!isInstalling)
                          Text(
                            percentText,
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: Colors.redAccent, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              statusMessage,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.red[200]
                                    : const Color(0xFFB91C1C),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                if (isError || isInstalling)
                  TextButton(
                    onPressed: cancelAndClose,
                    child: Text(
                      "Cerrar",
                      style: TextStyle(
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
