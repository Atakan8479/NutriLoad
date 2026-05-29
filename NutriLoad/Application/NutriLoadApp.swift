import SwiftUI

@main
struct NutriLoadApp: App {
    @StateObject private var coordinator = AppCoordinator()
    let coreDataManager = CoreDataManager.shared
    
    // Açılış ekranı durumunu kontrol eden değişken
    @State private var showLaunchScreen = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Ana akış (arkada hazır bekliyor)
                CoordinatorView(coordinator: coordinator)
                    .environment(\.managedObjectContext, coreDataManager.viewContext)
                
                // Açılış ekranı (başlangıçta önde)
                if showLaunchScreen {
                    LaunchScreenView {
                        withAnimation {
                            showLaunchScreen = false
                        }
                    }
                    // Ana ekran görünürken açılış ekranının kaybolmasını sağlar
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
        }
    }
}
