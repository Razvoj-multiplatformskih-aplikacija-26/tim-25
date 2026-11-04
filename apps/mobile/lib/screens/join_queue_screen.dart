import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../widgets/join_queue_form.dart';
import '../widgets/mobile_scaffold.dart';

class JoinQueueScreen extends StatelessWidget {
  const JoinQueueScreen({super.key, required this.salonId});
  final SalonId salonId;

  @override
  Widget build(BuildContext context) => MobileScaffold(
    title: 'Prijava u red',
    backPath: '/salons/${salonId.value}',
    showActionError: false,
    contentBuilder: (context, state, snapshot) =>
        JoinQueueForm(salonId: salonId),
  );
}
