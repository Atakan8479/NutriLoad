import Foundation
import CoreData

final class SyncManager {
    static let shared = SyncManager()
    private let coreDataManager = CoreDataManager.shared
    
    private init() {}
    
    func syncPendingWorkouts() async {
        let context = coreDataManager.newBackgroundContext()
        
        // Sadece sunucuya gitmemiş (syncStatus == 0) verileri getir
        let request: NSFetchRequest<WorkoutEntity> = WorkoutEntity.fetchRequest()
        request.predicate = NSPredicate(format: "syncStatus == %d", 0)
        
        do {
            let pendingWorkouts = try context.fetch(request)
            guard !pendingWorkouts.isEmpty else { return } // Bekleyen veri yoksa çık
            
            for workout in pendingWorkouts {
                // Backend'e asenkron istek at (Buradaki fonksiyonu kendi URL yapına göre güncelleyebilirsin)
                let success = await sendToFastAPI(workout: workout)
                
                if success {
                    // Sunucu '200 OK' dönerse lokaldeki statüyü güncelliyoruz
                    workout.syncStatus = 1
                }
            }
            
            // Değişiklikleri diske kaydet
            coreDataManager.saveContext(context)
            
        } catch {
            print("Senkronizasyon kuyruğu hatası: \(error)")
        }
    }
    
    // FastAPI Sunucusuna HTTP POST İsteği
    private func sendToFastAPI(workout: WorkoutEntity) async -> Bool {
        guard let url = URL(string: "http://localhost:8000/api/v1/sync/workout") else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // JSON Body oluşturma
        let payload: [String: Any] = [
            "id": workout.id?.uuidString ?? UUID().uuidString,
            "totalTonnage": workout.totalTonnage
            // Gerçek senaryoda date ve diğer özellikler de buraya eklenir
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                return true
            }
        } catch {
            print("API İstek hatası: \(error)")
        }
        
        return false
    }
}
