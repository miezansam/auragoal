import 'dart:async';

import 'package:flutter/foundation.dart';

/// Transforme un Stream (ici le flux d'auth Supabase) en Listenable
/// pour que go_router puisse réévaluer ses redirections à chaque
/// changement d'état de connexion.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (_) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
