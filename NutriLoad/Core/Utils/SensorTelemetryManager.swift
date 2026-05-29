import Foundation
import CoreMotion
import Combine

@MainActor
final class SensorTelemetryManager: ObservableObject {
    static let shared = SensorTelemetryManager()
    
    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()
    
    @Published var isTracking: Bool = false
    @Published var hasAnomaly: Bool = false
    @Published var stabilityScore: Double = 100.0 // 100.0 = Perfect lifting form
    
    // G-Force spike threshold that defines a "form breakdown" or severe tremor
    private let anomalyThreshold: Double = 2.5
    
    private init() {}
    
    func startTracking() {
        // Fallback for Simulator where CoreMotion isn't fully available
        guard motionManager.isAccelerometerAvailable else {
            print("Telemetry warning: Accelerometer is not available on this device.")
            return
        }
        
        motionManager.accelerometerUpdateInterval = 1.0 / 60.0 // 60 Hz sampling rate
        isTracking = true
        hasAnomaly = false
        stabilityScore = 100.0
        
        motionManager.startAccelerometerUpdates(to: queue) { [weak self] data, error in
            guard let data = data, error == nil else { return }
            self?.analyzeMotion(acceleration: data.acceleration)
        }
    }
    
    func stopTracking() {
        motionManager.stopAccelerometerUpdates()
        self.isTracking = false
    }
    
    private func analyzeMotion(acceleration: CMAcceleration) {
        // Calculate the magnitude of the acceleration vector
        let gForce = sqrt(pow(acceleration.x, 2) + pow(acceleration.y, 2) + pow(acceleration.z, 2))
        
        // Subtract gravity (1.0) to find the dynamic acceleration applied by the user
        let dynamicAcceleration = abs(gForce - 1.0)
        
        Task { @MainActor in
            // If acceleration spikes violently, flag as an anomaly
            if dynamicAcceleration > self.anomalyThreshold {
                self.hasAnomaly = true
                
                // Degrade the stability score slightly for each anomaly frame
                self.stabilityScore = max(0, self.stabilityScore - 2.5)
                
                print("⚠️ Form Anomaly Detected! Dynamic G: \(String(format: "%.2f", dynamicAcceleration))")
            }
        }
    }
}
