import 'package:nextpsa/models/location/location.dart';

class LocationResponse {
  final bool success;
  final String message;
  final List<Location>? data;
  final Location? singleData;

  LocationResponse({
    required this.success,
    required this.message,
    this.data,
    this.singleData,
  });

  // ✅ For list response
  factory LocationResponse.fromJsonList(Map<String, dynamic> json) {
    final data = json['Data'] ?? json['data'];
    return LocationResponse(
      success: json['Success'] ?? json['success'] ?? false,
      message: json['Message'] ?? json['message'] ?? '',
      data: data != null
          ? (data as List).map((e) => Location.fromJson(e)).toList()
          : null,
    );
  }

  // ✅ For single item response
  factory LocationResponse.fromJsonSingle(Map<String, dynamic> json) {
    final data = json['Data'] ?? json['data'];
    return LocationResponse(
      success: json['Success'] ?? json['success'] ?? false,
      message: json['Message'] ?? json['message'] ?? '',
      singleData: data != null ? Location.fromJson(data) : null,
    );
  }

  // ✅ For delete response
  factory LocationResponse.fromJsonNoData(Map<String, dynamic> json) {
    return LocationResponse(
      success: json['Success'] ?? json['success'] ?? false,
      message: json['Message'] ?? json['message'] ?? '',
    );
  }
}

