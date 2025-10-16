import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/lesson.dart';
import '../models/vocabulary_word.dart';
import '../services/gemini_live_service.dart';
import '../services/audio_recorder_service.dart';
import '../services/audio_player_service.dart';

/// Chat screen for learning vocabulary with Gemini AI tutor
class LessonChatScreen extends StatefulWidget {
  final String apiKey;
  final Lesson lesson;
  final List<VocabularyWord> vocabularyWords;

  const LessonChatScreen({
    super.key,
    required this.apiKey,
    required this.lesson,
    required this.vocabularyWords,
  });

  @override
  State<LessonChatScreen> createState() => _LessonChatScreenState();
}

class _LessonChatScreenState extends State<LessonChatScreen> {
  late GeminiLiveService _geminiService;
  late AudioRecorderService _audioRecorder;
  late AudioPlayerService _audioPlayer;

  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  bool _isConnected = false;
  bool _isRecording = false;
  bool _isConnecting = false;
  bool _contextSent = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  /// Initialize all services
  void _initializeServices() {
    _geminiService = GeminiLiveService(apiKey: widget.apiKey);
    _audioRecorder = AudioRecorderService(_geminiService);
    _audioPlayer = AudioPlayerService(_geminiService);

    // Listen to text responses
    _geminiService.textOutputStream.listen((text) {
      setState(() {
        // Check if last message is from Gemini and append to it
        if (_messages.isNotEmpty && _messages.last.isFromGemini) {
          _messages.last = ChatMessage(
            text: _messages.last.text + text,
            isFromGemini: true,
          );
        } else {
          _messages.add(ChatMessage(text: text, isFromGemini: true));
        }
      });
      _scrollToBottom();
    });

    // Listen to connection state
    _geminiService.connectionStateStream.listen((isConnected) {
      setState(() {
        _isConnected = isConnected;
        _isConnecting = false;
      });

      // Send lesson context once connected
      if (isConnected && !_contextSent) {
        _sendLessonContext();
      }
    });

    // Auto-connect on init
    _connect();
  }

  /// Generate lesson context prompt
  String _generateLessonContext() {
    final wordList = widget.vocabularyWords.map((word) {
      return '${word.word} (${word.reading}) - ${word.meanings.join(", ")}';
    }).join('\n');

    return '''You are a friendly and patient Japanese language tutor. I'm learning JLPT ${widget.lesson.jlptLevel.value} vocabulary.

Today's lesson focuses on the following ${widget.vocabularyWords.length} words:

$wordList

Please help me learn these words by:
1. Introducing each word clearly with correct pronunciation
2. Providing natural example sentences
3. Explaining the usage and context
4. Engaging me in conversation using these words
5. Being encouraging and supportive
6. Speaking slowly and clearly
7. Providing both Japanese and English explanations as needed

Let's start the lesson! Please greet me warmly and introduce the first word.''';
  }

  /// Send lesson context to Gemini
  Future<void> _sendLessonContext() async {
    if (_contextSent) return;

    try {
      final context = _generateLessonContext();
      await _geminiService.sendText(context);
      _contextSent = true;
      print('Lesson context sent to Gemini');
    } catch (e) {
      print('Error sending lesson context: $e');
    }
  }

  /// Connect to Gemini Live API
  Future<void> _connect() async {
    setState(() {
      _isConnecting = true;
    });

    try {
      await _geminiService.connect();
      _showSnackBar('Connected to your AI tutor', isError: false);
    } catch (e) {
      _showSnackBar('Failed to connect: $e', isError: true);
      setState(() {
        _isConnecting = false;
      });
    }
  }

  /// Disconnect from Gemini Live API
  Future<void> _disconnect() async {
    try {
      if (_isRecording) {
        await _stopRecording();
      }
      await _geminiService.disconnect();
      _showSnackBar('Disconnected from tutor', isError: false);
    } catch (e) {
      _showSnackBar('Error disconnecting: $e', isError: true);
    }
  }

  /// Toggle audio recording
  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  /// Start audio recording
  Future<void> _startRecording() async {
    // Check microphone permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _showSnackBar('Microphone permission denied', isError: true);
      return;
    }

    try {
      await _audioRecorder.startRecording();
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      _showSnackBar('Failed to start recording: $e', isError: true);
    }
  }

  /// Stop audio recording
  Future<void> _stopRecording() async {
    try {
      await _audioRecorder.stopRecording();
      setState(() {
        _isRecording = false;
      });
    } catch (e) {
      _showSnackBar('Failed to stop recording: $e', isError: true);
    }
  }

  /// Send text message
  Future<void> _sendTextMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isFromGemini: false));
    });

    _textController.clear();
    _scrollToBottom();

    try {
      await _geminiService.sendText(text);
    } catch (e) {
      _showSnackBar('Failed to send message: $e', isError: true);
    }
  }

  /// Scroll to bottom of message list
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Show snackbar message
  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) async {
        if (didPop && _isConnected) {
          await _disconnect();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.lesson.jlptLevel.value} Lesson'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            // Vocabulary count
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '${widget.vocabularyWords.length} words',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            // Connection status indicator
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _isConnected ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Connection status banner
            if (_isConnecting)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: Colors.blue.shade100,
                child: Text(
                  'Connecting to your AI tutor...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.blue.shade900),
                ),
              ),

            // Message list
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.school,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isConnecting
                                ? 'Preparing your lesson...'
                                : 'Your AI tutor is ready!\nStart speaking or send a message.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return ChatBubble(message: message);
                      },
                    ),
            ),

            // Input controls
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Microphone button
                  Container(
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.red : Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isRecording ? Icons.mic : Icons.mic_none,
                        size: 28,
                        color: Colors.white,
                      ),
                      onPressed: _isConnected ? _toggleRecording : null,
                      tooltip: _isRecording
                          ? 'Stop recording'
                          : 'Start recording',
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Text input field
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      enabled: _isConnected,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onSubmitted: (_) => _sendTextMessage(),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send button
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: Colors.blue,
                    onPressed: _isConnected ? _sendTextMessage : null,
                    tooltip: 'Send message',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _geminiService.dispose();
    super.dispose();
  }
}

/// Represents a chat message
class ChatMessage {
  String text;
  final bool isFromGemini;

  ChatMessage({
    required this.text,
    required this.isFromGemini,
  });
}

/// Widget to display a chat bubble
class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          message.isFromGemini ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isFromGemini
              ? Colors.grey.shade300
              : Colors.blue.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.isFromGemini ? 'AI Tutor' : 'You',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.text,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
