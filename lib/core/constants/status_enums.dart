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

enum JobStatus {
  requested,
  approved,
  assigned,
  inProgress,
  completed,
  rejected;

  static JobStatus fromString(String value) {
    switch (value) {
      case 'REQUESTED':
        return JobStatus.requested;
      case 'APPROVED':
        return JobStatus.approved;
      case 'ASSIGNED':
        return JobStatus.assigned;
      case 'IN_PROGRESS':
        return JobStatus.inProgress;
      case 'COMPLETED':
        return JobStatus.completed;
      case 'REJECTED':
        return JobStatus.rejected;
      default:
        throw ArgumentError('Unknown job status: $value');
    }
  }

  String get value {
    switch (this) {
      case JobStatus.requested:
        return 'REQUESTED';
      case JobStatus.approved:
        return 'APPROVED';
      case JobStatus.assigned:
        return 'ASSIGNED';
      case JobStatus.inProgress:
        return 'IN_PROGRESS';
      case JobStatus.completed:
        return 'COMPLETED';
      case JobStatus.rejected:
        return 'REJECTED';
    }
  }
}

enum JobItemStatus {
  pending,
  collected,
  delivered;

  static JobItemStatus fromString(String value) {
    switch (value) {
      case 'PENDING':
        return JobItemStatus.pending;
      case 'COLLECTED':
        return JobItemStatus.collected;
      case 'DELIVERED':
        return JobItemStatus.delivered;
      default:
        throw ArgumentError('Unknown job item status: $value');
    }
  }

  String get value {
    switch (this) {
      case JobItemStatus.pending:
        return 'PENDING';
      case JobItemStatus.collected:
        return 'COLLECTED';
      case JobItemStatus.delivered:
        return 'DELIVERED';
    }
  }
}

enum AssignmentStatus {
  pending,
  accepted,
  rejected;

  static AssignmentStatus fromString(String value) {
    switch (value) {
      case 'PENDING':
        return AssignmentStatus.pending;
      case 'ACCEPTED':
        return AssignmentStatus.accepted;
      case 'REJECTED':
        return AssignmentStatus.rejected;
      default:
        throw ArgumentError('Unknown assignment status: $value');
    }
  }

  String get value {
    switch (this) {
      case AssignmentStatus.pending:
        return 'PENDING';
      case AssignmentStatus.accepted:
        return 'ACCEPTED';
      case AssignmentStatus.rejected:
        return 'REJECTED';
    }
  }
}
