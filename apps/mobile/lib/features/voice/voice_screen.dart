// 🟣 NIMMY — Voice Screen (Full-screen AI conversation)
// =====================================================
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/native/nimmy_bridge.dart';
import '../../core/network/api_client.dart';
import '../nimmy_orb/nimmy_orb_widget.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen>
    with SingleTickerProviderStateMixin {
  final NimmyApiClient _apiClient = NimmyApiClient();
  NimmyOrbState _orbState = NimmyOrbState.idle;
  bool _isRecording = false;
  String _assistantReply = '';
  String? _recordedFilePath;

  Future<void> _handleStartRecording() async {
    setState(() {
      _isRecording = true;
      _orbState = NimmyOrbState.listening;
      _assistantReply = '';
    });

    final res = await NimmyNativeBridge.startVoiceRecording();
    if (mounted && res['filePath'] != null) {
      _recordedFilePath = res['filePath'] as String;
    }
  }

  Future<void> _handleStopRecording() async {
    setState(() {
      _isRecording = false;
      _orbState = NimmyOrbState.thinking;
    });

    final stopRes = await NimmyNativeBridge.stopVoiceRecording();
    final bytes = stopRes['fileSizeBytes'] ?? 0;

    // Send cognitive intent to Gateway / AI Brain
    final chatRes = await _apiClient.sendChatMessage(
      'Voice input captured ($bytes bytes PCM, path: ${_recordedFilePath ?? 'native stream'})',
      sessionId: 'voice-session',
    );

    if (mounted) {
      setState(() {
        _assistantReply = chatRes['reply'] ?? 'Voice turn processed.';
        _orbState = NimmyOrbState.speaking;
      });

      // Return to idle after speech presentation
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted && _orbState == NimmyOrbState.speaking) {
          setState(() => _orbState = NimmyOrbState.idle);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NimmyColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: NimmyColors.textSecondary,
                      size: 32,
                    ),
                  ),
                  const Text(
                    'Nimmy Voice Core',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: NimmyColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.history_rounded,
                      color: NimmyColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Nimmy Orb (large, centered)
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      NimmyOrbWidget(
                        size: 220,
                        state: _orbState,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _getStatusText(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: NimmyColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_assistantReply.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: NimmyColors.surface.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: NimmyColors.purple.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            '"$_assistantReply"',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              color: NimmyColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom controls
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Keyboard / chat fallback
                  _ControlButton(
                    icon: Icons.keyboard_rounded,
                    onTap: () {},
                  ),

                  // Main mic button with native AudioRecord hooks
                  GestureDetector(
                    onTapDown: (_) => _handleStartRecording(),
                    onTapUp: (_) => _handleStopRecording(),
                    onTapCancel: () {
                      NimmyNativeBridge.stopVoiceRecording();
                      setState(() {
                        _isRecording = false;
                        _orbState = NimmyOrbState.idle;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _isRecording ? 80 : 72,
                      height: _isRecording ? 80 : 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _isRecording
                              ? [NimmyColors.red, NimmyColors.pink]
                              : [NimmyColors.purpleDark, NimmyColors.purple],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isRecording
                                    ? NimmyColors.red
                                    : NimmyColors.purple)
                                .withValues(alpha: 0.4),
                            blurRadius: _isRecording ? 30 : 20,
                            spreadRadius: _isRecording ? 4 : 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),

                  // Native Android daemon status
                  _ControlButton(
                    icon: Icons.graphic_eq_rounded,
                    onTap: () async {
                      final running = await NimmyNativeBridge.isServiceRunning();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              running
                                  ? 'Kotlin Native Service: ACTIVE'
                                  : 'Kotlin Native Service: STANDBY',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText() {
    switch (_orbState) {
      case NimmyOrbState.idle:
        return 'Hold mic to capture native voice';
      case NimmyOrbState.listening:
        return 'Listening (16kHz PCM)...';
      case NimmyOrbState.thinking:
        return 'Cognitive processing...';
      case NimmyOrbState.speaking:
        return 'Nimmy response:';
      case NimmyOrbState.recording:
        return 'Recording buffer...';
      case NimmyOrbState.taskComplete:
        return 'Task synchronized!';
    }
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ControlButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: NimmyColors.surfaceLight,
          border: Border.all(color: NimmyColors.border),
        ),
        child: Icon(icon, color: NimmyColors.textSecondary, size: 24),
      ),
    );
  }
}
