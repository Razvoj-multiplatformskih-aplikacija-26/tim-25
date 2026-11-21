import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:frizeraj_ui/frizeraj_ui.dart';

import 'app.dart';
import 'data/android_session_storage.dart';

void main() {
  const fake = bool.fromEnvironment('FRIZERAJ_FAKE');
  runApp(
    fake
        ? const FrizerajMobile()
        : SessionGate(
            role: Role.client,
            title: 'Frizeraj',
            defaultApiUrl: 'http://10.0.2.2:8080',
            storage: AndroidSessionStorage.new,
            content: (actor, repository, onSessionExpired) => FrizerajMobile(
              actor: actor,
              repository: repository,
              onSessionExpired: onSessionExpired,
            ),
          ),
  );
}
