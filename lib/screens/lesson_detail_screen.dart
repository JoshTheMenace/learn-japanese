import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/vocabulary_word.dart';
import '../services/lesson_service.dart';
import 'lesson_chat_screen.dart';

/// Lesson detail screen showing progress and vocabulary
class LessonDetailScreen extends StatefulWidget {
  final LessonWithProgress lessonWithProgress;

  const LessonDetailScreen({
    super.key,
    required this.lessonWithProgress,
  });

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  final LessonService _lessonService = LessonService();
  List<VocabularyWord> _nextWords = [];
  bool _isLoadingWords = false;

  @override
  void initState() {
    super.initState();
    _loadNextWords();
  }

  /// Load next words to study
  Future<void> _loadNextWords() async {
    setState(() {
      _isLoadingWords = true;
    });

    try {
      final words = await _lessonService.getNextWordsToStudy(
        widget.lessonWithProgress.lesson,
        count: 5,
      );

      setState(() {
        _nextWords = words;
        _isLoadingWords = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingWords = false;
      });
      _showError('Failed to load words: $e');
    }
  }

  /// Start lesson with Gemini
  Future<void> _startLessonChat() async {
    if (_nextWords.isEmpty) {
      _showError('No more words to learn in this lesson!');
      return;
    }

    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      _showError('API key not found');
      return;
    }

    // Mark lesson as started
    await _lessonService.startLesson(widget.lessonWithProgress.lesson);

    // Navigate to lesson chat screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonChatScreen(
          apiKey: apiKey,
          lesson: widget.lessonWithProgress.lesson,
          vocabularyWords: _nextWords,
        ),
      ),
    );

    // Return to home screen and refresh
    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lessonWithProgress.lesson;
    final totalWords = widget.lessonWithProgress.totalWords;
    final learnedWords = widget.lessonWithProgress.learnedWordsCount;
    final wordsLeft = widget.lessonWithProgress.wordsLeftToLearn;
    final progressPercent = widget.lessonWithProgress.progressPercentage;
    final isCompleted = widget.lessonWithProgress.isCompleted;

    return Scaffold(
      appBar: AppBar(
        title: Text('${lesson.jlptLevel.value} - Lesson Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isCompleted
                              ? Icons.check_circle
                              : Icons.school,
                          size: 32,
                          color: isCompleted
                              ? Colors.green.shade600
                              : Colors.blue.shade600,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isCompleted
                                    ? 'Lesson Completed!'
                                    : 'In Progress',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isCompleted
                                      ? Colors.green.shade700
                                      : Colors.blue.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${progressPercent.toStringAsFixed(0)}% Complete',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progressPercent / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCompleted
                              ? Colors.green.shade600
                              : Colors.blue.shade600,
                        ),
                        minHeight: 12,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(
                          'Total Words',
                          totalWords.toString(),
                          Icons.book,
                          Colors.blue,
                        ),
                        _buildStatColumn(
                          'Learned',
                          learnedWords.toString(),
                          Icons.check_circle,
                          Colors.green,
                        ),
                        _buildStatColumn(
                          'Remaining',
                          wordsLeft.toString(),
                          Icons.pending,
                          Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Next words section
            Text(
              'Next Words to Study',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            if (_isLoadingWords)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_nextWords.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.celebration,
                        size: 32,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'All words in this lesson have been learned!',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._nextWords.map((word) => _buildWordCard(word)).toList(),

            const SizedBox(height: 24),

            // Continue button
            if (!isCompleted && _nextWords.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startLessonChat,
                  icon: const Icon(Icons.play_arrow, size: 28),
                  label: const Text(
                    'Continue Learning',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(
    String label,
    String value,
    IconData icon,
    MaterialColor color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color.shade600, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildWordCard(VocabularyWord word) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Japanese word
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        word.word,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        word.reading,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                // Part of speech
                Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      word.partOfSpeech.value,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purple.shade900,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Meanings
            Text(
              word.meanings.join(', '),
              style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),

            // Example sentence
            if (word.exampleSentences.isNotEmpty) ... [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.exampleSentences[0].japanese,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      word.exampleSentences[0].reading,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      word.exampleSentences[0].english,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
