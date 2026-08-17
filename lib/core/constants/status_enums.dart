enum UserRole {
  customer,
  admin,
  mover;

  static UserRole fromString(String value) {
    switch (value) {
      case 'customer':
        return UserRole.customer;

      case 'admin':
        return UserRole.admin;

      case 'mover':
        return UserRole.mover;

      default:
        throw ArgumentError('Unknown user role: $value');
    }
  }

  String get value => name;
}
