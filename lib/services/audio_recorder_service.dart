import 'dart:async';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'gemini_live_service.dart';

/// Service to handle audio recording and streaming to Gemini Live API
/// Records audio at 16kHz, 16-bit, mono (required by Gemini)
class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  final GeminiLiveService _geminiService;
  StreamSubscription<Uint8List>? _audioStreamSubscription;
  bool _isRecording = false;

  /// Whether audio is currently being recorded
  bool get isRecording => _isRecording;

  AudioRecorderService(this._geminiService);

  /// Start recording and streaming audio to Gemini
  Future<void> startRecording() async {
    try {
      // Check if microphone permission is granted
      if (!await _recorder.hasPermission()) {
        throw Exception('Microphone permission not granted');
      }

      // Configure recording for Gemini Live API requirements
      // - PCM 16-bit format
      // - 16kHz sample rate
      // - Mono (1 channel)
      final config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 256000,
      );

      print('Starting audio recording...');

      // Start recording and get the audio stream
      final stream = await _recorder.startStream(config);

      _isRecording = true;

      // Listen to audio chunks and send them to Gemini
      _audioStreamSubscription = stream.listen(
        (audioChunk) {
          // Send audio chunk to Gemini
          final uint8List = Uint8List.fromList(audioChunk);
          _geminiService.sendAudio(uint8List);
        },
        onError: (error) {
          print('Error in audio stream: $error');
          _isRecording = false;
        },
        onDone: () {
          print('Audio stream completed');
          _isRecording = false;
        },
      );

      print('Audio recording started');
    } catch (e) {
      print('Error starting recording: $e');
      _isRecording = false;
      rethrow;
    }
  }

  /// Stop recording audio
  Future<void> stopRecording() async {
    try {
      if (!_isRecording) {
        return;
      }

      print('Stopping audio recording...');

      // Cancel the stream subscription
      await _audioStreamSubscription?.cancel();
      _audioStreamSubscription = null;

      // Stop the recorder
      await _recorder.stop();

      _isRecording = false;
      print('Audio recording stopped');
    } catch (e) {
      print('Error stopping recording: $e');
      rethrow;
    }
  }

  /// Check if microphone permission is granted
  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  /// Dispose of resources
  void dispose() {
    stopRecording();
    _recorder.dispose();
  }
}
