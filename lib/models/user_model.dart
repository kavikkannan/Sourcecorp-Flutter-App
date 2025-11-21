class UserModel {
  final int id;
  final String name;
  final String email;
  final String number;
  final bool isAdmin;
  final String role;
  final int noOfFiles;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.number,
    required this.isAdmin,
    required this.role,
    required this.noOfFiles,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['ID'] ?? json['id'] ?? 0,
      name: json['Name'] ?? json['name'] ?? '',
      email: json['Email'] ?? json['email'] ?? '',
      number: json['Number'] ?? json['number'] ?? '',
      isAdmin: json['IsAdmin'] ?? json['isAdmin'] ?? json['is_admin'] ?? false,
      role: json['Role'] ?? json['role'] ?? '',
      noOfFiles: json['NoOfFiles'] ?? json['noOfFiles'] ?? json['no_of_files'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'number': number,
      'isAdmin': isAdmin,
      'role': role,
      'noOfFiles': noOfFiles,
    };
  }
}

