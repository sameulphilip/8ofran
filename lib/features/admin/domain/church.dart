class Church {
  const Church({
    required this.id,
    required this.name,
    this.city = '',
    this.address = '',
    this.mapsQuery = '',
    this.phone = '',
    this.isActive = true,
  });

  final String id;
  final String name;
  final String city;
  final String address;
  final String mapsQuery;
  final String phone;
  final bool isActive;

  String get subtitle {
    if (address.isNotEmpty) return address;
    if (city.isEmpty || city == name) return '';
    return city;
  }

  String get placeLabel {
    if (address.isNotEmpty) return address;
    if (city.isNotEmpty && city != name) return '$name — $city';
    return name;
  }

  String get mapQuery {
    if (mapsQuery.isNotEmpty) return mapsQuery;
    if (address.isNotEmpty) return address;
    if (city.isNotEmpty) return '$name $city';
    return name;
  }

  bool get hasPhone => phone.trim().isNotEmpty;

  Church copyWith({
    String? id,
    String? name,
    String? city,
    String? address,
    String? mapsQuery,
    String? phone,
    bool? isActive,
  }) {
    return Church(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      address: address ?? this.address,
      mapsQuery: mapsQuery ?? this.mapsQuery,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'city': city,
    if (address.isNotEmpty) 'address': address,
    if (mapsQuery.isNotEmpty) 'mapsQuery': mapsQuery,
    if (phone.isNotEmpty) 'phone': phone,
    'isActive': isActive,
  };

  factory Church.fromJson(Map<String, dynamic> json) {
    return Church(
      id: json['id'] as String,
      name: json['name'] as String,
      city: json['city'] as String? ?? '',
      address: json['address'] as String? ?? '',
      mapsQuery: json['mapsQuery'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

Church? findChurch(Iterable<Church> churches, String? id) {
  if (id == null || id.isEmpty) return null;
  for (final church in churches) {
    if (church.id == id) return church;
  }
  return null;
}
