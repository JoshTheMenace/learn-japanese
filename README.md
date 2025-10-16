# Gemini Live Flutter Demo

A Flutter application demonstrating real-time audio and text communication with Google's Gemini Live API.

## Features

- **Real-time voice chat** with Gemini AI
- **Text messaging** support
- **Live audio playback** of Gemini's voice responses
- Clean, intuitive UI
- Bidirectional streaming

## Quick Start

### Prerequisites

- Flutter SDK (3.8.1 or higher)
- A Gemini API key from [Google AI Studio](https://makersuite.google.com/app/apikey)

### Installation

1. Clone this repository

2. Create a `.env` file in the project root:
   ```bash
   cp .env.example .env
   ```

3. Add your API key to the `.env` file:
   ```
   GEMINI_API_KEY=your_actual_api_key_here
   ```

4. Install dependencies:
   ```bash
   flutter pub get
   ```

5. Run the app:
   ```bash
   flutter run
   ```

## Usage

1. **Connect**: Tap the power button in the top-right corner
2. **Voice Chat**: Tap and hold the microphone button, speak, then release
3. **Text Chat**: Type your message and tap send

## Documentation

For detailed implementation details, see [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)

For technical analysis of the Gemini Live API, see [assets/ANALYSIS.md](assets/ANALYSIS.md)

## Architecture

- **GeminiLiveService**: WebSocket communication
- **AudioRecorderService**: Microphone input handling
- **AudioPlayerService**: Audio playback management
- **GeminiLiveChatScreen**: User interface

## Platform Configuration

### Android

Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

### iOS

Add to `ios/Runner/Info.plist`:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to communicate with Gemini</string>
```

## Dependencies

- `web_socket_channel` - WebSocket communication
- `record` - Audio recording
- `just_audio` - Audio playback
- `path_provider` - Temporary file management
- `permission_handler` - Runtime permissions
- `flutter_dotenv` - Environment variable management

## License

This is a demonstration project. Refer to Google's Gemini API terms for usage rights.
