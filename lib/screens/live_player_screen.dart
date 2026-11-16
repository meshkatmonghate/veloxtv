import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../tv/tv_focusable.dart';

class LivePlayerScreen extends StatefulWidget {
  final ChannelItem initialChannel;
  final List<ChannelItem> channelList;

  const LivePlayerScreen({
    super.key,
    required this.initialChannel,
    required this.channelList,
  });

  @override
  State<LivePlayerScreen> createState() => _LivePlayerScreenState();
}

class _LivePlayerScreenState extends State<LivePlayerScreen> with SingleTickerProviderStateMixin {
  late final Player _player;
  late final VideoController _controller;
  late ChannelItem _currentChannel;

  // Player state
  bool _isPlaying = true;
  bool _isBuffering = true;
  String? _playerError;

  // UI state
  bool _showControls = true;
  Timer? _hideTimer;
  bool _isRecordingThis = false;
  String? _activeRecordingTaskId;
  BoxFit _aspectRatio = BoxFit.contain;

  // Center Play/Pause HUD Feedback
  bool _showPlayPauseHud = false;
  bool _hudIsPlaying = true;
  Timer? _hudTimer;

  // Quick Channel Drawer
  bool _showChannelDrawer = false;
  final ScrollController _drawerScrollController = ScrollController();

  // Stream Subscriptions
  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _currentChannel = widget.initialChannel;

    _player = Player();
    _controller = VideoController(_player);

    // Listen to media_kit player events
    _subscriptions.add(_player.stream.playing.listen((playing) {
      if (mounted) {
        setState(() => _isPlaying = playing);
      }
    }));

    _subscriptions.add(_player.stream.buffering.listen((buffering) {
      if (mounted) {
        setState(() => _isBuffering = buffering);
      }
    }));

    _subscriptions.add(_player.stream.error.listen((error) {
      if (mounted && error.isNotEmpty) {
        setState(() => _playerError = error);
      }
    }));

    _playCurrentStream();
    _resetHideTimer();
  }

  void _playCurrentStream() {
    setState(() {
      _isBuffering = true;
      _playerError = null;
    });

    _player.open(Media(_currentChannel.streamUrl), play: true);
    _player.play();
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    setState(() => _showControls = true);
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_showChannelDrawer) {
        setState(() => _showControls = false);
      }
    });
  }

  void _triggerPlayPause() {
    _hudTimer?.cancel();
    final willPlay = !_isPlaying;
    _player.playOrPause();

    setState(() {
      _hudIsPlaying = willPlay;
      _showPlayPauseHud = true;
    });

    _hudTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() => _showPlayPauseHud = false);
      }
    });

    _resetHideTimer();
  }

  void _switchChannel(ChannelItem channel) {
    if (_isRecordingThis && _activeRecordingTaskId != null) {
      context.read<AppState>().recordingService.stopRecording(_activeRecordingTaskId!);
      _isRecordingThis = false;
    }

    setState(() {
      _currentChannel = channel;
      _showChannelDrawer = false;
    });

    _playCurrentStream();
    _resetHideTimer();
  }

  void _channelUp() {
    final list = widget.channelList;
    if (list.isEmpty) return;
    final currentIndex = list.indexOf(_currentChannel);
    final nextIndex = (currentIndex + 1) % list.length;
    _switchChannel(list[nextIndex]);
  }

  void _channelDown() {
    final list = widget.channelList;
    if (list.isEmpty) return;
    final currentIndex = list.indexOf(_currentChannel);
    final prevIndex = (currentIndex - 1 + list.length) % list.length;
    _switchChannel(list[prevIndex]);
  }

  void _toggleRecording() async {
    final recService = context.read<AppState>().recordingService;

    if (_isRecordingThis && _activeRecordingTaskId != null) {
      recService.stopRecording(_activeRecordingTaskId!);
      setState(() {
        _isRecordingThis = false;
        _activeRecordingTaskId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording stopped and saved')),
      );
    } else {
      final task = await recService.startRecording(
        channelName: _currentChannel.name,
        streamUrl: _currentChannel.streamUrl,
      );
      setState(() {
        _isRecordingThis = true;
        _activeRecordingTaskId = task.id;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recording started: ${_currentChannel.name}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _cycleAspectRatio() {
    setState(() {
      if (_aspectRatio == BoxFit.contain) {
        _aspectRatio = BoxFit.fill;
      } else if (_aspectRatio == BoxFit.fill) {
        _aspectRatio = BoxFit.cover;
      } else {
        _aspectRatio = BoxFit.contain;
      }
    });
    _resetHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _hudTimer?.cancel();
    _drawerScrollController.dispose();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    if (_isRecordingThis && _activeRecordingTaskId != null) {
      context.read<AppState>().recordingService.stopRecording(_activeRecordingTaskId!);
    }
    _player.dispose();
    super.dispose();
  }

  KeyEventResult _handleRemoteKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      // 1. D-Pad Up / Channel Up (Next channel)
      if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.channelUp ||
          event.logicalKey == LogicalKeyboardKey.pageUp) {
        _channelUp();
        return KeyEventResult.handled;
      }

      // 2. D-Pad Down / Channel Down (Previous channel)
      if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.channelDown ||
          event.logicalKey == LogicalKeyboardKey.pageDown) {
        _channelDown();
        return KeyEventResult.handled;
      }

      // 3. OK / Center Button: Play/Pause with instant visual HUD
      if (event.logicalKey == LogicalKeyboardKey.select ||
          event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter ||
          event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.gameButtonA) {
        _triggerPlayPause();
        return KeyEventResult.handled;
      }

      // 4. D-Pad Left: Open/Close Quick Channel Drawer
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        setState(() {
          _showChannelDrawer = !_showChannelDrawer;
          _showControls = true;
        });
        return KeyEventResult.handled;
      }

      // 5. Back Button while Channel Drawer is open: Close Drawer first
      if (_showChannelDrawer &&
          (event.logicalKey == LogicalKeyboardKey.escape ||
              event.logicalKey == LogicalKeyboardKey.backspace)) {
        setState(() => _showChannelDrawer = false);
        return KeyEventResult.handled;
      }

      // 6. 'R' key: Record
      if (event.logicalKey == LogicalKeyboardKey.keyR) {
        _toggleRecording();
        return KeyEventResult.handled;
      }

      _resetHideTimer();
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: _handleRemoteKey,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_showControls) {
              _triggerPlayPause();
            } else {
              _resetHideTimer();
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. High-Performance Hardware Video Layer
              Video(
                controller: _controller,
                fit: _aspectRatio,
                controls: NoVideoControls,
              ),

              // 2. Buffering / Connecting Indicator
              if (_isBuffering && _playerError == null)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 38,
                          height: 38,
                          child: CircularProgressIndicator(
                            color: Color(0xFF00E5FF),
                            strokeWidth: 3.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Loading ${_currentChannel.name}...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 3. Player Error Banner
              if (_playerError != null)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    margin: const EdgeInsets.symmetric(horizontal: 36),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1418),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
                        const SizedBox(height: 12),
                        const Text(
                          'Playback Error / Stream Offline',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _playerError!,
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        TvFocusable(
                          onSelect: _playCurrentStream,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E5FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Retry Stream',
                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 4. Center Play/Pause HUD Feedback
              if (_showPlayPauseHud)
                Center(
                  child: AnimatedOpacity(
                    opacity: _showPlayPauseHud ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5), width: 2),
                      ),
                      child: Icon(
                        _hudIsPlaying ? Icons.play_arrow_rounded : Icons.pause_rounded,
                        color: const Color(0xFF00E5FF),
                        size: 54,
                      ),
                    ),
                  ),
                ),

              // 5. OSD Overlay Controls (Top & Bottom Bar)
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.9),
                        Colors.transparent,
                        Colors.black.withOpacity(0.9),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
                  child: Column(
                    children: [
                      // Top Bar
                      Row(
                        children: [
                          TvFocusable(
                            onSelect: () => Navigator.of(context).pop(),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Channel Number Badge
                          if (_currentChannel.num != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E5FF).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF00E5FF)),
                              ),
                              child: Text(
                                '#${_currentChannel.num}',
                                style: const TextStyle(
                                  color: Color(0xFF00E5FF),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),

                          // Channel Name & Category
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentChannel.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_currentChannel.categoryName != null)
                                  Text(
                                    _currentChannel.categoryName!,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Channel Drawer Quick Button
                          TvFocusable(
                            onSelect: () {
                              setState(() => _showChannelDrawer = !_showChannelDrawer);
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _showChannelDrawer
                                    ? const Color(0xFF00E5FF).withOpacity(0.3)
                                    : Colors.white12,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.list_rounded, color: Colors.white, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'Channels',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Recording Button
                          TvFocusable(
                            onSelect: _toggleRecording,
                            borderRadius: BorderRadius.circular(10),
                            glowColor: Colors.redAccent,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _isRecordingThis
                                    ? Colors.redAccent.withOpacity(0.35)
                                    : Colors.white12,
                                borderRadius: BorderRadius.circular(10),
                                border: _isRecordingThis
                                    ? Border.all(color: Colors.redAccent)
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.fiber_manual_record_rounded,
                                    color: _isRecordingThis ? Colors.redAccent : Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isRecordingThis ? 'REC' : 'RECORD',
                                    style: TextStyle(
                                      color: _isRecordingThis ? Colors.redAccent : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Favorite Toggle
                          TvFocusable(
                            onSelect: () => appState.toggleFavorite(_currentChannel),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                appState.storageService.isFavorite(_currentChannel.id)
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: appState.storageService.isFavorite(_currentChannel.id)
                                    ? Colors.amber
                                    : Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Aspect Ratio Toggle
                          TvFocusable(
                            onSelect: _cycleAspectRatio,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _aspectRatio == BoxFit.contain
                                    ? '16:9'
                                    : _aspectRatio == BoxFit.fill
                                        ? 'FILL'
                                        : 'ZOOM',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Bottom Info Bar (Full Player OSD)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B26).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Row(
                          children: [
                            // Pulsing Live Indicator
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E5FF).withOpacity(0.18),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF00E5FF)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF00E5FF),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'LIVE STREAM',
                                    style: TextStyle(
                                      color: Color(0xFF00E5FF),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),

                            // State Indicator (Playing / Paused / Buffering)
                            Icon(
                              _isBuffering
                                  ? Icons.sync_rounded
                                  : (_isPlaying ? Icons.play_arrow_rounded : Icons.pause_rounded),
                              color: Colors.white70,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isBuffering
                                  ? 'Buffering...'
                                  : (_isPlaying ? 'Playing' : 'Paused'),
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),

                            const Spacer(),

                            // Remote Control Guide
                            Text(
                              '▲ / ▼: Channels   |   OK: Play/Pause   |   ◄: Channel List   |   R: Record',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 6. Quick Channel Sidebar Drawer (Left Overlay)
              if (_showChannelDrawer)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 320,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF10131E).withOpacity(0.95),
                      border: Border(right: BorderSide(color: Colors.white.withOpacity(0.1))),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 25,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              const Icon(Icons.live_tv_rounded, color: Color(0xFF00E5FF), size: 22),
                              const SizedBox(width: 10),
                              const Text(
                                'Channel List',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: Colors.white60),
                                onPressed: () => setState(() => _showChannelDrawer = false),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            controller: _drawerScrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: widget.channelList.length,
                            itemBuilder: (context, index) {
                              final ch = widget.channelList[index];
                              final isCurrent = ch.id == _currentChannel.id;

                              return TvFocusable(
                                onSelect: () => _switchChannel(ch),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? const Color(0xFF00E5FF).withOpacity(0.2)
                                        : Colors.white.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(10),
                                    border: isCurrent
                                        ? Border.all(color: const Color(0xFF00E5FF))
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      if (ch.num != null)
                                        Text(
                                          '#${ch.num} ',
                                          style: TextStyle(
                                            color: isCurrent
                                                ? const Color(0xFF00E5FF)
                                                : Colors.white54,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      Expanded(
                                        child: Text(
                                          ch.name,
                                          style: TextStyle(
                                            color: isCurrent ? Colors.white : Colors.white70,
                                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
