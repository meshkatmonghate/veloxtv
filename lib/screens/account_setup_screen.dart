import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../tv/tv_focusable.dart';
import 'home_screen.dart';

class AccountSetupScreen extends StatefulWidget {
  const AccountSetupScreen({super.key});

  @override
  State<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends State<AccountSetupScreen> {
  int _selectedTab = 0; // 0 = Xtream Codes, 1 = M3U Playlist
  String? _validationError;

  // Controllers
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _m3uController = TextEditingController();

  // TV Remote Focus Nodes
  final _tabXtreamFocus = FocusNode(debugLabel: 'tabXtream');
  final _tabM3uFocus = FocusNode(debugLabel: 'tabM3u');
  final _serverFocus = FocusNode(debugLabel: 'server');
  final _usernameFocus = FocusNode(debugLabel: 'username');
  final _passwordFocus = FocusNode(debugLabel: 'password');
  final _m3uFocus = FocusNode(debugLabel: 'm3u');
  final _submitFocus = FocusNode(debugLabel: 'submit');

  @override
  void initState() {
    super.initState();

    // Listen to focus changes to update visual glow in real time
    for (final node in [
      _tabXtreamFocus,
      _tabM3uFocus,
      _serverFocus,
      _usernameFocus,
      _passwordFocus,
      _m3uFocus,
      _submitFocus,
    ]) {
      node.addListener(() {
        if (mounted) setState(() {});
      });
    }

    // Configure D-Pad key events to guarantee smooth directional navigation on TV
    _tabXtreamFocus.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _tabM3uFocus.requestFocus();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _serverFocus.requestFocus();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };

    _tabM3uFocus.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _tabXtreamFocus.requestFocus();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _m3uFocus.requestFocus();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };

    _serverFocus.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _usernameFocus.requestFocus();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          _tabXtreamFocus.requestFocus();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };

    _usernameFocus.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _passwordFocus.requestFocus();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          _serverFocus.requestFocus();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };

    _passwordFocus.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _submitFocus.requestFocus();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          _usernameFocus.requestFocus();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };

    _m3uFocus.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _submitFocus.requestFocus();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          _tabM3uFocus.requestFocus();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };

    _submitFocus.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          if (_selectedTab == 0) {
            _passwordFocus.requestFocus();
          } else {
            _m3uFocus.requestFocus();
          }
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter ||
            event.logicalKey == LogicalKeyboardKey.space ||
            event.logicalKey == LogicalKeyboardKey.gameButtonA) {
          if (_selectedTab == 0) {
            _loginXtream();
          } else {
            _importM3u();
          }
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };

    // Auto-focus the server field on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _serverFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _m3uController.dispose();

    _tabXtreamFocus.dispose();
    _tabM3uFocus.dispose();
    _serverFocus.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _m3uFocus.dispose();
    _submitFocus.dispose();
    super.dispose();
  }

  void _loginXtream() async {
    final appState = context.read<AppState>();
    var server = _serverController.text.trim();
    final user = _usernameController.text.trim();
    final pass = _passwordController.text.trim();

    if (server.isEmpty || user.isEmpty || pass.isEmpty) {
      setState(() {
        _validationError = 'لطفاً تمام فیلدها (آدرس سرور، نام کاربری و رمز عبور) را وارد کنید.';
      });
      return;
    }

    setState(() {
      _validationError = null;
    });

    final success = await appState.loginXtream(
      serverUrl: server,
      username: user,
      password: pass,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  void _importM3u() async {
    final appState = context.read<AppState>();
    final url = _m3uController.text.trim();

    if (url.isEmpty) {
      setState(() {
        _validationError = 'لطفاً آدرس لینک لیست M3U را وارد کنید.';
      });
      return;
    }

    setState(() {
      _validationError = null;
    });

    final success = await appState.importM3uUrl(url);
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Container(
              width: 580,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF171B26),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header & Logo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'VeloxTV',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Next-Generation High-Performance IPTV Client',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Mode Tabs
                  Row(
                    children: [
                      Expanded(
                        child: _buildTabButton(
                          title: 'Xtream Codes API',
                          icon: Icons.api_rounded,
                          index: 0,
                          focusNode: _tabXtreamFocus,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTabButton(
                          title: 'M3U Playlist URL',
                          icon: Icons.playlist_play_rounded,
                          index: 1,
                          focusNode: _tabM3uFocus,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Validation or App Error Display
                  if (_validationError != null || appState.errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _validationError ?? appState.errorMessage!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Form Fields
                  if (_selectedTab == 0) ...[
                    _buildTextField(
                      controller: _serverController,
                      focusNode: _serverFocus,
                      label: 'Server URL (آدرس سرور)',
                      hint: 'http://example.com:8080',
                      icon: Icons.dns_rounded,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _usernameFocus.requestFocus(),
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _usernameController,
                      focusNode: _usernameFocus,
                      label: 'Username (نام کاربری)',
                      hint: 'Enter your username',
                      icon: Icons.person_rounded,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _passwordFocus.requestFocus(),
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      label: 'Password (رمز عبور)',
                      hint: 'Enter your password',
                      icon: Icons.lock_rounded,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _loginXtream(),
                    ),
                    const SizedBox(height: 24),
                    _buildActionSubmitButton(
                      title: 'Connect with Xtream Codes',
                      isLoading: appState.isLoading,
                      focusNode: _submitFocus,
                      onSelect: _loginXtream,
                    ),
                  ] else ...[
                    _buildTextField(
                      controller: _m3uController,
                      focusNode: _m3uFocus,
                      label: 'M3U / M3U8 Playlist URL',
                      hint: 'http://example.com/playlist.m3u',
                      icon: Icons.link_rounded,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _importM3u(),
                    ),
                    const SizedBox(height: 24),
                    _buildActionSubmitButton(
                      title: 'Import M3U Playlist',
                      isLoading: appState.isLoading,
                      focusNode: _submitFocus,
                      onSelect: _importM3u,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required int index,
    required FocusNode focusNode,
  }) {
    final isSelected = _selectedTab == index;
    final isFocused = focusNode.hasFocus;

    return TvFocusable(
      focusNode: focusNode,
      onSelect: () {
        setState(() {
          _selectedTab = index;
          _validationError = null;
        });
        if (index == 0) {
          _serverFocus.requestFocus();
        } else {
          _m3uFocus.requestFocus();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00E5FF).withOpacity(0.18)
              : const Color(0xFF222838),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFocused
                ? const Color(0xFF00E5FF)
                : (isSelected ? const Color(0xFF00E5FF).withOpacity(0.6) : Colors.transparent),
            width: isFocused ? 2.0 : 1.0,
          ),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withOpacity(0.35),
                    blurRadius: 10,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? const Color(0xFF00E5FF) : Colors.white60,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? const Color(0xFF00E5FF) : Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputAction textInputAction = TextInputAction.next,
    ValueChanged<String>? onSubmitted,
  }) {
    final isFocused = focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: const Color(0xFF222838),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isFocused ? const Color(0xFF00E5FF) : Colors.white.withOpacity(0.08),
              width: isFocused ? 2.5 : 1.0,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withOpacity(0.4),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: isFocused ? const Color(0xFF00E5FF) : Colors.white60,
                size: 20,
              ),
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionSubmitButton({
    required String title,
    required bool isLoading,
    required FocusNode focusNode,
    required VoidCallback onSelect,
  }) {
    return TvFocusable(
      focusNode: focusNode,
      onSelect: isLoading ? null : onSelect,
      borderRadius: BorderRadius.circular(14),
      scaleFactor: 1.03,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isLoading ? null : onSelect,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0xFF00B0FF)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withOpacity(0.35),
                  blurRadius: 15,
                ),
              ],
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                    )
                  : Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
