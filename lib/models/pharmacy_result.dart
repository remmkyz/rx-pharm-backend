import 'package:latlong2/latlong.dart';

/// Represents one drugstore/pharmacy search result.
class PharmacyResult {
  final String name;
  final double rating;
  final int reviewCount;
  final String category;
  final String? phone;
  final bool hasWebsite;
  final LatLng? location;
  final String? websiteUrl;

  const PharmacyResult({
    required this.name,
    required this.rating,
    required this.reviewCount,
    required this.category,
    this.phone,
    this.hasWebsite = true,
    this.location,
    this.websiteUrl,
  });
}