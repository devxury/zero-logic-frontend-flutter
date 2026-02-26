import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../core_nucleus/utils/token_resolver.dart';
import '../../state_matrix/bypass_streams.dart';

class VideoTelemetry {
  final double progress; 
  final bool isPlaying;
  final String timecode;
  VideoTelemetry(this.progress, this.isPlaying, this.timecode);
}

class VideoPlayerBlackbox extends StatefulWidget {
  final Map<String, dynamic> props;
  const VideoPlayerBlackbox(this.props, {super.key});

  @override
  State<VideoPlayerBlackbox> createState() => _VideoPlayerBlackboxState();
}

class _VideoPlayerBlackboxState extends State<VideoPlayerBlackbox> {
  late String _streamId;
  late HighFrequencyChannel<VideoTelemetry> _channel;
  
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _streamId = widget.props['stream_id'] ?? 'video_${UniqueKey().toString()}';
    
    _channel = BypassStreamEngine().subscribe<VideoTelemetry>(
      _streamId, 
      VideoTelemetry(0.0, false, "0:00 / 0:00")
    );

    _initializeRealVideo();
  }

  Future<void> _initializeRealVideo() async {
    final String? url = TokenResolver.resolveValue(widget.props['url'])?.toString();
    if (url == null || url.trim().isEmpty) return;
    
    _controller = VideoPlayerController.networkUrl(Uri.parse(url));

    try {
      await _controller!.initialize();
      
      if (mounted) {
        setState(() { _isInitialized = true; });
      }

      _controller!.addListener(() {
        if (!mounted) return;
        final pos = _controller!.value.position;
        final dur = _controller!.value.duration;
        final isPlaying = _controller!.value.isPlaying;

        double progress = 0.0;
        if (dur.inMilliseconds > 0) {
          progress = pos.inMilliseconds / dur.inMilliseconds;
        }

        final timecode = "${_formatDuration(pos)} / ${_formatDuration(dur)}";

        BypassStreamEngine().emitFast(_streamId, VideoTelemetry(progress, isPlaying, timecode));
      });

      if (widget.props['auto_play'] == true) {
        _controller!.play();
      }
    } catch (e) {
      debugPrint("[DeepCore Blackbox] Error inicializando stream de video: $e");
    }
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return "$mins:${secs.toString().padLeft(2, '0')}";
  }

  void _togglePlay() {
    if (_controller == null || !_isInitialized) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    BypassStreamEngine().unsubscribe(_streamId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // CORRECCIONES: Uso de ?? para valores por defecto internos
    final double height = TokenResolver.resolveSize(widget.props['height']) ?? 220;
    final double radius = TokenResolver.resolveSize(widget.props['radius']) ?? 0;
    final Color bgColor = TokenResolver.resolveColor(widget.props['bg_color']) ?? Colors.black;
    
    final String posterUrl = TokenResolver.resolveValue(widget.props['poster'])?.toString() ?? '';
    final double posterOpacity = TokenResolver.resolveSize(widget.props['poster_opacity']) ?? 0.6;
    
    final double controlHeight = TokenResolver.resolveSize(widget.props['control_height']) ?? 40;
    final double barHeight = TokenResolver.resolveSize(widget.props['bar_height']) ?? 4;
    final Color accentColor = TokenResolver.resolveColor(widget.props['accent_color']) ?? Colors.red;
    final Color barBgColor = TokenResolver.resolveColor(widget.props['bar_bg_color']) ?? Colors.white24;
    
    final Color textColor = TokenResolver.resolveColor(widget.props['text_color']) ?? Colors.white;
    final String fontFamily = TokenResolver.resolveValue(widget.props['font_family'])?.toString() ?? 'monospace';
    final String playIcon = TokenResolver.resolveValue(widget.props['play_icon'])?.toString() ?? "▶";
    final String pauseIcon = TokenResolver.resolveValue(widget.props['pause_icon'])?.toString() ?? "⏸";

    return Container(
      width: double.infinity,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_isInitialized && _controller != null)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!), 
              ),
            )
          else if (posterUrl.isNotEmpty)
            Opacity(
              opacity: posterOpacity,
              child: Image.network(
                posterUrl, 
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: CircularProgressIndicator(color: accentColor)
                ),
              ),
            ),

          Positioned.fill(
            child: GestureDetector(
              onTap: _togglePlay, 
              child: Container(color: Colors.transparent),
            ),
          ),

          Positioned(
            left: 0, right: 0, bottom: 0,
            height: controlHeight,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _VideoProgressPainter(
                  channel: _channel, 
                  accentColor: accentColor,
                  barBgColor: barBgColor,
                  textColor: textColor,
                  barHeight: barHeight,
                  fontFamily: fontFamily,
                  playIcon: playIcon,
                  pauseIcon: pauseIcon,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoProgressPainter extends CustomPainter {
  final HighFrequencyChannel<VideoTelemetry> channel;
  final Color accentColor;
  final Color barBgColor;
  final Color textColor;
  final double barHeight;
  final String fontFamily;
  final String playIcon;
  final String pauseIcon;

  _VideoProgressPainter({
    required this.channel, 
    required this.accentColor,
    required this.barBgColor,
    required this.textColor,
    required this.barHeight,
    required this.fontFamily,
    required this.playIcon,
    required this.pauseIcon,
  }) : super(repaint: channel.notifier);

  @override
  void paint(Canvas canvas, Size size) {
    final telemetry = channel.currentPayload;

    final bgPaint = Paint()..color = barBgColor;
    canvas.drawRect(Rect.fromLTWH(0, size.height - barHeight, size.width, barHeight), bgPaint);

    final progressPaint = Paint()..color = accentColor;
    canvas.drawRect(Rect.fromLTWH(0, size.height - barHeight, size.width * telemetry.progress, barHeight), progressPaint);

    final double controlCenterY = (size.height - barHeight) / 2;

    final textPainter = TextPainter(
      text: TextSpan(
        text: telemetry.timecode,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: fontFamily),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(16, controlCenterY - (textPainter.height / 2)));

    final iconPainter = TextPainter(
      text: TextSpan(
        text: telemetry.isPlaying ? pauseIcon : playIcon,
        style: TextStyle(color: textColor, fontSize: 16),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(canvas, Offset(size.width - 16 - iconPainter.width, controlCenterY - (iconPainter.height / 2)));
  }

  @override
  bool shouldRepaint(covariant _VideoProgressPainter oldDelegate) => true;
}