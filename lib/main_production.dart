
import 'package:camion/bootstrap.dart';
import 'package:camion/core/config/app_flavor.dart';
import 'package:camion/firebase_options.dart';

Future<void> main() async {
  await bootstrap(
    flavor: AppFlavor.production,
    envFile: '.env.production',
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
  );
}
