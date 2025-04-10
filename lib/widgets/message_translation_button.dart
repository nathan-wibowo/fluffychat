import 'package:flutter/material.dart';
import 'package:fluffychat/utils/translation_service.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class MessageTranslationButton extends StatefulWidget {
  final Event event;
  final String currentLanguage;

  const MessageTranslationButton({
    super.key,
    required this.event,
    required this.currentLanguage,
  });

  @override
  State<MessageTranslationButton> createState() => _MessageTranslationButtonState();
}

class _MessageTranslationButtonState extends State<MessageTranslationButton> {
  bool _isTranslating = false;
  String? _translatedText;
  String? _detectedLanguage;
  bool _showTranslated = false;

  Future<void> _toggleTranslation() async {
    if (_translatedText != null) {
      setState(() {
        _showTranslated = !_showTranslated;
      });
      return;
    }

    if (_isTranslating) return;

    setState(() {
      _isTranslating = true;
    });

    try {
      // Get the original message text
      final originalText = widget.event.text;
      if (originalText == null) return;

      // Always translate regardless of detected language
      await TranslationService.translateEvent(
        widget.event,
        widget.currentLanguage,
      );
      _translatedText = TranslationService.getTranslatedText(widget.event);

      setState(() {
        _showTranslated = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.of(context).translationFailed),
        ),
      );
    } finally {
      setState(() {
        _isTranslating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show translation button for all text messages
    if (widget.event.type != EventTypes.Message || 
        widget.event.content['msgtype'] != 'm.text' || 
        widget.event.text == null) {
      return const SizedBox.shrink();
    }

    final messageText = widget.event.text;
    if (messageText == null) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showTranslated && _translatedText != null)
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(_translatedText!),
            ),
          ),
        IconButton(
          icon: _isTranslating
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.translate),
          onPressed: _toggleTranslation,
          tooltip: _showTranslated
              ? L10n.of(context).showOriginal
              : L10n.of(context).translateMessage,
        ),
      ],
    );
  }
}
