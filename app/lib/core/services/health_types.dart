import 'package:health/health.dart';

/// The set of HealthKit data types XPulse syncs in v1.
///
/// All are HKQuantityType — single numeric value per sample. Workouts and
/// sleep (HKCategoryType / HKWorkoutType) are intentionally deferred; they
/// need different value extraction and would complicate the backend's
/// generic `value: float` schema.
const v1HealthTypes = <HealthDataType>[
  // Activity
  HealthDataType.STEPS,
  HealthDataType.DISTANCE_WALKING_RUNNING,
  HealthDataType.FLIGHTS_CLIMBED,
  HealthDataType.ACTIVE_ENERGY_BURNED,
  HealthDataType.BASAL_ENERGY_BURNED,
  HealthDataType.EXERCISE_TIME,
  // Vitals
  HealthDataType.HEART_RATE,
  HealthDataType.RESTING_HEART_RATE,
  HealthDataType.HEART_RATE_VARIABILITY_SDNN,
  HealthDataType.RESPIRATORY_RATE,
  HealthDataType.BLOOD_OXYGEN,
  // Body
  HealthDataType.BODY_MASS_INDEX,
  HealthDataType.BODY_FAT_PERCENTAGE,
  HealthDataType.LEAN_BODY_MASS,
  HealthDataType.WEIGHT,
  HealthDataType.HEIGHT,
  HealthDataType.BODY_TEMPERATURE,
  HealthDataType.WALKING_HEART_RATE,
  HealthDataType.TOTAL_CALORIES_BURNED,
];

/// All types are read-only for now.
List<HealthDataAccess> get v1HealthPermissions =>
    List.filled(v1HealthTypes.length, HealthDataAccess.READ);
