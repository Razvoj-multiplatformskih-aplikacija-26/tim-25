import 'package:domain/domain.dart';

String statusLabel(QueueStatus status) => switch (status) {
  QueueStatus.waiting => 'Na čekanju',
  QueueStatus.called => 'Pozvan',
  QueueStatus.inProgress => 'U toku',
  QueueStatus.completed => 'Završen',
  QueueStatus.cancelled => 'Otkazan',
  QueueStatus.noShow => 'Nije se pojavio',
};
String availabilityLabel(BarberAvailability availability) =>
    switch (availability) {
      BarberAvailability.working => 'Radi',
      BarberAvailability.paused => 'Pauza',
      BarberAvailability.away => 'Odsutan',
    };

String serviceName(QueueSnapshot snapshot, ServiceId id) =>
    snapshot.services.where((s) => s.id == id).firstOrNull?.name ?? id.value;
String salonName(QueueSnapshot snapshot, SalonId id) =>
    snapshot.salons.where((s) => s.id == id).firstOrNull?.name ?? id.value;
String dateLabel(DateTime date) {
  final local = date.toLocal();
  return '${local.day}.${local.month}.${local.year}. '
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
