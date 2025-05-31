class User {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String image;
  final String? phone;
  final String? address;
  final String? company;
  final int? age;
  final String? gender;
  final String? domain;
  final String? university;
  final String? birthDate;
  final String? bloodGroup;
  final String? eyeColor;
  final Map<String, dynamic>? hair;
  final Map<String, dynamic>? companyDetails;
  final Map<String, dynamic>? addressDetails;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.image,
    this.phone,
    this.address,
    this.company,
    this.age,
    this.gender,
    this.domain,
    this.university,
    this.birthDate,
    this.bloodGroup,
    this.eyeColor,
    this.hair,
    this.companyDetails,
    this.addressDetails,
  });

  String get fullName => '$firstName $lastName';

  String get formattedBirthDate {
    if (birthDate == null) return 'N/A';
    try {
      final date = DateTime.parse(birthDate!);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return birthDate!;
    }
  }

  String get formattedAddress {
    if (addressDetails == null) return address ?? 'N/A';
    final addr = addressDetails!;
    return '${addr['address'] ?? ''}, ${addr['city'] ?? ''}, ${addr['state'] ?? ''} ${addr['postalCode'] ?? ''}';
  }

  String get formattedCompany {
    if (companyDetails == null) return company ?? 'N/A';
    final comp = companyDetails!;
    return '${comp['title'] ?? ''} at ${comp['name'] ?? ''} (${comp['department'] ?? ''})';
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      image: json['image'],
      phone: json['phone'],
      age: json['age'],
      gender: json['gender'],
      domain: json['domain'],
      university: json['university'],
      birthDate: json['birthDate'],
      bloodGroup: json['bloodGroup'],
      eyeColor: json['eyeColor'],
      hair: json['hair'],
      addressDetails: json['address'],
      companyDetails: json['company'],
      address: json['address'] != null
          ? '${json['address']['address']}, ${json['address']['city']}'
          : null,
      company: json['company'] != null ? json['company']['name'] : null,
    );
  }
}
