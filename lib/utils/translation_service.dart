import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';

class TranslationService {
  static const String _baseUrl = 'https://translation.googleapis.com/language/translate/v2';
  // TODO: Replace with your API key and move to secure storage
  static const String _apiKey = 'AIzaSyBrm8ht4qHFSmIdfeqyaFWV1SiF9p17Kig';

  static const String _translatedTextKey = 'chat.fluffy.translated_text';
  static const String _showTranslatedKey = 'chat.fluffy.show_translated';

  /// Translates text to the target language and stores it in the event
  static Future<void> translateEvent(Event event, String targetLanguage) async {
    if (event.content['body'] == null) return;

    final text = event.content['body'] as String;
    if (text.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        body: {
          'q': text,
          'target': targetLanguage,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translatedText = data['data']['translations'][0]['translatedText'];

        // Store the translated text in the event's unsigned data
        event.unsigned ??= {};
        event.unsigned![_translatedTextKey] = translatedText;
        event.unsigned![_showTranslatedKey] = true;
      } else {
        throw Exception('Translation failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Translation failed: $e');
    }
  }

  /// Toggle translation visibility for an event
  static void toggleTranslation(Event event) {
    event.unsigned ??= {};
    final showTranslated = event.unsigned![_showTranslatedKey] as bool? ?? false;
    event.unsigned![_showTranslatedKey] = !showTranslated;
  }

  /// Get the translated text for an event
  static String? getTranslatedText(Event event) {
    if (event.unsigned == null) return null;
    return event.unsigned![_translatedTextKey] as String?;
  }

  /// Check if the event should show translation
  static bool shouldShowTranslation(Event event) {
    if (event.unsigned == null) return false;
    return event.unsigned![_showTranslatedKey] as bool? ?? false;
  }
}
