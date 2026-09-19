class Church {
  const Church({required this.id, required this.name, this.city = ''});

  final String id;
  final String name;
  final String city;

  String get subtitle => city.isEmpty || city == name ? '' : city;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'city': city};

  factory Church.fromJson(Map<String, dynamic> json) {
    return Church(
      id: json['id'] as String,
      name: json['name'] as String,
      city: json['city'] as String? ?? '',
    );
  }
}
