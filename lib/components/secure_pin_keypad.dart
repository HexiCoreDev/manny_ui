import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconly/iconly.dart';

/// Secure PIN keypad widget for authentication.
///
/// Features:
/// - Custom numeric keypad (no device keyboard)
/// - Visual PIN dots indicator
/// - Haptic feedback on key press
/// - Lockout countdown display
/// - Biometric fallback button (optional)
/// - Setup mode with confirmation step
///
/// Example usage:
/// ```dart
/// SecurePinKeypad(
///   title: 'Enter PIN',
///   onPinSubmitted: (pin) async {
///     final valid = await verifyPin(pin);
///     return valid;
///   },
/// )
/// ```
class SecurePinKeypad extends StatefulWidget {
  /// Title shown above the PIN dots.
  final String title;

  /// Subtitle/description text.
  final String? subtitle;

  /// Whether this is for PIN setup (shows confirm step).
  final bool isSetup;

  /// Whether to show biometric button.
  final bool showBiometricOption;

  /// Callback when biometric button is pressed.
  final VoidCallback? onBiometricPressed;

  /// Callback when PIN is submitted. Returns true if PIN is accepted.
  final Future<bool> Function(String pin) onPinSubmitted;

  /// Callback when cancel is pressed.
  final VoidCallback? onCancel;

  /// PIN length (default 4).
  final int pinLength;

  /// Optional callback to check lockout status.
  /// Returns the remaining lockout seconds, or null if not locked.
  final Future<int?> Function()? getLockoutSeconds;

  /// Whether to enable haptic feedback.
  final bool enableHaptics;

  const SecurePinKeypad({
    super.key,
    required this.title,
    this.subtitle,
    this.isSetup = false,
    this.showBiometricOption = false,
    this.onBiometricPressed,
    required this.onPinSubmitted,
    this.onCancel,
    this.pinLength = 4,
    this.getLockoutSeconds,
    this.enableHaptics = true,
  });

  @override
  State<SecurePinKeypad> createState() => _SecurePinKeypadState();
}

class _SecurePinKeypadState extends State<SecurePinKeypad>
    with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  String? _firstPin; // For setup confirmation
  bool _isConfirmStep = false;
  bool _isLoading = false;
  String? _errorMessage;
  int? _lockoutSeconds;
  Timer? _lockoutTimer;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _checkLockout();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkLockout() async {
    if (widget.getLockoutSeconds == null) return;
    final seconds = await widget.getLockoutSeconds!();
    if (seconds != null && seconds > 0) {
      setState(() {
        _lockoutSeconds = seconds;
      });
      _startLockoutTimer();
    }
  }

  void _startLockoutTimer() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_lockoutSeconds != null && _lockoutSeconds! > 0) {
        setState(() {
          _lockoutSeconds = _lockoutSeconds! - 1;
        });
      } else {
        timer.cancel();
        setState(() {
          _lockoutSeconds = null;
          _errorMessage = null;
        });
      }
    });
  }

  void _onKeyPressed(String key) {
    if (_isLoading || _lockoutSeconds != null) return;

    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }

    setState(() {
      _errorMessage = null;
    });

    if (key == 'delete') {
      if (_enteredPin.isNotEmpty) {
        setState(() {
          _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        });
      }
    } else if (key == 'biometric') {
      widget.onBiometricPressed?.call();
    } else {
      if (_enteredPin.length < widget.pinLength) {
        setState(() {
          _enteredPin += key;
        });

        // Auto-submit when PIN is complete
        if (_enteredPin.length == widget.pinLength) {
          _handlePinComplete();
        }
      }
    }
  }

  Future<void> _handlePinComplete() async {
    if (widget.isSetup) {
      if (!_isConfirmStep) {
        // First entry - save and ask for confirmation
        setState(() {
          _firstPin = _enteredPin;
          _enteredPin = '';
          _isConfirmStep = true;
        });
      } else {
        // Confirm step - check if PINs match
        if (_enteredPin == _firstPin) {
          await _submitPin(_enteredPin);
        } else {
          _showError('PINs do not match. Try again.');
          setState(() {
            _firstPin = null;
            _enteredPin = '';
            _isConfirmStep = false;
          });
        }
      }
    } else {
      await _submitPin(_enteredPin);
    }
  }

  Future<void> _submitPin(String pin) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await widget.onPinSubmitted(pin);

      if (!success && mounted) {
        _showError('Incorrect PIN');
        await _checkLockout();
      }
    } catch (e) {
      if (mounted) {
        _showError('An error occurred');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _enteredPin = '';
        });
      }
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _enteredPin = '';
    });
    _shakeController.forward(from: 0);
    if (widget.enableHaptics) {
      HapticFeedback.heavyImpact();
    }
  }

  String get _displayTitle {
    if (widget.isSetup) {
      return _isConfirmStep ? 'Confirm your PIN' : widget.title;
    }
    return widget.title;
  }

  String? get _displaySubtitle {
    if (widget.isSetup) {
      return _isConfirmStep
          ? 'Re-enter your PIN to confirm'
          : 'Choose a ${widget.pinLength}-digit PIN';
    }
    return widget.subtitle;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLocked = _lockoutSeconds != null && _lockoutSeconds! > 0;

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Header with cancel button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.onCancel != null)
                    IconButton(
                      onPressed: widget.onCancel,
                      icon: const Icon(IconlyBroken.close_square),
                    )
                  else
                    const SizedBox(width: 48),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // Title and subtitle
            Text(
              _displayTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (_displaySubtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                _displaySubtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 32),

            // PIN dots indicator
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    _shakeController.isAnimating
                        ? _shakeAnimation.value *
                              ((_shakeController.value * 10).toInt() % 2 == 0
                                  ? 1
                                  : -1)
                        : 0,
                    0,
                  ),
                  child: child,
                );
              },
              child: _buildPinDots(theme),
            ),

            const SizedBox(height: 16),

            // Error message or lockout timer
            SizedBox(height: 24, child: _buildStatusMessage(theme, isLocked)),

            const Spacer(flex: 1),

            // Numeric keypad
            _buildKeypad(theme, isLocked),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildPinDots(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.pinLength, (index) {
        final isFilled = index < _enteredPin.length;
        final hasError = _errorMessage != null;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled
                ? (hasError ? Colors.red : theme.colorScheme.primary)
                : Colors.transparent,
            border: Border.all(
              color: hasError
                  ? Colors.red
                  : (isFilled
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.3)),
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStatusMessage(ThemeData theme, bool isLocked) {
    if (_isLoading) {
      return CupertinoActivityIndicator(
        radius: 10,
        color: theme.colorScheme.primary,
      );
    }

    if (isLocked) {
      final minutes = (_lockoutSeconds! / 60).floor();
      final seconds = _lockoutSeconds! % 60;
      return Text(
        'Try again in ${minutes > 0 ? '${minutes}m ' : ''}${seconds}s',
        style: theme.textTheme.bodySmall?.copyWith(
          color: Colors.orange,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    if (_errorMessage != null) {
      return Text(
        _errorMessage!,
        style: theme.textTheme.bodySmall?.copyWith(
          color: Colors.red,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildKeypad(ThemeData theme, bool isLocked) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      [widget.showBiometricOption ? 'biometric' : '', '0', 'delete'],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: keys.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((key) {
                if (key.isEmpty) {
                  return const SizedBox(width: 72, height: 72);
                }
                return _buildKey(theme, key, isLocked);
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKey(ThemeData theme, String key, bool isLocked) {
    final isDisabled = isLocked && key != 'biometric';

    Widget child;
    if (key == 'delete') {
      child = Icon(
        IconlyBroken.delete,
        size: 24,
        color: isDisabled
            ? theme.colorScheme.onSurface.withValues(alpha: 0.2)
            : theme.colorScheme.onSurface,
      );
    } else if (key == 'biometric') {
      child = Icon(
        IconlyBroken.scan,
        size: 24,
        color: theme.colorScheme.primary,
      );
    } else {
      child = Text(
        key,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: isDisabled
              ? theme.colorScheme.onSurface.withValues(alpha: 0.2)
              : theme.colorScheme.onSurface,
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : () => _onKeyPressed(key),
        borderRadius: BorderRadius.circular(36),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: key == 'delete' || key == 'biometric'
                ? Colors.transparent
                : theme.colorScheme.surface.withValues(alpha: 0.5),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Full-screen PIN authentication dialog.
///
/// Shows a modal PIN entry screen with optional biometric fallback.
class PinAuthDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBiometricOption;
  final VoidCallback? onBiometricPressed;
  final Future<bool> Function(String pin) onPinSubmitted;
  final int pinLength;
  final Future<int?> Function()? getLockoutSeconds;

  const PinAuthDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.showBiometricOption = false,
    this.onBiometricPressed,
    required this.onPinSubmitted,
    this.pinLength = 4,
    this.getLockoutSeconds,
  });

  /// Show PIN authentication dialog.
  ///
  /// Returns true if authentication was successful, false if cancelled.
  static Future<bool> show({
    required BuildContext context,
    String title = 'Enter PIN',
    String? subtitle,
    bool showBiometricOption = false,
    VoidCallback? onBiometricPressed,
    required Future<bool> Function(String pin) onPinSubmitted,
    int pinLength = 4,
    Future<int?> Function()? getLockoutSeconds,
  }) async {
    final result = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return PinAuthDialog(
            title: title,
            subtitle: subtitle,
            showBiometricOption: showBiometricOption,
            onBiometricPressed: onBiometricPressed,
            onPinSubmitted: onPinSubmitted,
            pinLength: pinLength,
            getLockoutSeconds: getLockoutSeconds,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SecurePinKeypad(
        title: title,
        subtitle: subtitle,
        showBiometricOption: showBiometricOption,
        onBiometricPressed: onBiometricPressed,
        pinLength: pinLength,
        getLockoutSeconds: getLockoutSeconds,
        onPinSubmitted: (pin) async {
          final success = await onPinSubmitted(pin);
          if (success && context.mounted) {
            Navigator.of(context).pop(true);
          }
          return success;
        },
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }
}

/// PIN setup dialog for first-time setup.
///
/// Shows a security warning before allowing PIN setup, informing users
/// that the PIN cannot be recovered if forgotten.
class PinSetupDialog extends StatefulWidget {
  final Future<bool> Function(String pin) onPinSet;
  final int pinLength;
  final Future<int?> Function()? getLockoutSeconds;
  final String warningTitle;
  final String warningMessage;

  const PinSetupDialog({
    super.key,
    required this.onPinSet,
    this.pinLength = 4,
    this.getLockoutSeconds,
    this.warningTitle = 'Important Security Notice',
    this.warningMessage =
        'Your PIN is highly encrypted and stored only on this device. '
        'For your protection, it cannot be recovered or reset remotely.\n\n'
        'If you forget your PIN, you will need to sign out and sign back in to reset it.',
  });

  /// Show PIN setup dialog.
  ///
  /// Returns true if PIN was set successfully, false if cancelled.
  static Future<bool> show({
    required BuildContext context,
    required Future<bool> Function(String pin) onPinSet,
    int pinLength = 4,
    Future<int?> Function()? getLockoutSeconds,
    String? warningTitle,
    String? warningMessage,
  }) async {
    final result = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return PinSetupDialog(
            onPinSet: onPinSet,
            pinLength: pinLength,
            getLockoutSeconds: getLockoutSeconds,
            warningTitle: warningTitle ?? 'Important Security Notice',
            warningMessage:
                warningMessage ??
                'Your PIN is highly encrypted and stored only on this device. '
                    'For your protection, it cannot be recovered or reset remotely.\n\n'
                    'If you forget your PIN, you will need to sign out and sign back in to reset it.',
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
    return result ?? false;
  }

  @override
  State<PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<PinSetupDialog> {
  bool _hasAcknowledgedWarning = false;

  @override
  Widget build(BuildContext context) {
    if (!_hasAcknowledgedWarning) {
      return _buildWarningScreen(context);
    }

    return Scaffold(
      body: SecurePinKeypad(
        title: 'Set up PIN',
        isSetup: true,
        pinLength: widget.pinLength,
        getLockoutSeconds: widget.getLockoutSeconds,
        onPinSubmitted: (pin) async {
          final success = await widget.onPinSet(pin);
          if (success && context.mounted) {
            Navigator.of(context).pop(true);
          }
          return success;
        },
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  Widget _buildWarningScreen(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(IconlyBroken.close_square),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),

              // Security icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  IconlyBold.shield_done,
                  size: 50,
                  color: theme.colorScheme.primary,
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                widget.warningTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Warning message
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.amber[700],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'PIN Cannot Be Recovered',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.warningMessage,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.8,
                        ),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Tips
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tips for a strong PIN:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTip(theme, 'Avoid simple patterns like 1234 or 0000'),
                    _buildTip(
                      theme,
                      'Don\'t use your birth year or phone number',
                    ),
                    _buildTip(
                      theme,
                      'Choose something memorable but not obvious',
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasAcknowledgedWarning = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'I Understand, Continue',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTip(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
