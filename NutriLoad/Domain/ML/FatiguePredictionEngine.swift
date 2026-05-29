import Foundation
import CoreML

final class FatiguePredictionEngine {
    static let shared = FatiguePredictionEngine()
    
    private init() {}
    
    func predictRecommendedTonnage(recentWorkouts: [WorkoutEntity]) -> Double {
        guard !recentWorkouts.isEmpty else {
            return 10000.0 // Default baseline tonnage
        }
        
        let totalRecentTonnage = recentWorkouts.prefix(3).reduce(0) { $0 + $1.totalTonnage }
        let averageRPE = recentWorkouts.prefix(3).compactMap { getRPE(from: $0) }.reduce(0, +) / 3.0
        
        // 🚀 GERÇEK CORE ML ENTEGRASYONU
        do {
            let config = MLModelConfiguration()
            // Xcode'un otomatik oluşturduğu FatigueRegressor sınıfını çağırıyoruz
            let model = try FatigueRegressor(configuration: config)
            
            // Python'da belirlediğimiz girdileri (recentTonnage ve avgRPE) veriyoruz
            let input = FatigueRegressorInput(recentTonnage: totalRecentTonnage, avgRPE: averageRPE)
            
            // Çıkarım (Inference) yapıyoruz
            let prediction = try model.prediction(input: input)
            
            print("AI Prediction Successful: \(prediction.recommendedTonnage) kg")
            return prediction.recommendedTonnage
            
        } catch {
            print("Core ML Error, falling back to heuristic: \(error)")
            return calculateHeuristicTonnage(totalRecentTonnage: totalRecentTonnage, avgRPE: averageRPE)
        }
    }
    
    private func calculateHeuristicTonnage(totalRecentTonnage: Double, avgRPE: Double) -> Double {
        let baseTarget = 12000.0
        if avgRPE > 8.5 {
            return baseTarget * 0.8
        }
        return baseTarget
    }
    
    private func getRPE(from workout: WorkoutEntity) -> Double? {
        guard let exercises = workout.exercises?.allObjects as? [ExerciseEntity],
              let firstExercise = exercises.first,
              let sets = firstExercise.sets?.allObjects as? [SetEntity],
              let firstSet = sets.first else {
            return nil
        }
        return firstSet.rpe
    }
}
