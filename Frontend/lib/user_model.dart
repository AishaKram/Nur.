class User {
  final String name;
  final String email;
  final String userId;  
  final String currentPhase;
  final int cycleDay;
  final int daysLeft;

  User({
    required this.name,
    required this.email,
    required this.userId,  
    required this.currentPhase,
    required this.cycleDay,
    required this.daysLeft,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      userId: json['userId'] ?? '',  
      currentPhase: json['currentPhase'] ?? 'Menstrual',
      cycleDay: json['cycleDay'] ?? 1,
      daysLeft: json['daysLeft'] ?? 5,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'userId': userId, 
    'currentPhase': currentPhase,
    'cycleDay': cycleDay,
    'daysLeft': daysLeft,
  };
}