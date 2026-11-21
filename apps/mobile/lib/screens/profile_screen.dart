import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frizeraj_ui/frizeraj_ui.dart';

import '../widgets/mobile_scaffold.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => MobileScaffold(
    title: 'Profil',
    selectedIndex: 2,
    contentBuilder: (context, state, snapshot) => ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const CircleAvatar(
          radius: 38,
          backgroundColor: FrizerajColors.navyTint,
          child: FrizerajIcon('profile', size: 36),
        ),
        const SizedBox(height: 20),
        Text(
          context.read<QueueBloc>().actor.name,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          SessionActions.of(context) == null
              ? 'Demo klijent · Beograd'
              : 'Klijent · Beograd',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        if (SessionActions.of(context) case final session?) ...[
          if (session.error case final error?) Text(errorMessage(error)),
          OutlinedButton(
            onPressed: session.onLogout,
            child: const Text('Odjavi se'),
          ),
        ] else
          const Text(
            'Ovo je demo verzija sa lokalnim podacima. Ocene, udaljenosti i procene čekanja služe za prikaz salona.',
          ),
      ],
    ),
  );
}
