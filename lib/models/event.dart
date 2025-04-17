class Event {
  final int id;
  final String title;
  final String coverImage;
  final String description;
  final String organizer;
  final String location;
  final bool odProvided;
  final String duration;
  final String enrollmentCriteria;
  final String registrationLink;
  final double price; // Price in RITZ, 0 for free events

  Event({
    required this.id,
    required this.title,
    required this.coverImage,
    required this.description,
    required this.organizer,
    required this.location,
    required this.odProvided,
    required this.duration,
    required this.enrollmentCriteria,
    required this.registrationLink,
    required this.price,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      coverImage: json['cover_image'],
      description: json['description'],
      organizer: json['organizer'],
      location: json['location'],
      odProvided: json['od_provided'],
      duration: json['duration'],
      enrollmentCriteria: json['enrollment_criteria'],
      registrationLink: json['registration_link'],
      price: (json['price'] as num).toDouble(),
    );
  }
}
