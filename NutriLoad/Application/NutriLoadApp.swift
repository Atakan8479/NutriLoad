import SwiftUI
import CoreData // NSManagedObjectContext için zorunlu kütüphane

@main
struct NutriLoadApp: App {
    // Coordinator'ı tüm uygulamanın en üst seviyesinde başlatıyoruz
    @StateObject private var coordinator = AppCoordinator()
    
    // Core Data Manager referansı
    let coreDataManager = CoreDataManager.shared
    
    // Açılış ekranı (LaunchScreen) kontrolü
    @State private var showLaunchScreen = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // 1. Katman: Ana Uygulama Akışı
                CoordinatorView(coordinator: coordinator)
                    .environment(\.managedObjectContext, coreDataManager.viewContext)
                
                // 2. Katman: Açılış Ekranı (Başlangıçta en üstte durur)
                if showLaunchScreen {
                    LaunchScreenView {
                        withAnimation {
                            showLaunchScreen = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
        }
    }
}
