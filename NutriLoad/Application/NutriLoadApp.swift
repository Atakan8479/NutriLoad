import SwiftUI

@main
struct NutriLoadApp: App {
    // Tüm uygulama boyunca yaşayacak tek Coordinator (Yönlendirici) örneği
    @StateObject private var coordinator = AppCoordinator()
    
    // Core Data kalıcılığını (viewContext) SwiftUI ortamına (environment) enjekte etmek
    // (Bunu eklemek, View'lar içinden doğrudan @Environment(\.managedObjectContext) ile veriye ulaşabilmek için iyi bir pratiktir)
    let coreDataManager = CoreDataManager.shared
    
    var body: some Scene {
        WindowGroup {
            CoordinatorView(coordinator: coordinator)
                .environment(\.managedObjectContext, coreDataManager.viewContext)
        }
    }
}

// Rotalara göre hangi ekranın çizileceğine karar veren ana görünüm yapısı
struct CoordinatorView: View {
    @ObservedObject var coordinator: AppCoordinator
    
    var body: some View {
        switch coordinator.currentRoute {
        case .dashboard:
            DashboardView(coordinator: coordinator)
        case .logWorkout:
            LogWorkoutView(coordinator: coordinator)
        case .logMeal:
            LogMealView(coordinator: coordinator) // <-- "Yakında" metni yerine ekranı bağladık
        }
    }
}
