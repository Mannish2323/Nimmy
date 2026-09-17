import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/state/nimmy_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../models/nimmy_state.dart';
import '../../models/reminder.dart';
import '../../services/permissions/permission_service.dart';
import '../../services/voice/voice_service.dart';
import '../../widgets/confirmation_sheet.dart';
import '../../widgets/status_badge.dart';
import '../nimmy_orb/nimmy_orb_widget.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isListening = false;
  bool _finalTranscriptHandled = false;
  VoiceService? _voiceService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _voiceService ??= context.read<VoiceService>();
  }

  @override
  void dispose() {
    _voiceService?.cancelListening();
    _voiceService?.stopSpeaking();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    final voice = context.read<VoiceService>();
    final controller = context.read<NimmyController>();
    if (_isListening) {
      await voice.stopListening();
      if (!mounted) return;
      setState(() => _isListening = false);
      controller.setOrbState(
        NimmyOrbState.idle,
        message: 'Listening stopped. You can edit the transcript below.',
      );
      return;
    }

    final permissionService = context.read<PermissionService>();
    final permission =
        await permissionService.request(NimmyPermission.microphone);
    if (!mounted) return;
    if (permission != NimmyPermissionStatus.allowed) {
      controller.setOrbState(
        NimmyOrbState.error,
        message:
            'Microphone access is off. You can type instead or enable it in Permissions.',
      );
      return;
    }

    _finalTranscriptHandled = false;
    final started = await voice.startListening((text, isFinal) {
      if (!mounted) return;
      setState(() {
        _textController.text = text;
        _textController.selection = TextSelection.collapsed(
          offset: _textController.text.length,
        );
      });
      if (isFinal && !_finalTranscriptHandled) {
        _finalTranscriptHandled = true;
        setState(() => _isListening = false);
        _submit(text, source: InteractionSource.voice);
      }
    });
    if (!mounted) return;
    if (!started) {
      controller.setOrbState(
        NimmyOrbState.error,
        message:
            'Speech recognition is unavailable on this device. Please type your request.',
      );
      return;
    }
    setState(() => _isListening = true);
    controller.setOrbState(
      NimmyOrbState.listening,
      message: 'Listening… Speak naturally.',
    );
  }

  Future<void> _submit(
    String value, {
    InteractionSource source = InteractionSource.text,
  }) async {
    final text = value.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    final controller = context.read<NimmyController>();
    await controller.submitCommand(text, source: source);
    if (!mounted || controller.pendingProposal == null) return;

    final proposal = controller.pendingProposal!;
    final decision = await showNimmyConfirmationSheet(context, proposal);
    if (!mounted) return;
    switch (decision) {
      case ConfirmationDecision.confirm:
        final result = await controller.confirmPending();
        if (!mounted || result == null) return;
        if (result.success) {
          controller.setOrbState(NimmyOrbState.speaking);
          await context.read<VoiceService>().speak(result.message);
          if (mounted) controller.setOrbState(NimmyOrbState.success);
        }
        break;
      case ConfirmationDecision.edit:
        await controller.cancelPending(reason: 'user_requested_edit');
        if (!mounted) return;
        _textController.text = proposal.originalText;
        _textController.selection = TextSelection.collapsed(
          offset: _textController.text.length,
        );
        _focusNode.requestFocus();
        break;
      case ConfirmationDecision.cancel || null:
        await controller.cancelPending();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NimmyController>();
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      backgroundColor: NimmyColors.voidBlack,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: NimmySpacing.xs,
                vertical: NimmySpacing.xs,
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
                  ),
                  const Expanded(
                    child: Text(
                      'Nimmy',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Activity history',
                    onPressed: () => context.push('/audit'),
                    icon: const Icon(Icons.history_rounded),
                  ),
                ],
              ),
            ),
            if (controller.isLocalOnly)
              const Padding(
                padding: EdgeInsets.only(top: NimmySpacing.xs),
                child: StatusBadge(
                  label: 'LOCAL MODE • CLOUD SYNC NOT CONFIGURED',
                  color: NimmyColors.amber,
                  icon: Icons.cloud_off_outlined,
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(NimmySpacing.lg),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.sizeOf(context).height -
                        310 -
                        bottomInset,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      NimmyOrbWidget(
                        size: 230,
                        state: controller.orbState,
                        audioLevel: _isListening ? 0.72 : 0.28,
                      ),
                      const SizedBox(height: NimmySpacing.xl),
                      AnimatedSwitcher(
                        duration: NimmyDurations.medium,
                        child: Text(
                          controller.assistantMessage,
                          key: ValueKey(controller.assistantMessage),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: controller.orbState == NimmyOrbState.error
                                    ? NimmyColors.red
                                    : NimmyColors.textPrimary,
                              ),
                        ),
                      ),
                      if (controller.warning != null) ...[
                        const SizedBox(height: NimmySpacing.sm),
                        Text(
                          controller.warning!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: NimmyColors.amber,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(
                NimmySpacing.md,
                NimmySpacing.sm,
                NimmySpacing.md,
                NimmySpacing.lg,
              ),
              decoration: const BoxDecoration(
                color: NimmyColors.surface,
                border: Border(top: BorderSide(color: NimmyColors.border)),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    enabled: !controller.isBusy,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _submit,
                    decoration: InputDecoration(
                      hintText: 'Ask Nimmy to remind or remember…',
                      prefixIcon: const Icon(Icons.keyboard_rounded),
                      suffixIcon: IconButton(
                        tooltip: 'Send',
                        onPressed: controller.isBusy
                            ? null
                            : () => _submit(_textController.text),
                        icon: const Icon(Icons.arrow_upward_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(height: NimmySpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'Use keyboard',
                        onPressed: () => _focusNode.requestFocus(),
                        icon: const Icon(Icons.keyboard_rounded),
                      ),
                      const SizedBox(width: NimmySpacing.lg),
                      Semantics(
                        button: true,
                        label: _isListening ? 'Stop listening' : 'Start listening',
                        child: AnimatedContainer(
                          duration: NimmyDurations.fast,
                          width: _isListening ? 76 : 68,
                          height: _isListening ? 76 : 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: _isListening
                                ? const LinearGradient(
                                    colors: [NimmyColors.red, NimmyColors.pink],
                                  )
                                : NimmyColors.primaryGradient,
                            boxShadow: const [
                              BoxShadow(
                                color: NimmyColors.purpleGlow,
                                blurRadius: 28,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: controller.isBusy ? null : _toggleListening,
                            icon: Icon(
                              _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: NimmySpacing.lg),
                      IconButton.filledTonal(
                        tooltip: 'Permissions',
                        onPressed: () => context.push('/permissions'),
                        icon: const Icon(Icons.shield_outlined),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
