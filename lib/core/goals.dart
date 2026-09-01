import 'package:flutter/material.dart';

class Goal {
  final String key;
  final String label;
  final IconData icon;
  final List<String> tasks;

  const Goal({
    required this.key,
    required this.label,
    required this.icon,
    required this.tasks,
  });
}

class Goals {
  static const health = Goal(
    key: 'health',
    label: 'Health & Body',
    icon: Icons.favorite_outline,
    tasks: [
      'Drink 2L water',
      '10 min stretch',
      'Make your bed',
      'Eat one meal slowly',
      'Sleep by 11 PM',
    ],
  );

  static const fitness = Goal(
    key: 'fitness',
    label: 'Fitness',
    icon: Icons.fitness_center_outlined,
    tasks: [
      '20 min walk',
      '10 push-ups',
      '5 min HIIT',
      '10 squats',
      'Evening walk',
    ],
  );

  static const mindfulness = Goal(
    key: 'mindfulness',
    label: 'Mindfulness',
    icon: Icons.self_improvement_outlined,
    tasks: [
      'Meditate 5 min',
      'Journal 3 lines',
      '60s deep breathing',
      'Gratitude note',
      'No phone for 30 min',
    ],
  );

  static const learning = Goal(
    key: 'learning',
    label: 'Learning',
    icon: Icons.school_outlined,
    tasks: [
      'Read 10 pages',
      'Learn 5 new words',
      'Watch one tutorial',
      'Write notes on one idea',
      'Listen to a podcast',
    ],
  );

  static const career = Goal(
    key: 'career',
    label: 'Career',
    icon: Icons.work_outline,
    tasks: [
      'Plan top 3 priorities',
      'Clear your inbox',
      'Write one resume bullet',
      'Send one networking message',
      'Review yesterday\u2019s progress',
    ],
  );

  static const creativity = Goal(
    key: 'creativity',
    label: 'Creativity',
    icon: Icons.palette_outlined,
    tasks: [
      'Sketch 10 min',
      'Write 100 words',
      'Play an instrument 10 min',
      'Edit one photo',
      'Doodle one idea',
    ],
  );

  static const relationships = Goal(
    key: 'relationships',
    label: 'Relationships',
    icon: Icons.people_outline,
    tasks: [
      'Call one friend',
      'Message a family member',
      'Write a thank-you note',
      'Plan a meet-up',
      'Compliment someone',
    ],
  );

  static const List<Goal> all = [
    health,
    fitness,
    mindfulness,
    learning,
    career,
    creativity,
    relationships,
  ];

  static Goal? getByKey(String key) {
    for (final g in all) {
      if (g.key == key) return g;
    }
    return null;
  }
}