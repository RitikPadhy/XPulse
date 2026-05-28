import Flutter
import UIKit
import HealthKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let healthStore = HKHealthStore()
  private var channel: FlutterMethodChannel?
  private var observerQueries: [HKObserverQuery] = []

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      channel = FlutterMethodChannel(
        name: "xpulse/background_sync",
        binaryMessenger: controller.binaryMessenger
      )
      channel?.setMethodCallHandler { [weak self] call, result in
        guard let self = self else { return }
        switch call.method {
        case "startObservers":
          self.startObservers()
          result(true)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func startObservers() {
    guard HKHealthStore.isHealthDataAvailable() else { return }

    // Tear down any prior queries (e.g., if Dart re-registers after permission re-grant).
    for q in observerQueries {
      healthStore.stop(q)
    }
    observerQueries.removeAll()

    for type in v1SampleTypes() {
      let query = HKObserverQuery(sampleType: type, predicate: nil) { [weak self] _, completionHandler, error in
        guard let self = self, error == nil else {
          completionHandler()
          return
        }
        self.triggerDartSync { completionHandler() }
      }
      healthStore.execute(query)
      observerQueries.append(query)

      healthStore.enableBackgroundDelivery(for: type, frequency: .immediate) { _, _ in
        // Best-effort. If the user revokes a type, this silently no-ops.
      }
    }
  }

  private func v1SampleTypes() -> [HKQuantityType] {
    let ids: [HKQuantityTypeIdentifier] = [
      .stepCount,
      .distanceWalkingRunning,
      .flightsClimbed,
      .activeEnergyBurned,
      .basalEnergyBurned,
      .appleExerciseTime,
      .heartRate,
      .restingHeartRate,
      .heartRateVariabilitySDNN,
      .respiratoryRate,
      .oxygenSaturation,
      .bodyMassIndex,
      .bodyFatPercentage,
      .leanBodyMass,
      .bodyMass,
      .height,
      .bodyTemperature,
      .walkingHeartRateAverage,
    ]
    return ids.compactMap { HKQuantityType.quantityType(forIdentifier: $0) }
  }

  /// Invokes the Dart-side sync handler. The HKObserverQuery completion
  /// handler is called only after Dart finishes — so iOS keeps trusting us
  /// for future background wakes.
  private func triggerDartSync(completion: @escaping () -> Void) {
    DispatchQueue.main.async { [weak self] in
      guard let channel = self?.channel else {
        completion()
        return
      }
      channel.invokeMethod("syncRequested", arguments: nil) { _ in
        completion()
      }
    }
  }
}
