import Foundation
import CoreData

// 1. Soyutlama (Abstraction): Protokol tanımlıyoruz.
// Bu sayede test (Mock) yazarken veya veritabanı değiştirirken kodumuz patlamaz.
protocol WorkoutRepositoryProtocol {
    func addWorkout(totalTonnage: Double, date: Date) async throws -> WorkoutEntity
    func fetchWorkouts() async throws -> [WorkoutEntity]
}

// 2. Somutlaştırma (Implementation): Core Data'ya özel repository
final class CoreDataWorkoutRepository: WorkoutRepositoryProtocol {
    
    private let coreDataManager = CoreDataManager.shared
    
    // Antrenman Ekleme Servisi (Background Thread'de çalışır)
    func addWorkout(totalTonnage: Double, date: Date) async throws -> WorkoutEntity {
        // Ağır kayıt işlemleri için arka plan bağlamını (Background Context) çağırıyoruz
        let context = coreDataManager.newBackgroundContext()
        
        // Swift Concurrency (async/await) ile context.perform bloku, işlemin doğru thread'de yapılmasını garanti eder.
        return try await context.perform {
            let newWorkout = WorkoutEntity(context: context)
            newWorkout.id = UUID()
            newWorkout.date = date
            newWorkout.totalTonnage = totalTonnage
            newWorkout.syncStatus = 0 // 0 = Pending (Çevrimdışı, henüz sunucuya gitmedi)
            
            // Veriyi diske kaydet
            self.coreDataManager.saveContext(context)
            
            return newWorkout
        }
    }
    
    // Antrenmanları Okuma Servisi
    func fetchWorkouts() async throws -> [WorkoutEntity] {
        // Okuma işlemlerini genelde ekranda hemen göstermek için UI (View) bağlamında yaparız.
        let context = coreDataManager.viewContext
        
        let request: NSFetchRequest<WorkoutEntity> = WorkoutEntity.fetchRequest()
        // Tarihe göre en yeniden en eskiye sırala
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutEntity.date, ascending: false)]
        
        return try await context.perform {
            return try context.fetch(request)
        }
    }
}
