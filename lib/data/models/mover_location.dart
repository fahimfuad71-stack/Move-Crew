class MoverLocation {
  final String? id;
  final String assignmentId;
  final String moverId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime? recordedAt;

  MoverLocation({
    this.id,
    required this.assignmentId,
    required this.moverId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.recordedAt,
  });

  factory MoverLocation.fromMap(Map<String, dynamic> map) {
    return MoverLocation(
      id: map['id'],
      assignmentId: map['assignment_id'],
      moverId: map['mover_id'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      accuracy: map['accuracy'],
      recordedAt: map['recorded_at'] != null
          ? DateTime.parse(map['recorded_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'assignment_id': assignmentId,
      'mover_id': moverId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'recorded_at': recordedAt?.toIso8601String(),
    };
  }
}
