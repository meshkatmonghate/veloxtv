import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tv/tv_focusable.dart';

class ParentalPinDialog extends StatefulWidget {
  final String title;
  final bool isSettingPin;
  final bool Function(String pin)? onVerify;

  const ParentalPinDialog({
    super.key,
    this.title = 'Enter Parental PIN',
    this.isSettingPin = false,
    this.onVerify,
  });

  static Future<bool> show(
    BuildContext context, {
    String title = 'Enter Parental PIN',
    bool isSettingPin = false,
    bool Function(String pin)? onVerify,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ParentalPinDialog(
        title: title,
        isSettingPin: isSettingPin,
        onVerify: onVerify,
      ),
    );
    return result ?? false;
  }

  @override
  State<ParentalPinDialog> createState() => _ParentalPinDialogState();
}

class _ParentalPinDialogState extends State<ParentalPinDialog> {
  String _pin = '';
  bool _hasError = false;

  void _onDigit(String digit) {
    if (_pin.length < 4) {
      setState(() {
        _pin += digit;
        _hasError = false;
      });

      if (_pin.length == 4) {
        _submitPin();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _hasError = false;
      });
    }
  }

  void _submitPin() {
    if (widget.onVerify != null) {
      final isValid = widget.onVerify!(_pin);
      if (isValid) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _hasError = true;
          _pin = '';
        });
      }
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E2230),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_rounded, size: 48, color: Color(0xFF00E5FF)),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _hasError ? 'Incorrect PIN, please try again' : 'Enter 4-digit security PIN',
              style: TextStyle(
                color: _hasError ? Colors.redAccent : Colors.white60,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),

            // PIN Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? const Color(0xFF00E5FF) : Colors.white24,
                    boxShadow: isFilled
                        ? [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: 28),

            // Numpad for TV remote
            Column(
              children: [
                _buildNumRow(['1', '2', '3']),
                const SizedBox(height: 10),
                _buildNumRow(['4', '5', '6']),
                const SizedBox(height: 10),
                _buildNumRow(['7', '8', '9']),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildNumpadButton(
                      child: const Icon(Icons.close_rounded, color: Colors.white60),
                      onSelect: () => Navigator.of(context).pop(false),
                    ),
                    const SizedBox(width: 12),
                    _buildNumpadButton(
                      child: const Text(
                        '0',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      onSelect: () => _onDigit('0'),
                    ),
                    const SizedBox(width: 12),
                    _buildNumpadButton(
                      child: const Icon(Icons.backspace_outlined, color: Colors.white70),
                      onSelect: _onBackspace,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits.map((d) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: _buildNumpadButton(
            child: Text(
              d,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            onSelect: () => _onDigit(d),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNumpadButton({
    required Widget child,
    required VoidCallback onSelect,
  }) {
    return TvFocusable(
      onSelect: onSelect,
      borderRadius: BorderRadius.circular(12),
      scaleFactor: 1.15,
      child: Container(
        width: 64,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF282E42),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: child),
      ),
    );
  }
}
