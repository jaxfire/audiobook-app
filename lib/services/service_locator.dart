import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';

import '../page_manager.dart';
import 'audio_handler/audio_handler.dart';
import 'playlist_repository.dart';

GetIt getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Note: The audio service docs have you initialize the audio handler in main() before runApp.
  // So if you go with a different state mgmt system ensure this advice is followed.
  getIt.registerSingleton<AudioHandler>(await initAudioService());

  // services
  getIt.registerLazySingleton<PlaylistRepository>(() => DemoPlaylist());

  // page state
  getIt.registerLazySingleton<PageManager>(() => PageManager());
}
