import 'package:camion/bootstrap.dart';
import 'package:camion/core/config/app_flavor.dart';
import 'package:camion/firebase_options.dart';

Future<void> main() async {
  await bootstrap(
    flavor: AppFlavor.development,
    envFile: '.env.development',
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
  );
}
