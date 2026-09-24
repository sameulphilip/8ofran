import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../data/app_lock_store.dart';

class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  final _pin = TextEditingController();
  var _error = '';
  var _biometricTried = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pin.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      ref.read(appLockUnlockedProvider.notifier).lock();
      _biometricTried = false;
      _pin.clear();
      setState(() => _error = '');
    } else if (state == AppLifecycleState.resumed) {
      _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    final unlocked = ref.read(appLockUnlockedProvider);
    if (unlocked || _biometricTried) return;
    final store = ref.read(appLockStoreProvider);
    if (!store.isEnabled) return;
    _biometricTried = true;
    if (!await store.canUseBiometric()) return;
    final ok = await store.unlockWithBiometric(
      reason: AppStrings.unlockWithBiometric,
    );
    if (ok && mounted) {
      ref.read(appLockUnlockedProvider.notifier).unlock();
    }
  }

  void _submitPin() {
    final store = ref.read(appLockStoreProvider);
    if (store.verifyPin(_pin.text)) {
      _pin.clear();
      setState(() => _error = '');
      ref.read(appLockUnlockedProvider.notifier).unlock();
    } else {
      setState(() => _error = AppStrings.wrongPin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = ref.watch(appLockUnlockedProvider);
    if (unlocked) return widget.child;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Material(
          color: AppColors.splash,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.gold500,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.unlockApp,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    AppStrings.appLockHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _pin,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      letterSpacing: 8,
                      fontSize: 22,
                    ),
                    decoration: InputDecoration(
                      hintText: AppStrings.enterAppPin,
                      hintStyle: const TextStyle(
                        color: Colors.white54,
                        letterSpacing: 0,
                        fontSize: 16,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      errorText: _error.isEmpty ? null : _error,
                    ),
                    onSubmitted: (_) => _submitPin(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _submitPin,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text(AppStrings.unlockApp),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      _biometricTried = false;
                      _tryBiometric();
                    },
                    child: const Text(
                      AppStrings.unlockWithBiometric,
                      style: TextStyle(color: AppColors.gold500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
