class Space {
  final String id;
  final String name;
  final String tagline;
  final String description;
  final String image;
  final int totalSeats;
  final int availableSeats;
  final String color;
  final String gradient;
  final List<String> features;
  final List<Amenity> amenities;

  Space({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.image,
    required this.totalSeats,
    required this.availableSeats,
    required this.color,
    required this.gradient,
    required this.features,
    required this.amenities,
  });

  int get occupancyRate =>
      ((totalSeats - availableSeats) / totalSeats * 100).toInt();

  bool get isLowOccupancy => occupancyRate < 50;
}

class Amenity {
  final String icon;
  final String label;

  Amenity({required this.icon, required this.label});
}

class CoWorkingInfo {
  final String name;
  final String tagline;
  final String description;
  final String address;
  final String phone;
  final String email;
  final double rating;
  final int reviews;
  final String image;
  final String weekdayHours;
  final String weekendHours;
  final int totalSeats;
  final int availableSeats;
  final int occupancyRate;
  final List<Amenity> amenities;
  final List<String> features;

  CoWorkingInfo({
    required this.name,
    required this.tagline,
    required this.description,
    required this.address,
    required this.phone,
    required this.email,
    required this.rating,
    required this.reviews,
    required this.image,
    required this.weekdayHours,
    required this.weekendHours,
    required this.totalSeats,
    required this.availableSeats,
    required this.occupancyRate,
    required this.amenities,
    required this.features,
  });
}
