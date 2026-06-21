import 'package:flutter_test/flutter_test.dart';
import 'package:mediconnect/models/available_worker.dart';
import 'package:mediconnect/models/service_category.dart';
import 'package:mediconnect/services/service_request_repository.dart';

void main() {
  const category = ServiceCategory(
    id: ' category-id ',
    name: 'Bandage',
  );

  group('serviceRequestValidationError', () {
    test('allows complete request fields after normalization', () {
      final request = normalizeServiceRequestFields(
        category: category,
        description: '  Dressing change needed  ',
        address: '  House 12, Block 4  ',
        city: '  Karachi  ',
      );

      expect(serviceRequestValidationError(request), isNull);
      expect(request.categoryId, 'category-id');
      expect(request.description, 'Dressing change needed');
      expect(request.address, 'House 12, Block 4');
      expect(request.city, 'Karachi');
    });

    test('normalizes optional GPS coordinates', () {
      final request = normalizeServiceRequestFields(
        category: category,
        description: 'Dressing change needed',
        address: 'House 12, Block 4',
        city: 'Karachi',
        latitude: 24.917612345,
        longitude: 67.097176543,
      );

      expect(serviceRequestValidationError(request), isNull);
      expect(request.latitude, 24.9176123);
      expect(request.longitude, 67.0971765);
    });

    test('rejects missing category, description, address, city, and bad GPS',
        () {
      ServiceRequestValidationError? errorFor({
        String categoryId = 'category-id',
        String description = 'Need injection support',
        String address = 'House 1',
        String city = 'Karachi',
        double? latitude,
        double? longitude,
      }) {
        return serviceRequestValidationError(
          normalizeServiceRequestFields(
            category: ServiceCategory(id: categoryId, name: 'Injection'),
            description: description,
            address: address,
            city: city,
            latitude: latitude,
            longitude: longitude,
          ),
        );
      }

      expect(
        errorFor(categoryId: ' '),
        ServiceRequestValidationError.missingCategory,
      );
      expect(
        errorFor(description: ' '),
        ServiceRequestValidationError.missingDescription,
      );
      expect(
        errorFor(address: ' '),
        ServiceRequestValidationError.missingAddress,
      );
      expect(
        errorFor(city: ' '),
        ServiceRequestValidationError.missingCity,
      );
      expect(
        errorFor(latitude: 91, longitude: 67),
        ServiceRequestValidationError.invalidCoordinates,
      );
      expect(
        errorFor(latitude: 24.9),
        ServiceRequestValidationError.invalidCoordinates,
      );
    });

    test('createRequest blocks invalid fields before demo or Supabase path',
        () {
      expect(
        () => ServiceRequestRepository().createRequest(
          category: category,
          description: '',
          address: 'House 12',
          city: 'Karachi',
        ),
        throwsArgumentError,
      );
    });
  });

  group('serviceRequestImageExtensionError', () {
    test('allows jpg, jpeg, and png extensions after normalization', () {
      expect(serviceRequestImageExtensionError('jpg'), isNull);
      expect(serviceRequestImageExtensionError('.JPEG'), isNull);
      expect(serviceRequestImageExtensionError(' png '), isNull);
      expect(normalizedServiceRequestImageExtension('.JPEG'), 'jpeg');
    });

    test('rejects missing and unsupported image extensions', () {
      expect(
        serviceRequestImageExtensionError(null),
        ServiceRequestImageExtensionError.unsupported,
      );
      expect(
        serviceRequestImageExtensionError(''),
        ServiceRequestImageExtensionError.unsupported,
      );
      expect(
        serviceRequestImageExtensionError('gif'),
        ServiceRequestImageExtensionError.unsupported,
      );
      expect(
        serviceRequestImageExtensionError('pdf'),
        ServiceRequestImageExtensionError.unsupported,
      );
    });
  });

  group('workerMatchesRequestCity', () {
    test('allows workers from the requested city after normalization', () {
      expect(
        workerMatchesRequestCity(
          workerCity: ' Karachi ',
          requestCity: 'karachi',
        ),
        isTrue,
      );
      expect(
        workerMatchesRequestCity(
          workerCity: 'Gulshan  Karachi',
          requestCity: 'Gulshan Karachi',
        ),
        isTrue,
      );
    });

    test('rejects workers from a different city', () {
      expect(
        workerMatchesRequestCity(
          workerCity: 'Karachi',
          requestCity: 'Hyderabad',
        ),
        isFalse,
      );
      expect(
        workerMatchesRequestCity(
          workerCity: '',
          requestCity: 'Hyderabad',
        ),
        isFalse,
      );
    });
  });

  group('availableWorkersForRequest', () {
    const workers = [
      AvailableWorker(
        id: 'near',
        name: 'Near Worker',
        workerType: 'Nurse',
        city: 'Karachi',
        pricePkr: 1000,
        rating: 4.5,
        totalReviews: 10,
        latitude: 24.918,
        longitude: 67.097,
      ),
      AvailableWorker(
        id: 'far',
        name: 'Far Worker',
        workerType: 'Nurse',
        city: 'Karachi',
        pricePkr: 1000,
        rating: 4.9,
        totalReviews: 50,
        latitude: 24.861,
        longitude: 67.06,
      ),
      AvailableWorker(
        id: 'other-city',
        name: 'Other City Worker',
        workerType: 'Nurse',
        city: 'Hyderabad',
        pricePkr: 1000,
        rating: 5,
        totalReviews: 100,
      ),
    ];

    test('uses city fallback and sorts by rating when GPS is unavailable', () {
      final matches = availableWorkersForRequest(
        workers: workers,
        requestCity: 'Karachi',
      );

      expect(matches.map((worker) => worker.id), ['far', 'near']);
      expect(matches.every((worker) => worker.distanceKm == null), isTrue);
    });

    test('filters and sorts by distance when GPS is available', () {
      final matches = availableWorkersForRequest(
        workers: workers,
        requestCity: 'Karachi',
        requestLatitude: 24.9176,
        requestLongitude: 67.0971,
        maxDistanceKm: 4,
      );

      expect(matches.map((worker) => worker.id), ['near']);
      expect(matches.single.distanceKm, lessThan(1));
      expect(matches.single.etaMinutes, greaterThanOrEqualTo(10));
    });

    test('calculates known nearby distances in kilometers', () {
      final distance = distanceBetweenKm(
        fromLatitude: 24.9176,
        fromLongitude: 67.0971,
        toLatitude: 24.8607,
        toLongitude: 67.0599,
      );

      expect(distance, closeTo(7.3, 0.4));
    });
  });
}
