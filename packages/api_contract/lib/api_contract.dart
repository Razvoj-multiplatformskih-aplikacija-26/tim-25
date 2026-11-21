typedef Json = Map<String, Object?>;

Json jsonObject(Object? value) => Map<String, Object?>.from(value as Map);

const apiPath = '/api/v1';
const loginPath = '$apiPath/auth/login';
const sessionPath = '$apiPath/auth/session';
const logoutPath = '$apiPath/auth/logout';
const queuePath = '$apiPath/queue';
const entriesPath = '$queuePath/entries';
const barbersPath = '$queuePath/barbers';

final class UserDto {
  const UserDto({required this.id, required this.name, required this.role});

  final String id;
  final String name;
  final String role;

  factory UserDto.fromJson(Json json) => UserDto(
    id: json['id'] as String,
    name: json['name'] as String,
    role: json['role'] as String,
  );

  Json toJson() => {'id': id, 'name': name, 'role': role};
}

final class LoginDto {
  const LoginDto({
    required this.username,
    required this.password,
    required this.role,
  });

  final String username;
  final String password;
  final String role;

  factory LoginDto.fromJson(Json json) => LoginDto(
    username: json['username'] as String,
    password: json['password'] as String,
    role: json['role'] as String,
  );

  Json toJson() => {'username': username, 'password': password, 'role': role};
}

final class SessionDto {
  const SessionDto({
    required this.user,
    required this.expiresAt,
    this.token,
    this.csrf,
  });

  final UserDto user;
  final String expiresAt;
  final String? token;
  final String? csrf;

  factory SessionDto.fromJson(Json json) => SessionDto(
    user: UserDto.fromJson(jsonObject(json['user'])),
    expiresAt: json['expiresAt'] as String,
    token: json['token'] as String?,
    csrf: json['csrf'] as String?,
  );

  Json toJson() => {
    'user': user.toJson(),
    'expiresAt': expiresAt,
    if (token != null) 'token': token,
    if (csrf != null) 'csrf': csrf,
  };
}

final class SalonDto {
  const SalonDto({
    required this.id,
    required this.name,
    required this.address,
    required this.weekdays,
    required this.opensAtMinute,
    required this.closesAtMinute,
  });

  final String id;
  final String name;
  final String address;
  final List<int> weekdays;
  final int opensAtMinute;
  final int closesAtMinute;

  factory SalonDto.fromJson(Json json) => SalonDto(
    id: json['id'] as String,
    name: json['name'] as String,
    address: json['address'] as String,
    weekdays: List<int>.from(json['weekdays'] as List),
    opensAtMinute: json['opensAtMinute'] as int,
    closesAtMinute: json['closesAtMinute'] as int,
  );

  Json toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'weekdays': weekdays,
    'opensAtMinute': opensAtMinute,
    'closesAtMinute': closesAtMinute,
  };
}

final class ServiceDto {
  const ServiceDto({
    required this.id,
    required this.salonId,
    required this.name,
    required this.priceRsd,
    required this.durationMinutes,
  });

  final String id;
  final String salonId;
  final String name;
  final int priceRsd;
  final int durationMinutes;

  factory ServiceDto.fromJson(Json json) => ServiceDto(
    id: json['id'] as String,
    salonId: json['salonId'] as String,
    name: json['name'] as String,
    priceRsd: json['priceRsd'] as int,
    durationMinutes: json['durationMinutes'] as int,
  );

  Json toJson() => {
    'id': id,
    'salonId': salonId,
    'name': name,
    'priceRsd': priceRsd,
    'durationMinutes': durationMinutes,
  };
}

final class BarberDto {
  const BarberDto({
    required this.id,
    required this.salonId,
    required this.name,
    required this.services,
    required this.availability,
  });

  final String id;
  final String salonId;
  final String name;
  final List<String> services;
  final String availability;

  factory BarberDto.fromJson(Json json) => BarberDto(
    id: json['id'] as String,
    salonId: json['salonId'] as String,
    name: json['name'] as String,
    services: List<String>.from(json['services'] as List),
    availability: json['availability'] as String,
  );

  Json toJson() => {
    'id': id,
    'salonId': salonId,
    'name': name,
    'services': services,
    'availability': availability,
  };
}

final class EntryDto {
  const EntryDto({
    required this.id,
    required this.salonId,
    required this.clientId,
    required this.clientName,
    required this.serviceId,
    required this.joinedAt,
    required this.sequence,
    required this.status,
    this.barberId,
    required this.note,
    required this.revision,
  });

  final String id;
  final String salonId;
  final String clientId;
  final String clientName;
  final String serviceId;
  final String joinedAt;
  final int sequence;
  final String status;
  final String? barberId;
  final String note;
  final int revision;

  factory EntryDto.fromJson(Json json) => EntryDto(
    id: json['id'] as String,
    salonId: json['salonId'] as String,
    clientId: json['clientId'] as String,
    clientName: json['clientName'] as String,
    serviceId: json['serviceId'] as String,
    joinedAt: json['joinedAt'] as String,
    sequence: json['sequence'] as int,
    status: json['status'] as String,
    barberId: json['barberId'] as String?,
    note: json['note'] as String,
    revision: json['revision'] as int,
  );

  Json toJson() => {
    'id': id,
    'salonId': salonId,
    'clientId': clientId,
    'clientName': clientName,
    'serviceId': serviceId,
    'joinedAt': joinedAt,
    'sequence': sequence,
    'status': status,
    if (barberId != null) 'barberId': barberId,
    'note': note,
    'revision': revision,
  };
}

final class QueueDto {
  const QueueDto({
    required this.salons,
    required this.services,
    required this.barbers,
    required this.entries,
    required this.positions,
    required this.waitingCounts,
    this.nextCursor,
    this.businessTime,
  });

  final List<SalonDto> salons;
  final List<ServiceDto> services;
  final List<BarberDto> barbers;
  final List<EntryDto> entries;
  final Map<String, int> positions;
  final Map<String, int> waitingCounts;
  final String? nextCursor;
  final String? businessTime;

  factory QueueDto.fromJson(Json json) => QueueDto(
    salons: (json['salons'] as List)
        .map((value) => SalonDto.fromJson(jsonObject(value)))
        .toList(),
    services: (json['services'] as List)
        .map((value) => ServiceDto.fromJson(jsonObject(value)))
        .toList(),
    barbers: (json['barbers'] as List)
        .map((value) => BarberDto.fromJson(jsonObject(value)))
        .toList(),
    entries: (json['entries'] as List)
        .map((value) => EntryDto.fromJson(jsonObject(value)))
        .toList(),
    positions: Map<String, int>.from(jsonObject(json['positions'])),
    waitingCounts: Map<String, int>.from(jsonObject(json['waitingCounts'])),
    nextCursor: json['nextCursor'] as String?,
    businessTime: json['businessTime'] as String?,
  );

  Json toJson() => {
    'salons': salons.map((value) => value.toJson()).toList(),
    'services': services.map((value) => value.toJson()).toList(),
    'barbers': barbers.map((value) => value.toJson()).toList(),
    'entries': entries.map((value) => value.toJson()).toList(),
    'positions': positions,
    'waitingCounts': waitingCounts,
    if (nextCursor != null) 'nextCursor': nextCursor,
    if (businessTime != null) 'businessTime': businessTime,
  };
}

final class JoinDto {
  const JoinDto({
    required this.salonId,
    required this.serviceId,
    required this.note,
  });

  final String salonId;
  final String serviceId;
  final String note;

  factory JoinDto.fromJson(Json json) => JoinDto(
    salonId: json['salonId'] as String,
    serviceId: json['serviceId'] as String,
    note: json['note'] as String,
  );

  Json toJson() => {'salonId': salonId, 'serviceId': serviceId, 'note': note};
}

final class TransitionDto {
  const TransitionDto({required this.status, required this.revision});

  final String status;
  final int revision;

  factory TransitionDto.fromJson(Json json) => TransitionDto(
    status: json['status'] as String,
    revision: json['revision'] as int,
  );

  Json toJson() => {'status': status, 'revision': revision};
}

final class AvailabilityDto {
  const AvailabilityDto({required this.availability});

  final String availability;

  factory AvailabilityDto.fromJson(Json json) =>
      AvailabilityDto(availability: json['availability'] as String);

  Json toJson() => {'availability': availability};
}

final class ErrorDto {
  const ErrorDto({required this.code, required this.details});

  final String code;
  final Json details;

  factory ErrorDto.fromJson(Json json) => ErrorDto(
    code: json['code'] as String,
    details: json['details'] == null ? const {} : jsonObject(json['details']),
  );

  Json toJson() => {'code': code, 'details': details};
}
