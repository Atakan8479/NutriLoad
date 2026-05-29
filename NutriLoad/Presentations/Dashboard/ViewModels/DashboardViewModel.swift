import Foundation
import Combine

// Sadece Main Thread'de çalışmasını garanti altına alıyoruz
@MainActor
final class DashboardViewModel: ObservableObject {
    
    // UI'ın anında tepki vereceği reaktif (Published) değişkenler
    @Published var recentWorkouts: [WorkoutEntity] = []
    @Published var dailyProteinTarget: ClosedRange<Double> = 150.0...150.0
    @Published var isLoading: Bool = false
    
    // Bağımlılıkları enjekte ediyoruz (Dependency Injection)
    private let workoutRepository: WorkoutRepositoryProtocol
    private let optimizationEngine = MacroOptimizationEngine.shared
    
    // Default parametre vererek test edilebilirliği artırıyoruz
    init(workoutRepository: WorkoutRepositoryProtocol = CoreDataWorkoutRepository()) {
        self.workoutRepository = workoutRepository
    }
    
    // Sayfa açıldığında veya yenilendiğinde verileri çeken fonksiyon
    func loadDashboardData() async {
        isLoading = true
        
        do {
            // 1. Core Data'dan asenkron olarak verileri çek
            let workouts = try await workoutRepository.fetchWorkouts()
            self.recentWorkouts = workouts
            
            // 2. Makro motorunu çalıştır
            calculateCurrentMetrics(from: workouts)
            
        } catch {
            print("Veri çekme hatası: \(error)")
        }
        
        isLoading = false
    }
    
    private func calculateCurrentMetrics(from workouts: [WorkoutEntity]) {
        // Son antrenmanı alıp hacmini hesaplıyoruz (Gerçek senaryoda haftalık ortalama da alınabilir)
        guard let lastWorkout = workouts.first,
              let sets = lastWorkout.exercises?.allObjects.flatMap({ ($0 as? ExerciseEntity)?.sets?.allObjects as? [SetEntity] ?? [] }) else {
            return
        }
        
        let currentTonnage = optimizationEngine.calculateTonnage(for: sets)
        
        // Örnek bir hedef tonaj (Örn: 10,000 kg). Bu değer normalde UserEntity'den gelmelidir.
        let targetTonnage: Double = 10000.0
        
        // Dinamik (150g - 165g arası) protein hedefini hesapla ve UI'ı güncelle
        self.dailyProteinTarget = optimizationEngine.calculateDynamicProteinTarget(currentVolume: currentTonnage, targetVolume: targetTonnage)
    }
}
