import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:abpos/services/update_service.dart';

/// GetX controller that manages OTA update state, including checking,
/// downloading, and triggering the install prompt.
class UpdateController extends GetxController {
  // ---------------------------------------------------------------------------
  // Observable state
  // ---------------------------------------------------------------------------

  /// `true` while we're fetching release info from GitHub.
  final isChecking = false.obs;

  /// `true` while an APK is being downloaded.
  final isDownloading = false.obs;

  /// Download progress 0.0 – 1.0.
  final downloadProgress = 0.0.obs;

  /// `true` when a newer version is available.
  final updateAvailable = false.obs;

  /// The current app version string (e.g. "1.0.0").
  final currentVersion = ''.obs;

  /// Information about the latest remote release (nullable).
  final Rx<ReleaseInfo?> latestRelease = Rx<ReleaseInfo?>(null);

  /// Path to the downloaded APK on disk.
  final downloadedApkPath = ''.obs;

  /// Whether the APK has finished downloading and is ready to install.
  final isReadyToInstall = false.obs;

  /// Error message (empty when no error).
  final errorMessage = ''.obs;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    _loadCurrentVersion();
    _checkPendingUpdate();
  }

  Future<void> _loadCurrentVersion() async {
    currentVersion.value = await UpdateService.getCurrentVersion();
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Checks GitHub for a new release. If one is found and is newer than the
  /// current version, sets [updateAvailable] to `true`.
  Future<void> checkForUpdate({bool silent = false}) async {
    errorMessage.value = '';
    isChecking.value = true;

    try {
      final errorBuf = StringBuffer();
      final release = await UpdateService.fetchLatestRelease(error: errorBuf);
      if (release == null) {
        if (!silent) {
          final reason = errorBuf.toString();
          if (reason == 'no_apk_asset') {
            errorMessage.value = 'no_apk_in_release'.tr;
          } else if (reason == 'no_releases') {
            errorMessage.value = 'no_releases_found'.tr;
          } else if (reason.isNotEmpty) {
            errorMessage.value = '${'update_check_failed'.tr} ($reason)';
          } else {
            errorMessage.value = 'update_check_failed'.tr;
          }
        }
        isChecking.value = false;
        return;
      }

      latestRelease.value = release;

      final current = currentVersion.value;
      if (UpdateService.isNewer(release.version, current)) {
        updateAvailable.value = true;
      } else {
        updateAvailable.value = false;
        if (!silent) {
          Get.snackbar(
            'update'.tr,
            'already_latest_version'.tr,
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(16),
          );
        }
      }
    } catch (e) {
      if (!silent) {
        errorMessage.value = 'update_check_failed'.tr;
      }
    } finally {
      isChecking.value = false;
    }
  }

  /// Downloads the APK of the latest release. On success, saves it as a
  /// pending update so it re-appears on next launch if dismissed.
  Future<void> downloadUpdate() async {
    final release = latestRelease.value;
    if (release == null) return;

    errorMessage.value = '';
    isDownloading.value = true;
    downloadProgress.value = 0.0;
    isReadyToInstall.value = false;

    try {
      final path = await UpdateService.downloadApk(
        release.apkDownloadUrl,
        onProgress: (p) => downloadProgress.value = p,
      );

      if (path == null) {
        errorMessage.value = 'download_failed'.tr;
        isDownloading.value = false;
        return;
      }

      downloadedApkPath.value = path;
      isReadyToInstall.value = true;

      // Persist so the install prompt appears again on next launch.
      await UpdateService.savePendingUpdate(release.version, path);
    } catch (e) {
      errorMessage.value = 'download_failed'.tr;
    } finally {
      isDownloading.value = false;
    }
  }

  /// Triggers the system install dialog for the downloaded APK.
  Future<void> installUpdate() async {
    final path = downloadedApkPath.value;
    if (path.isEmpty) return;

    final success = await UpdateService.installApk(path);
    if (success) {
      await UpdateService.clearPendingUpdate();
    }
  }

  /// Called when the user dismisses the install modal.
  Future<void> dismissUpdate() async {
    final release = latestRelease.value;
    if (release != null) {
      // Keep the pending update on disk but note it was dismissed so we
      // only auto-prompt once per launch.
      await UpdateService.setDismissedVersion(release.version);
    }
  }

  // ---------------------------------------------------------------------------
  // Pending update (re-prompt on app launch)
  // ---------------------------------------------------------------------------

  /// Called on init to check if a previously downloaded APK is waiting.
  Future<void> _checkPendingUpdate() async {
    final (version, path) = await UpdateService.getPendingUpdate();
    if (version == null || path == null) return;

    // Only auto-prompt if this version wasn't already dismissed in a
    // previous session. The user can still trigger it manually.
    final dismissed = await UpdateService.getDismissedVersion();
    if (dismissed == version) {
      // User dismissed this version before – still show button but
      // don't auto-pop.
      downloadedApkPath.value = path;
      isReadyToInstall.value = true;
      updateAvailable.value = true;

      await _loadCurrentVersion();
      if (UpdateService.isNewer(version, currentVersion.value)) {
        latestRelease.value = ReleaseInfo(
          tagName: 'v$version',
          version: version,
          name: 'Release v$version',
          body: '',
          apkDownloadUrl: '',
          htmlUrl: '',
        );
      }
      return;
    }

    downloadedApkPath.value = path;
    isReadyToInstall.value = true;
    updateAvailable.value = true;

    await _loadCurrentVersion();
    if (UpdateService.isNewer(version, currentVersion.value)) {
      latestRelease.value = ReleaseInfo(
        tagName: 'v$version',
        version: version,
        name: 'Release v$version',
        body: '',
        apkDownloadUrl: '',
        htmlUrl: '',
      );

      // Wait until the first frame is rendered, then show the install modal.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showInstallDialog();
      });
    } else {
      // Current version is same or newer – clear stale pending update.
      await UpdateService.clearPendingUpdate();
      isReadyToInstall.value = false;
      updateAvailable.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // UI helpers
  // ---------------------------------------------------------------------------

  /// Shows the update-available / download / install bottom sheet.
  void showUpdateDialog() {
    if (Get.context == null) return;

    Get.bottomSheet<void>(
      _UpdateBottomSheet(controller: this),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  /// Shows a compact install-confirmation modal.
  void showInstallDialog() {
    if (Get.context == null) return;

    Get.dialog<void>(
      _InstallConfirmDialog(controller: this),
      barrierDismissible: true,
    );
  }
}

// =============================================================================
// UI: Update Bottom Sheet
// =============================================================================

class _UpdateBottomSheet extends StatelessWidget {
  const _UpdateBottomSheet({required this.controller});
  final UpdateController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Obx(() => _buildContent(context, theme)),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme) {
    // --- Checking ---
    if (controller.isChecking.value) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _handle(theme),
          const SizedBox(height: 28),
          const CircularProgressIndicator(),
          const SizedBox(height: 18),
          Text('checking_for_updates'.tr,
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 28),
        ],
      );
    }

    // --- Downloading ---
    if (controller.isDownloading.value) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _handle(theme),
          const SizedBox(height: 28),
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: controller.downloadProgress.value,
                  strokeWidth: 6,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.12),
                ),
                Text(
                  '${(controller.downloadProgress.value * 100).toInt()}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('downloading_update'.tr,
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('please_wait'.tr,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color
                      ?.withValues(alpha: 0.6))),
          const SizedBox(height: 28),
        ],
      );
    }

    // --- Ready to install ---
    if (controller.isReadyToInstall.value) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _handle(theme),
          const SizedBox(height: 20),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.download_done_rounded,
                color: Color(0xFF10B981), size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'update_ready'.tr,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            '${'version'.tr}: ${controller.latestRelease.value?.version ?? ''}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color
                  ?.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                Get.back<void>();
                controller.installUpdate();
              },
              icon: const Icon(Icons.install_mobile_rounded),
              label: Text('install_now'.tr,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: () {
                controller.dismissUpdate();
                Get.back<void>();
              },
              child: Text('later'.tr),
            ),
          ),
        ],
      );
    }

    // --- Update available (not yet downloaded) ---
    if (controller.updateAvailable.value) {
      final release = controller.latestRelease.value!;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _handle(theme),
          const SizedBox(height: 20),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.system_update_rounded,
                color: theme.colorScheme.primary, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'update_available'.tr,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            '${controller.currentVersion.value} → ${release.version}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color
                  ?.withValues(alpha: 0.6),
            ),
          ),
          if (release.body.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                release.body,
                style: theme.textTheme.bodySmall,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => controller.downloadUpdate(),
              icon: const Icon(Icons.download_rounded),
              label: Text('download_update'.tr,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: () => Get.back<void>(),
              child: Text('later'.tr),
            ),
          ),
        ],
      );
    }

    // --- Error ---
    if (controller.errorMessage.value.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _handle(theme),
          const SizedBox(height: 28),
          Icon(Icons.error_outline_rounded,
              color: theme.colorScheme.error, size: 48),
          const SizedBox(height: 14),
          Text(controller.errorMessage.value,
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: () => Get.back<void>(),
              child: Text('close'.tr),
            ),
          ),
        ],
      );
    }

    // --- No update ---
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _handle(theme),
        const SizedBox(height: 28),
        Icon(Icons.check_circle_outline_rounded,
            color: const Color(0xFF10B981), size: 48),
        const SizedBox(height: 14),
        Text('already_latest_version'.tr,
            style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          '${'version'.tr}: ${controller.currentVersion.value}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color
                ?.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton(
            onPressed: () => Get.back<void>(),
            child: Text('close'.tr),
          ),
        ),
      ],
    );
  }

  Widget _handle(ThemeData theme) {
    return Center(
      child: Container(
        width: 52,
        height: 5,
        decoration: BoxDecoration(
          color: theme.dividerColor.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

// =============================================================================
// UI: Install Confirm Dialog (shown on app launch if pending)
// =============================================================================

class _InstallConfirmDialog extends StatelessWidget {
  const _InstallConfirmDialog({required this.controller});
  final UpdateController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.system_update_rounded,
                    color: Color(0xFF10B981), size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                'update_ready'.tr,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Obx(() => Text(
                    '${'new_version_available'.tr}: v${controller.latestRelease.value?.version ?? ''}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  )),
              const SizedBox(height: 10),
              Text(
                'install_update_prompt'.tr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color
                      ?.withValues(alpha: 0.6),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.back<void>();
                    controller.installUpdate();
                  },
                  icon: const Icon(Icons.install_mobile_rounded,
                      size: 20),
                  label: Text('install_now'.tr,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton(
                  onPressed: () {
                    controller.dismissUpdate();
                    Get.back<void>();
                  },
                  child: Text('later'.tr),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
