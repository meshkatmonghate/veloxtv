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

class _LivePlayerScreenState extends State<LivePlayerScreen> {
  late final Player _player;
  late final VideoController _controller;
  late ChannelItem _currentChannel;

  bool _showControls = true;
  Timer? _hideTimer;
  bool _isRecordingThis = false;
  String? _activeRecordingTaskId;
  BoxFit _aspectRatio = BoxFit.contain;

  @override
  void initState() {
    super.initState();
    _currentChannel = widget.initialChannel;

    _player = Player();
    _controller = VideoController(_player);

    _playCurrentStream();
    _resetHideTimer();
  }

  void _playCurrentStream() {
    _player.open(Media(_currentChannel.streamUrl));
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    setState(() => _showControls = true);
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  void _switchChannel(ChannelItem channel) {
    if (_isRecordingThis && _activeRecordingTaskId != null) {
      context.read<AppState>().recordingService.stopRecording(_activeRecordingTaskId!);
      _isRecordingThis = false;
    }

    setState(() {
      _currentChannel = channel;
    });
    _playCurrentStream();
    _resetHideTimer();
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
    if (_isRecordingThis && _activeRecordingTaskId != null) {
      context.read<AppState>().recordingService.stopRecording(_activeRecordingTaskId!);
    }
    _player.dispose();
    super.dispose();
  }

  KeyEventResult _handleRemoteKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      _resetHideTimer();

      // Quick channel switch with D-pad Up / Down
      final currentIndex = widget.channelList.indexOf(_currentChannel);
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        if (currentIndex < widget.channelList.length - 1) {
          _switchChannel(widget.channelList[currentIndex + 1]);
          return KeyEventResult.handled;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        if (currentIndex > 0) {
          _switchChannel(widget.channelList[currentIndex - 1]);
          return KeyEventResult.handled;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.select ||
          event.logicalKey == LogicalKeyboardKey.enter) {
        _player.playOrPause();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.keyR) {
        _toggleRecording();
        return KeyEventResult.handled;
      }
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
          onTap: _resetHideTimer,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video Layer
              Video(
                controller: _controller,
                fit: _aspectRatio,
                controls: NoVideoControls,
              ),

              // Overlay Controls
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.85),
                        Colors.transparent,
                        Colors.black.withOpacity(0.85),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
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

                          // Recording Indicator & Trigger Button
                          TvFocusable(
                            onSelect: _toggleRecording,
                            borderRadius: BorderRadius.circular(10),
                            glowColor: Colors.redAccent,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: _isRecordingThis
                                    ? Colors.redAccent.withOpacity(0.3)
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
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isRecordingThis ? 'REC ACTIVE' : 'RECORD',
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

                          // Favorite Button
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
                                _currentChannel.isFavorite
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: _currentChannel.isFavorite ? Colors.amber : Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Aspect Ratio Button
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

                      // Bottom Bar (Stream status & remote control hint)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E5FF).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'LIVE STREAM',
                              style: TextStyle(
                                color: Color(0xFF00E5FF),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'D-Pad ▲ / ▼: Switch Channel  |  OK: Play/Pause  |  R: Record',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
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
