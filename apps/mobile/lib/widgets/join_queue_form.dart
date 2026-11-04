import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:frizeraj_ui/frizeraj_ui.dart';
import 'package:blocs/blocs.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class JoinQueueForm extends StatefulWidget {
  const JoinQueueForm({super.key, required this.salonId});
  final SalonId salonId;
  @override
  State<JoinQueueForm> createState() => _JoinQueueFormState();
}

class _JoinQueueFormState extends State<JoinQueueForm> {
  ServiceId? selected;
  final note = TextEditingController();
  final formKey = GlobalKey<FormState>();
  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<QueueBloc, QueueState>(
    listenWhen: (previous, current) =>
        current.joinedId != null && current.joinedId != previous.joinedId,
    listener: (context, state) =>
        context.go('/entries/${state.joinedId!.value}'),
    builder: (context, state) {
      final snapshot = state.snapshot!;
      final services = snapshot.services
          .where((s) => s.salonId == widget.salonId)
          .toList();
      if (services.isEmpty) {
        return const Center(child: Text('Salon nije pronađen.'));
      }
      return Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'JOŠ SAMO JEDAN KORAK',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
                color: FrizerajColors.navy,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              salonName(snapshot, widget.salonId),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Text(
              'Jedna aktivna prijava po salonu. Prijavljivanje tokom radnog vremena.',
              style: TextStyle(color: FrizerajColors.muted, height: 1.5),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<ServiceId>(
              initialValue: selected,
              decoration: const InputDecoration(labelText: 'Usluga'),
              items: [
                for (final s in services)
                  DropdownMenuItem(
                    value: s.id,
                    child: Text('${s.name} • ${s.priceRsd} RSD'),
                  ),
              ],
              validator: (value) => value == null ? 'Izaberi uslugu.' : null,
              onChanged: state.busy
                  ? null
                  : (value) => setState(() => selected = value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: note,
              enabled: !state.busy,
              decoration: const InputDecoration(
                labelText: 'Napomena (opciono)',
              ),
              maxLines: 3,
              validator: (value) => switch (validateNote(value ?? '')) {
                Failure(:final error) => errorMessage(error),
                Success() => null,
              },
            ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  errorMessage(state.error!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: state.busy
                  ? null
                  : () {
                      if (formKey.currentState!.validate()) {
                        context.read<QueueBloc>().add(
                          JoinQueue(widget.salonId, selected!, note.text),
                        );
                      }
                    },
              child: Text(
                state.busy
                    ? 'Slanje…'
                    : state.error == null
                    ? 'Potvrdi prijavu'
                    : 'Pokušaj ponovo',
              ),
            ),
          ],
        ),
      );
    },
  );
}
