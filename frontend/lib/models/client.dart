class Client {
  final int? id;
  final String code;
  final String type;
  final String name;
  final String? commercialName;
  final String? documentNumber;
  final String? contactName;
  final String? contactPosition;
  final String? phone;
  final String? mobile;
  final String? whatsapp;
  final String? email;
  final String? country;
  final String? province;
  final String? city;
  final String? sector;
  final String? address;
  final double creditLimit;
  final int creditDays;
  final String classification;
  final bool active;
  final String? notes;

  Client({
    this.id,
    required this.code,
    required this.type,
    required this.name,
    this.commercialName,
    this.documentNumber,
    this.contactName,
    this.contactPosition,
    this.phone,
    this.mobile,
    this.whatsapp,
    this.email,
    this.country,
    this.province,
    this.city,
    this.sector,
    this.address,
    this.creditLimit = 0.0,
    this.creditDays = 0,
    this.classification = 'bueno',
    this.active = true,
    this.notes,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      code: json['code'] ?? '',
      type: json['type'] ?? 'persona_fisica',
      name: json['name'] ?? '',
      commercialName: json['commercial_name'],
      documentNumber: json['document_number'],
      contactName: json['contact_name'],
      contactPosition: json['contact_position'],
      phone: json['phone'],
      mobile: json['mobile'],
      whatsapp: json['whatsapp'],
      email: json['email'],
      country: json['country'],
      province: json['province'],
      city: json['city'],
      sector: json['sector'],
      address: json['address'],
      creditLimit: double.tryParse(json['credit_limit']?.toString() ?? '0') ?? 0.0,
      creditDays: int.tryParse(json['credit_days']?.toString() ?? '0') ?? 0,
      classification: json['classification'] ?? 'bueno',
      active: json['active'] == true || json['active'] == 1,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'code': code,
      'type': type,
      'name': name,
      'commercial_name': commercialName,
      'document_number': documentNumber,
      'contact_name': contactName,
      'contact_position': contactPosition,
      'phone': phone,
      'mobile': mobile,
      'whatsapp': whatsapp,
      'email': email,
      'country': country,
      'province': province,
      'city': city,
      'sector': sector,
      'address': address,
      'credit_limit': creditLimit,
      'credit_days': creditDays,
      'classification': classification,
      'active': active,
      'notes': notes,
    };
  }
}
