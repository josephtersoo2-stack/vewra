class UserModel {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final double walletBalance;
  final String? dateJoined;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.walletBalance = 0.0,
    this.dateJoined,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      walletBalance: (json['wallet_balance'] is num)
          ? (json['wallet_balance'] as num).toDouble()
          : double.tryParse(json['wallet_balance']?.toString() ?? '0') ?? 0.0,
      dateJoined: json['date_joined'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'wallet_balance': walletBalance,
      'date_joined': dateJoined,
    };
  }

  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    double? walletBalance,
    String? dateJoined,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      walletBalance: walletBalance ?? this.walletBalance,
      dateJoined: dateJoined ?? this.dateJoined,
    );
  }
}
