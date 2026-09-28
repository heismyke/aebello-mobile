/// Data returned by the backend. Field names match the JSON from svc.
library;

class User {
  const User({required this.id, required this.email, required this.name});
  final String id;
  final String email;
  final String name;

  factory User.fromJson(Map<String, dynamic> j) => User(id: j['id'], email: j['email'], name: j['name']);
  Map<String, dynamic> toJson() => {'id': id, 'email': email, 'name': name};

  String get firstName => name.split(' ').first;
}

class Network {
  const Network(this.name, this.type);
  final String name;
  final String type; // 4G, 5G

  factory Network.fromJson(Map<String, dynamic> j) => Network(j['name'], j['type']);
  static List<Network> list(dynamic j) => [for (final n in (j as List? ?? [])) Network.fromJson(n)];
}

class Destination {
  const Destination({
    required this.code,
    required this.name,
    required this.flag,
    required this.fromPrice,
    required this.planCount,
    required this.networks,
  });
  final String code;
  final String name;
  final String flag;
  final int fromPrice; // cents
  final int planCount;
  final List<Network> networks;

  factory Destination.fromJson(Map<String, dynamic> j) => Destination(
    code: j['code'],
    name: j['name'],
    flag: j['flag'],
    fromPrice: j['fromPrice'],
    planCount: j['planCount'],
    networks: Network.list(j['networks']),
  );
}

class Plan {
  const Plan({
    required this.slug,
    required this.name,
    required this.kind,
    required this.region,
    required this.countryCount,
    required this.data,
    required this.days,
    required this.price,
    required this.currency,
    required this.networks,
    this.charge,
  });
  final String slug;
  final String name;
  final String kind; // country, regional, global
  final String region;
  final int countryCount;
  final String data; // "1 GB"
  final int days;
  final int price; // cents
  final String currency;
  final List<Network> networks;

  /// What checkout collects when it differs from price, e.g. (819000, NGN).
  final (int, String)? charge;

  bool get isCountry => kind == 'country';

  factory Plan.fromJson(Map<String, dynamic> j) => Plan(
    slug: j['slug'],
    name: j['name'],
    kind: j['kind'],
    region: j['region'] ?? '',
    countryCount: j['countryCount'],
    data: j['data'],
    days: j['days'],
    price: j['price'],
    currency: j['currency'],
    networks: Network.list(j['networks']),
    charge: j['charge'] == null ? null : (j['charge']['amount'] as int, j['charge']['currency'] as String),
  );
}

class Order {
  const Order({
    required this.id,
    required this.status,
    required this.planName,
    required this.countryCode,
    required this.amount,
    required this.currency,
    required this.createdAt,
  });
  final String id;
  final String status; // pending, paid, processing, completed, failed
  final String planName;
  final String countryCode;
  final int amount; // cents
  final String currency;
  final DateTime createdAt;

  bool get inProgress => status == 'paid' || status == 'processing';

  factory Order.fromJson(Map<String, dynamic> j) => Order(
    id: j['id'],
    status: j['status'],
    planName: j['planName'],
    countryCode: j['countryCode'],
    amount: j['amount'],
    currency: j['currency'],
    createdAt: DateTime.parse(j['createdAt']),
  );
}

class Esim {
  const Esim({
    required this.id,
    required this.planName,
    required this.countryCode,
    required this.iccid,
    required this.activationCode,
    required this.qrCodeUrl,
    required this.status,
    required this.totalBytes,
    required this.usedBytes,
    required this.expiresAt,
    required this.syncedAt,
    required this.createdAt,
  });
  final String id;
  final String planName;
  final String countryCode;
  final String iccid;
  final String activationCode; // LPA:1$smdp$matchingId
  final String qrCodeUrl;
  final String status; // ready, installed, active, depleted, expired, ...
  final int totalBytes;
  final int usedBytes;
  final DateTime? expiresAt;
  final DateTime syncedAt;
  final DateTime createdAt;

  bool get usable => const {'ready', 'installed', 'active'}.contains(status);
  int get leftBytes => (totalBytes - usedBytes).clamp(0, totalBytes);

  /// The two values phones ask for when the QR code can't be scanned.
  ({String smdp, String matchingId}) get manualCodes {
    final parts = activationCode.split(r'$');
    return (smdp: parts.length > 1 ? parts[1] : '', matchingId: parts.length > 2 ? parts[2] : '');
  }

  factory Esim.fromJson(Map<String, dynamic> j) => Esim(
    id: j['id'],
    planName: j['planName'],
    countryCode: j['countryCode'],
    iccid: j['iccid'],
    activationCode: j['activationCode'],
    qrCodeUrl: j['qrCodeUrl'],
    status: j['status'],
    totalBytes: j['totalBytes'],
    usedBytes: j['usedBytes'],
    expiresAt: j['expiresAt'] == null ? null : DateTime.parse(j['expiresAt']),
    syncedAt: DateTime.parse(j['syncedAt']),
    createdAt: DateTime.parse(j['createdAt']),
  );
}
