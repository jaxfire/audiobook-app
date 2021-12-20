import 'package:audio_service/audio_service.dart';
import 'package:flutter/painting.dart';

import 'MyAudioHandler.dart';

Future<AudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => MyAudioHandler(),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.mycompany.myapp.audio',
      androidNotificationChannelName: 'Audio Service Demo',
      // androidNotificationChannelDescription TODO: Should probable do this. Read docs.

      // TODO: When set to true these two allow the user to swipe away the media notification.
      // The downside is that this makes it easier for the system to dismiss your app when it's paused as well.
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,

      // androidNotificationIcon:  TODO: Tiny status bar icon.

      notificationColor: Color.fromARGB(255, 20, 200, 100),
      fastForwardInterval:
          Duration(seconds: 10), // TODO: Make these customisable
      rewindInterval: Duration(seconds: 10), // TODO: Make these customisable
      preloadArtwork: true,
    ),
  );
}
