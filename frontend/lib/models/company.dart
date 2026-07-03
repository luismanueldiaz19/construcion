class Company {
  final String name;
  final String rnc;
  final String address;
  final String phone;
  final String mobile;

  const Company({
    required this.name,
    required this.rnc,
    required this.address,
    required this.phone,
    required this.mobile,
  });

  // Instancia con los datos reales para usar en la aplicación
  static const Company current = Company(
    name: 'NEO PROJECT S.R.L',
    rnc: '131181181',
    address: 'Manolo Tavares Justo No. 15, Puerto Plata',
    phone: '809-320-1668',
    mobile: '809-223-8039',
  );

  // Puedes agregar factory de JSON si en el futuro los datos vienen del backend
  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      name: json['name'] ?? '',
      rnc: json['rnc'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      mobile: json['mobile'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'rnc': rnc,
      'address': address,
      'phone': phone,
      'mobile': mobile,
    };
  }
}
