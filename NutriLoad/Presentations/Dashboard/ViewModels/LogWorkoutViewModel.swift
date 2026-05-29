import Foundation

@MainActor
final class LogWorkoutViewModel: ObservableObject {
    @Published var weight: String = ""
    @Published var reps: String = ""
    @Published var rpe: String = "8.0" // Varsayılan zorluk derecesi
    @Published var isSaving: Bool = false
    
    private let repository: WorkoutRepositoryProtocol
    
    init(repository: WorkoutRepositoryProtocol = CoreDataWorkoutRepository()) {
        self.repository = repository
    }
    
    func saveWorkout(completion: @escaping () -> Void) async {
        guard let weightVal = Double(weight), let repsVal = Int(reps), let rpeVal = Double(rpe) else {
            return // Gerçek senaryoda buraya hata mesajı eklenebilir
        }
        
        isSaving = true
        
        // Hızlı bir test için formülü doğrudan kullanıyoruz: Ağırlık * Tekrar * RPE
        let totalTonnage = weightVal * Double(repsVal) * rpeVal
        
        do {
            _ = try await repository.addWorkout(totalTonnage: totalTonnage, date: Date())
            isSaving = false
            completion() // Başarılı olursa sayfayı kapatmak için tetikliyoruz
        } catch {
            print("Kayıt hatası: \(error)")
            isSaving = false
        }
    }
}
