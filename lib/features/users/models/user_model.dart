class User {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String image;
  final String? phone;
  final String? address;
  final String? company;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.image,
    this.phone,
    this.address,
    this.company,
  });

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      image: json['image'],
      phone: json['phone'],
      address: json['address'] != null
          ? '${json['address']['address']}, ${json['address']['city']}'
          : null,
      company: json['company'] != null ? json['company']['name'] : null,
    );
  }
}
