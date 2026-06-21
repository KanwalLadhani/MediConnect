import 'dart:math' as math;
import 'dart:typed_data';

import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/available_worker.dart';
import '../models/service_category.dart';
import '../models/service_request_result.dart';
import 'supabase_status.dart';

class ServiceRequestRepository {
  Future<List<ServiceCategory>> fetchCategories() async {
    if (!SupabaseStatus.isConfigured) {
      return _demoCategories;
    }

    final data = await SupabaseStatus.client
        .from('service_categories')
        .select('id, name_en, description_en')
        .eq('is_active', true)
        .order('name_en');

    return data
        .map<ServiceCategory>(
          ServiceCategory.fromMap,
        )
        .toList();
  }

  Future<ServiceRequestResult> createRequest({
    required ServiceCategory category,
    required String description,
    required String address,
    required String city,
    double? latitude,
    double? longitude,
    Uint8List? imageBytes,
    String? imageExtension,
  }) async {
    final normalizedRequest = normalizeServiceRequestFields(
      category: category,
      description: description,
      address: address,
      city: city,
      latitude: latitude,
      longitude: longitude,
    );
    final validationError = serviceRequestValidationError(
      normalizedRequest,
    );
    if (validationError != null) {
      throw ArgumentError(serviceRequestValidationMessage(validationError));
    }

    if (!SupabaseStatus.isConfigured) {
      return ServiceRequestResult(
        requestId: 'demo-request',
        patientId: 'demo-patient',
        category: category,
        description: normalizedRequest.description,
        address: normalizedRequest.address,
        city: normalizedRequest.city,
        latitude: normalizedRequest.latitude,
        longitude: normalizedRequest.longitude,
        workers: availableWorkersForRequest(
          workers: _demoWorkers,
          requestCity: normalizedRequest.city,
          requestLatitude: normalizedRequest.latitude,
          requestLongitude: normalizedRequest.longitude,
        ),
      );
    }

    final client = SupabaseStatus.client;
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Please log in before creating a service request.');
    }

    final patient = await client
        .from('patients')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();

    if (patient == null) {
      throw StateError(
        'Complete patient onboarding before requesting service.',
      );
    }

    final location = await client
        .from('locations')
        .insert({
          'user_id': user.id,
          'label': 'service request',
          'address': normalizedRequest.address,
          'city': normalizedRequest.city,
          'latitude': normalizedRequest.latitude,
          'longitude': normalizedRequest.longitude,
          'is_default': false,
        })
        .select('id')
        .single();

    final imagePath = imageBytes == null
        ? null
        : await _uploadServiceRequestImage(
            client: client,
            userId: user.id,
            bytes: imageBytes,
            extension: imageExtension ?? 'jpg',
          );

    final request = await client
        .from('service_requests')
        .insert({
          'patient_id': patient['id'],
          'service_category_id': normalizedRequest.categoryId,
          'description': normalizedRequest.description,
          'image_path': imagePath,
          'location_id': location['id'],
          'status': 'searching',
        })
        .select('id')
        .single();

    final workers = await fetchAvailableWorkers(
      categoryId: normalizedRequest.categoryId,
      city: normalizedRequest.city,
      latitude: normalizedRequest.latitude,
      longitude: normalizedRequest.longitude,
    );

    return ServiceRequestResult(
      requestId: request['id'] as String,
      patientId: patient['id'] as String,
      category: category,
      description: normalizedRequest.description,
      address: normalizedRequest.address,
      city: normalizedRequest.city,
      latitude: normalizedRequest.latitude,
      longitude: normalizedRequest.longitude,
      imagePath: imagePath,
      workers: workers,
    );
  }

  Future<List<AvailableWorker>> fetchAvailableWorkers({
    required String categoryId,
    required String city,
    double? latitude,
    double? longitude,
  }) async {
    final normalizedCity = normalizeCity(city);
    final normalizedCoordinates = normalizeCoordinates(
      latitude: latitude,
      longitude: longitude,
    );

    if (!SupabaseStatus.isConfigured) {
      return availableWorkersForRequest(
        workers: _demoWorkers,
        requestCity: normalizedCity,
        requestLatitude: normalizedCoordinates?.latitude,
        requestLongitude: normalizedCoordinates?.longitude,
      );
    }

    final rows = await SupabaseStatus.client.rpc(
      'find_available_workers_for_request',
      params: {
        'request_category_id': categoryId,
        'request_city': normalizedCity,
        'request_latitude': normalizedCoordinates?.latitude,
        'request_longitude': normalizedCoordinates?.longitude,
        'max_distance_km': defaultWorkerSearchRadiusKm,
      },
    );

    return rows.cast<Map<String, dynamic>>().map((row) {
      return AvailableWorker(
        id: row['worker_id'] as String,
        name: row['full_name'] as String? ?? 'Verified worker',
        workerType: _labelize(row['worker_type'] as String? ?? 'other'),
        city: row['city'] as String? ?? '',
        serviceArea: row['service_area'] as String?,
        pricePkr: row['base_price_pkr'] as int? ?? 0,
        rating: (row['average_rating'] as num? ?? 0).toDouble(),
        totalReviews: row['total_reviews'] as int? ?? 0,
        phone: row['phone'] as String?,
        latitude: (row['latitude'] as num?)?.toDouble(),
        longitude: (row['longitude'] as num?)?.toDouble(),
        distanceKm: (row['distance_km'] as num?)?.toDouble(),
        etaMinutes: row['eta_minutes'] as int?,
      );
    }).toList();
  }

  Future<ServiceRequestLocationDefaults?>
      fetchCurrentPatientLocationDefaults() async {
    if (!SupabaseStatus.isConfigured) {
      return const ServiceRequestLocationDefaults(
        address: 'Demo House, Block 7',
        city: 'Karachi',
      );
    }

    final user = SupabaseStatus.client.auth.currentUser;
    if (user == null) {
      return null;
    }

    final patient = await SupabaseStatus.client
        .from('patients')
        .select('address, city')
        .eq('user_id', user.id)
        .maybeSingle();

    if (patient == null) {
      return null;
    }

    final city = (patient['city'] as String? ?? '').trim();
    if (city.isEmpty) {
      return null;
    }

    return ServiceRequestLocationDefaults(
      address: (patient['address'] as String? ?? '').trim(),
      city: city,
    );
  }

  Future<ServiceRequestLocationDefaults>
      fetchCurrentGpsLocationDefaults() async {
    final existingDefaults = await fetchCurrentPatientLocationDefaults();
    final position = await _currentPosition();
    final fallbackAddress = existingDefaults?.address.trim();

    return ServiceRequestLocationDefaults(
      address: fallbackAddress == null || fallbackAddress.isEmpty
          ? 'Current GPS location'
          : fallbackAddress,
      city: existingDefaults?.city ?? '',
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<String> hireWorker({
    required ServiceRequestResult request,
    required AvailableWorker worker,
  }) async {
    if (!SupabaseStatus.isConfigured) {
      return 'demo-offer';
    }

    final client = SupabaseStatus.client;
    final offer = await client
        .from('service_request_offers')
        .insert({
          'service_request_id': request.requestId,
          'patient_id': request.patientId,
          'worker_id': worker.id,
          'quoted_price_pkr': worker.pricePkr,
          'status': 'pending',
        })
        .select('id')
        .single();

    await client
        .from('service_requests')
        .update({'status': 'offered'}).eq('id', request.requestId);

    return offer['id'] as String;
  }

  Future<String> _uploadServiceRequestImage({
    required SupabaseClient client,
    required String userId,
    required Uint8List bytes,
    required String extension,
  }) {
    final normalizedExtension = normalizedServiceRequestImageExtension(
      extension,
    );
    if (serviceRequestImageExtensionError(normalizedExtension) != null) {
      throw ArgumentError('Unsupported image type.');
    }

    final path =
        '$userId/${DateTime.now().millisecondsSinceEpoch}.$normalizedExtension';

    return client.storage.from('service-request-images').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType:
                normalizedExtension == 'png' ? 'image/png' : 'image/jpeg',
          ),
        );
  }

  Future<Position> _currentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw StateError('Turn on location services or enter address manually.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError(
        'Location permission was denied. Enter address and city manually.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }
}

NormalizedServiceRequestFields normalizeServiceRequestFields({
  required ServiceCategory category,
  required String description,
  required String address,
  required String city,
  double? latitude,
  double? longitude,
}) {
  final coordinates = normalizeCoordinates(
    latitude: latitude,
    longitude: longitude,
  );
  final hasInvalidCoordinates = !hasValidCoordinatePair(
    latitude: latitude,
    longitude: longitude,
  );
  return NormalizedServiceRequestFields(
    categoryId: category.id.trim(),
    description: description.trim(),
    address: address.trim(),
    city: city.trim(),
    latitude: coordinates?.latitude,
    longitude: coordinates?.longitude,
    hasInvalidCoordinates: hasInvalidCoordinates,
  );
}

ServiceRequestValidationError? serviceRequestValidationError(
  NormalizedServiceRequestFields request,
) {
  if (request.categoryId.isEmpty) {
    return ServiceRequestValidationError.missingCategory;
  }
  if (request.description.isEmpty) {
    return ServiceRequestValidationError.missingDescription;
  }
  if (request.address.isEmpty) {
    return ServiceRequestValidationError.missingAddress;
  }
  if (request.city.isEmpty) {
    return ServiceRequestValidationError.missingCity;
  }
  if (request.hasInvalidCoordinates) {
    return ServiceRequestValidationError.invalidCoordinates;
  }

  return null;
}

String serviceRequestValidationMessage(ServiceRequestValidationError error) {
  return switch (error) {
    ServiceRequestValidationError.missingCategory => 'Choose a service.',
    ServiceRequestValidationError.missingDescription =>
      'Describe the service need.',
    ServiceRequestValidationError.missingAddress =>
      'Enter the service address.',
    ServiceRequestValidationError.missingCity => 'Enter the service city.',
    ServiceRequestValidationError.invalidCoordinates =>
      'Use a valid service location.',
  };
}

class NormalizedServiceRequestFields {
  const NormalizedServiceRequestFields({
    required this.categoryId,
    required this.description,
    required this.address,
    required this.city,
    this.latitude,
    this.longitude,
    this.hasInvalidCoordinates = false,
  });

  final String categoryId;
  final String description;
  final String address;
  final String city;
  final double? latitude;
  final double? longitude;
  final bool hasInvalidCoordinates;
}

enum ServiceRequestValidationError {
  missingCategory,
  missingDescription,
  missingAddress,
  missingCity,
  invalidCoordinates,
}

String normalizedServiceRequestImageExtension(String? extension) {
  return (extension ?? '').replaceAll('.', '').trim().toLowerCase();
}

ServiceRequestImageExtensionError? serviceRequestImageExtensionError(
  String? extension,
) {
  final normalizedExtension = normalizedServiceRequestImageExtension(extension);
  if (!{'jpg', 'jpeg', 'png'}.contains(normalizedExtension)) {
    return ServiceRequestImageExtensionError.unsupported;
  }

  return null;
}

enum ServiceRequestImageExtensionError {
  unsupported,
}

String normalizeCity(String city) {
  return city.trim().replaceAll(RegExp(r'\s+'), ' ');
}

bool workerMatchesRequestCity({
  required String workerCity,
  required String requestCity,
}) {
  final normalizedWorkerCity = normalizeCity(workerCity).toLowerCase();
  final normalizedRequestCity = normalizeCity(requestCity).toLowerCase();
  return normalizedWorkerCity.isNotEmpty &&
      normalizedWorkerCity == normalizedRequestCity;
}

const defaultWorkerSearchRadiusKm = 30.0;

class ServiceRequestCoordinates {
  const ServiceRequestCoordinates({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

ServiceRequestCoordinates? normalizeCoordinates({
  required double? latitude,
  required double? longitude,
}) {
  if (latitude == null && longitude == null) {
    return null;
  }

  if (!hasValidCoordinatePair(latitude: latitude, longitude: longitude)) {
    return null;
  }

  return ServiceRequestCoordinates(
    latitude: double.parse(latitude!.toStringAsFixed(7)),
    longitude: double.parse(longitude!.toStringAsFixed(7)),
  );
}

bool hasValidCoordinatePair({
  required double? latitude,
  required double? longitude,
}) {
  if (latitude == null && longitude == null) {
    return true;
  }
  if (latitude == null || longitude == null) {
    return false;
  }

  return latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}

double distanceBetweenKm({
  required double fromLatitude,
  required double fromLongitude,
  required double toLatitude,
  required double toLongitude,
}) {
  const earthRadiusKm = 6371.0;
  final latitudeDelta = _degreesToRadians(toLatitude - fromLatitude);
  final longitudeDelta = _degreesToRadians(toLongitude - fromLongitude);
  final fromLatitudeRadians = _degreesToRadians(fromLatitude);
  final toLatitudeRadians = _degreesToRadians(toLatitude);
  final a = math.pow(math.sin(latitudeDelta / 2), 2) +
      math.cos(fromLatitudeRadians) *
          math.cos(toLatitudeRadians) *
          math.pow(math.sin(longitudeDelta / 2), 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

int estimatedEtaMinutes(double distanceKm) {
  final travelMinutes = (distanceKm / 22 * 60).ceil();
  return math.max(10, travelMinutes + 5);
}

List<AvailableWorker> availableWorkersForRequest({
  required List<AvailableWorker> workers,
  required String requestCity,
  double? requestLatitude,
  double? requestLongitude,
  double maxDistanceKm = defaultWorkerSearchRadiusKm,
}) {
  final coordinates = normalizeCoordinates(
    latitude: requestLatitude,
    longitude: requestLongitude,
  );

  if (coordinates == null) {
    return workers
        .where(
          (worker) => workerMatchesRequestCity(
            workerCity: worker.city,
            requestCity: requestCity,
          ),
        )
        .toList()
      ..sort(_compareWorkersByRating);
  }

  return workers
      .where(
        (worker) => worker.latitude != null && worker.longitude != null,
      )
      .map((worker) {
        final distanceKm = distanceBetweenKm(
          fromLatitude: coordinates.latitude,
          fromLongitude: coordinates.longitude,
          toLatitude: worker.latitude!,
          toLongitude: worker.longitude!,
        );
        return AvailableWorker(
          id: worker.id,
          name: worker.name,
          workerType: worker.workerType,
          city: worker.city,
          serviceArea: worker.serviceArea,
          pricePkr: worker.pricePkr,
          rating: worker.rating,
          totalReviews: worker.totalReviews,
          phone: worker.phone,
          latitude: worker.latitude,
          longitude: worker.longitude,
          distanceKm: distanceKm,
          etaMinutes: estimatedEtaMinutes(distanceKm),
        );
      })
      .where((worker) => worker.distanceKm! <= maxDistanceKm)
      .toList()
    ..sort(_compareWorkersByDistance);
}

int _compareWorkersByDistance(AvailableWorker a, AvailableWorker b) {
  final distanceCompare = a.distanceKm!.compareTo(b.distanceKm!);
  if (distanceCompare != 0) {
    return distanceCompare;
  }

  return _compareWorkersByRating(a, b);
}

int _compareWorkersByRating(AvailableWorker a, AvailableWorker b) {
  final ratingCompare = b.rating.compareTo(a.rating);
  if (ratingCompare != 0) {
    return ratingCompare;
  }

  return b.totalReviews.compareTo(a.totalReviews);
}

double _degreesToRadians(double degrees) => degrees * math.pi / 180;

class ServiceRequestLocationDefaults {
  const ServiceRequestLocationDefaults({
    required this.address,
    required this.city,
    this.latitude,
    this.longitude,
  });

  final String address;
  final String city;
  final double? latitude;
  final double? longitude;
}

String _labelize(String value) {
  return value
      .split('_')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

const _demoCategories = [
  ServiceCategory(
    id: 'demo-bandage',
    name: 'Bandage',
    description: 'Basic bandage and wound dressing support.',
  ),
  ServiceCategory(
    id: 'demo-injection',
    name: 'Injection',
    description: 'At-home injection service by a verified worker.',
  ),
  ServiceCategory(
    id: 'demo-drip',
    name: 'Drip',
    description: 'IV drip support where medically appropriate.',
  ),
  ServiceCategory(
    id: 'demo-blood-sample',
    name: 'Blood Sample',
    description: 'Blood sample collection from home.',
  ),
  ServiceCategory(
    id: 'demo-basic-checkup',
    name: 'Basic Checkup',
    description: 'General basic health checkup at home.',
  ),
  ServiceCategory(
    id: 'demo-wound-care',
    name: 'Wound Care',
    description: 'Basic wound cleaning and care.',
  ),
];

const _demoWorkers = [
  AvailableWorker(
    id: 'demo-worker-1',
    name: 'Ayesha Khan',
    workerType: 'Nurse',
    city: 'Karachi',
    serviceArea: 'Gulshan-e-Iqbal',
    pricePkr: 1200,
    rating: 4.8,
    totalReviews: 42,
    phone: '+92 300 0000000',
    latitude: 24.9176,
    longitude: 67.0971,
  ),
  AvailableWorker(
    id: 'demo-worker-2',
    name: 'Bilal Ahmed',
    workerType: 'Dispenser',
    city: 'Karachi',
    serviceArea: 'PECHS',
    pricePkr: 950,
    rating: 4.6,
    totalReviews: 31,
    phone: '+92 301 0000000',
    latitude: 24.8607,
    longitude: 67.0599,
  ),
];
