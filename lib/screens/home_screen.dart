import 'package:flutter/material.dart';
import '../services/lesson_service.dart';
import 'lesson_detail_screen.dart';

/// Home screen showing list of available lessons
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LessonService _lessonService = LessonService();
  List<LessonWithProgress> _lessons = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadLessons();
  }

  /// Initialize app and load lessons
  Future<void> _initializeAndLoadLessons() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Initialize database and create test lessons
      await _lessonService.initializeApp();

      // Load lessons
      await _loadLessons();
    } catch (e) {
      setState(() {
        _error = 'Failed to load lessons: $e';
        _isLoading = false;
      });
    }
  }

  /// Load all lessons with progress
  Future<void> _loadLessons() async {
    try {
      final lessons = await _lessonService.getAllLessons();
      final lessonsWithProgress = <LessonWithProgress>[];

      for (var lesson in lessons) {
        final lessonWithProgress =
            await _lessonService.getLessonWithProgress(lesson);
        lessonsWithProgress.add(lessonWithProgress);
      }

      setState(() {
        _lessons = lessonsWithProgress;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load lessons: $e';
        _isLoading = false;
      });
    }
  }

  /// Navigate to lesson detail
  void _openLesson(LessonWithProgress lessonWithProgress) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonDetailScreen(
          lessonWithProgress: lessonWithProgress,
        ),
      ),
    );

    // Reload lessons when returning from detail screen
    if (result == true) {
      _loadLessons();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Japanese Learning'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeAndLoadLessons,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_lessons.isEmpty) {
      return const Center(
        child: Text(
          'No lessons available yet.\nCheck back soon!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLessons,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _lessons.length,
        itemBuilder: (context, index) {
          final lessonWithProgress = _lessons[index];
          return _buildLessonCard(lessonWithProgress);
        },
      ),
    );
  }

  Widget _buildLessonCard(LessonWithProgress lessonWithProgress) {
    final lesson = lessonWithProgress.lesson;
    final progressPercent = lessonWithProgress.progressPercentage;
    final isStarted = lessonWithProgress.isStarted;
    final isCompleted = lessonWithProgress.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _openLesson(lessonWithProgress),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                children: [
                  // JLPT Level badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      lesson.jlptLevel.value,
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Lesson title
                  Expanded(
                    child: Text(
                      'Lesson ${_lessons.indexOf(lessonWithProgress) + 1}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Status badge
                  if (isCompleted)
                    Icon(Icons.check_circle, color: Colors.green.shade600)
                  else if (isStarted)
                    Icon(Icons.play_circle, color: Colors.orange.shade600)
                  else
                    Icon(Icons.circle_outlined, color: Colors.grey.shade400),
                ],
              ),
              const SizedBox(height: 12),

              // Progress info
              Row(
                children: [
                  Icon(Icons.book, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    '${lessonWithProgress.totalWords} words',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.trending_up, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    '${lessonWithProgress.learnedWordsCount} learned',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '${progressPercent.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressPercent / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted
                            ? Colors.green.shade600
                            : Colors.blue.shade600,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
