import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:frizeraj_ui/frizeraj_ui.dart';

import 'app.dart';
import 'data/windows_session_storage.dart';

void main() {
  const fake = bool.fromEnvironment('FRIZERAJ_FAKE');
  runApp(
    fake
        ? const FrizerajBackoffice()
        : SessionGate(
            role: Role.staff,
            title: 'Frizeraj • osoblje',
            storage: WindowsSessionStorage.new,
            content: (actor, repository, onSessionExpired) =>
                FrizerajBackoffice(
                  actor: actor,
                  repository: repository,
                  onSessionExpired: onSessionExpired,
                ),
          ),
  );
}
