// The user's dating profile, collected during onboarding so the coach can
// ground advice in their specifics (gender, age, who they want, their goal,
// and which app they're on) — per the PRD voice guidelines.

enum Gender {
  male('Male'),
  female('Female'),
  nonbinary('Non-binary');

  const Gender(this.label);
  final String label;
}

enum InterestedIn {
  women('Women'),
  men('Men'),
  everyone('Everyone');

  const InterestedIn(this.label);
  final String label;
}

enum DatingGoal {
  serious('Something serious'),
  casual('Casual dating'),
  moreMatches('More matches'),
  unsure('Still figuring it out');

  const DatingGoal(this.label);
  final String label;
}

enum DatingApp {
  hinge('Hinge'),
  tinder('Tinder'),
  bumble('Bumble'),
  raya('Raya'),
  other('Other');

  const DatingApp(this.label);
  final String label;
}

T _enumFromName<T extends Enum>(List<T> values, String? name, T fallback) {
  return values.firstWhere((e) => e.name == name, orElse: () => fallback);
}

class UserProfile {
  const UserProfile({
    required this.gender,
    required this.age,
    required this.interestedIn,
    required this.goal,
    required this.app,
    this.city,
  });

  final Gender gender;
  final int age;
  final InterestedIn interestedIn;
  final DatingGoal goal;
  final DatingApp app;
  final String? city;

  /// A one-line summary the coach uses to personalise its advice.
  String get summary {
    final place = (city != null && city!.trim().isNotEmpty) ? ' in ${city!.trim()}' : '';
    return '$age-year-old ${gender.label.toLowerCase()}$place, interested in '
        '${interestedIn.label.toLowerCase()}, looking for ${goal.label.toLowerCase()}, '
        'on ${app.label}';
  }

  Map<String, dynamic> toJson() => {
        'gender': gender.name,
        'age': age,
        'interestedIn': interestedIn.name,
        'goal': goal.name,
        'app': app.name,
        'city': city,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        gender: _enumFromName(Gender.values, json['gender'] as String?, Gender.male),
        age: (json['age'] as num?)?.toInt() ?? 0,
        interestedIn: _enumFromName(
            InterestedIn.values, json['interestedIn'] as String?, InterestedIn.everyone),
        goal: _enumFromName(DatingGoal.values, json['goal'] as String?, DatingGoal.unsure),
        app: _enumFromName(DatingApp.values, json['app'] as String?, DatingApp.other),
        city: json['city'] as String?,
      );
}
