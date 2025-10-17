import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Service class to handle Gemini Live API WebSocket communication
/// Supports bidirectional audio and text streaming
class GeminiLiveService {
  WebSocketChannel? _channel;
  final String apiKey;
  bool _isConnected = false;

  // Streams for bidirectional communication
  final StreamController<Uint8List> _audioOutputController =
      StreamController<Uint8List>.broadcast();
  final StreamController<String> _textOutputController =
      StreamController<String>.broadcast();
  final StreamController<bool> _connectionStateController =
      StreamController<bool>.broadcast();
  final StreamController<Map<String, dynamic>> _toolCallController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of audio data received from Gemini (PCM 24kHz, 16-bit, mono)
  Stream<Uint8List> get audioOutputStream => _audioOutputController.stream;

  /// Stream of text responses received from Gemini
  Stream<String> get textOutputStream => _textOutputController.stream;

  /// Stream of connection state changes
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  /// Stream of tool calls from Gemini (for display_text function)
  Stream<Map<String, dynamic>> get toolCallStream => _toolCallController.stream;

  /// Whether the service is currently connected
  bool get isConnected => _isConnected;

  GeminiLiveService({required this.apiKey});

  /// Connect to the Gemini Live API
  Future<void> connect({
    String model = 'models/gemini-2.5-flash-native-audio-preview-09-2025',
    String voiceName = 'Zephyr',
    List<String> responseModalities = const ['AUDIO'],
  }) async {
    try {
      // Construct WebSocket URL with API key
      final wsUrl = Uri.parse(
        'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key=$apiKey',
      );

      print('Connecting to Gemini Live API...');
      _channel = WebSocketChannel.connect(wsUrl);

      // Send setup message to configure the session with function calling
      final setupMsg = {
        'setup': {
          'model': model,
          'generationConfig': {
            'responseModalities': responseModalities,
            'speechConfig': {
              'voiceConfig': {
                'prebuiltVoiceConfig': {'voiceName': voiceName}
              }
            }
          },
          'tools': [
            {
              'functionDeclarations': [
                {
                  'name': 'display_text',
                  'description': 'Display text on the screen for the student to read. Use this to show transcripts of what you just said, translations, vocabulary words, or any text the student should see.',
                  'parameters': {
                    'type': 'object',
                    'properties': {
                      'text': {
                        'type': 'string',
                        'description': 'The text to display on screen'
                      },
                      'type': {
                        'type': 'string',
                        'description': 'Type of text: transcript, translation, vocabulary, or note',
                        'enum': ['transcript', 'translation', 'vocabulary', 'note']
                      }
                    },
                    'required': ['text', 'type']
                  }
                }
              ]
            }
          ]
        }
      };

      print('=== Setup message: ${jsonEncode(setupMsg)}');

      _channel!.sink.add(jsonEncode(setupMsg));
      _isConnected = true;
      _connectionStateController.add(true);
      print('Connected to Gemini Live API');

      // Listen to incoming messages
      _channel!.stream.listen(
        _handleIncomingMessage,
        onError: (error) {
          print('!!! WebSocket error: $error');
          print('!!! Error type: ${error.runtimeType}');
          _isConnected = false;
          _connectionStateController.add(false);
        },
        onDone: () {
          print('!!! WebSocket connection closed');
          _isConnected = false;
          _connectionStateController.add(false);
        },
        cancelOnError: false,
      );
    } catch (e) {
      print('Error connecting to Gemini Live API: $e');
      _isConnected = false;
      _connectionStateController.add(false);
      rethrow;
    }
  }

  /// Handle incoming messages from the WebSocket
  void _handleIncomingMessage(dynamic message) {
    try {
      // Convert binary data to string if needed
      String messageString;
      if (message is String) {
        messageString = message;
      } else if (message is Uint8List) {
        messageString = utf8.decode(message);
      } else if (message is List<int>) {
        messageString = utf8.decode(message);
      } else {
        print('Unknown message type: ${message.runtimeType}');
        return;
      }

      final data = jsonDecode(messageString);

      // Check for errors
      if (data['error'] != null) {
        print('!!! ERROR from server: ${jsonEncode(data['error'])}');
        return;
      }

      // Handle setup completion
      if (data['setupComplete'] != null) {
        print('Setup complete');
        return;
      }

      // Handle server response with content
      if (data['serverContent'] != null) {
        final modelTurn = data['serverContent']['modelTurn'];
        if (modelTurn != null && modelTurn['parts'] != null) {
          final parts = modelTurn['parts'] as List;

          for (var part in parts) {
            // Audio data (base64 encoded PCM)
            if (part['inlineData'] != null) {
              final audioB64 = part['inlineData']['data'];
              final audioBytes = base64Decode(audioB64);
              _audioOutputController.add(audioBytes);
            }

            // Text data (regular text responses)
            if (part['text'] != null) {
              _textOutputController.add(part['text']);
            }
          }
        }

        // Check for turn completion (interruption handling)
        if (data['serverContent']['turnComplete'] == true) {
          print('Turn complete');
        }
      }

      // Handle tool calls
      if (data['toolCall'] != null) {
        final toolCall = data['toolCall'];
        print('=== Tool call received');

        // Parse functionCalls array
        if (toolCall['functionCalls'] != null) {
          final functionCalls = toolCall['functionCalls'] as List;
          for (var functionCall in functionCalls) {
            print('=== Calling function: ${functionCall['name']}');
            _handleFunctionCall(functionCall);
          }
        }
      }

      // Also check for functionCall in serverContent parts
      if (data['serverContent'] != null &&
          data['serverContent']['modelTurn'] != null &&
          data['serverContent']['modelTurn']['parts'] != null) {
        final parts = data['serverContent']['modelTurn']['parts'] as List;
        for (var part in parts) {
          if (part['functionCall'] != null) {
            print('=== Function call in parts: ${part['functionCall']['name']}');
            _handleFunctionCall(part['functionCall']);
          }
        }
      }
    } catch (e) {
      print('Error handling incoming message: $e');
    }
  }

  /// Send audio data to Gemini
  /// Audio should be PCM 16kHz, 16-bit, mono
  Future<void> sendAudio(Uint8List audioData) async {
    if (!_isConnected) {
      throw Exception('Not connected to Gemini Live API');
    }

    try {
      final message = {
        'realtimeInput': {
          'mediaChunks': [
            {
              'mimeType': 'audio/pcm',
              'data': base64Encode(audioData),
            }
          ]
        }
      };

      _channel?.sink.add(jsonEncode(message));
    } catch (e) {
      print('Error sending audio: $e');
      rethrow;
    }
  }

  /// Send text message to Gemini
  Future<void> sendText(String text) async {
    if (!_isConnected) {
      throw Exception('Not connected to Gemini Live API');
    }

    try {
      final message = {
        'clientContent': {
          'turns': [
            {
              'role': 'user',
              'parts': [
                {'text': text}
              ]
            }
          ],
          'turnComplete': true
        }
      };

      _channel?.sink.add(jsonEncode(message));
      print('Sent text: $text');
    } catch (e) {
      print('Error sending text: $e');
      rethrow;
    }
  }

  /// Handle function calls from Gemini (like display_text)
  void _handleFunctionCall(Map<String, dynamic> functionCall) {
    final functionName = functionCall['name'];
    final args = functionCall['args'] as Map<String, dynamic>?;

    if (functionName == 'display_text' && args != null) {
      final text = args['text'] ?? '';
      final type = args['type'] ?? 'transcript';

      print('=== Displaying text: $text (type: $type)');

      // Emit the display_text call to the stream
      _toolCallController.add({
        'function': 'display_text',
        'text': text,
        'type': type,
      });
    }
  }

  /// Disconnect from the Gemini Live API
  Future<void> disconnect() async {
    try {
      await _channel?.sink.close();
      _isConnected = false;
      _connectionStateController.add(false);
      print('Disconnected from Gemini Live API');
    } catch (e) {
      print('Error disconnecting: $e');
    }
  }

  /// Dispose of all resources
  void dispose() {
    disconnect();
    _audioOutputController.close();
    _textOutputController.close();
    _connectionStateController.close();
    _toolCallController.close();
  }
}
