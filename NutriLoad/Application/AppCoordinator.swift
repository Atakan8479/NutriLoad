import SwiftUI

// Uygulama içi rotalarımız
enum AppRoute: Hashable {
    case dashboard
    case logWorkout
    case logMeal
}

@MainActor
final class AppCoordinator: ObservableObject {
    // NavigationStack'in takip edeceği dinamik yol
    @Published var path = NavigationPath()
    
    // Yeni bir sayfaya gitmek için
    func navigate(to route: AppRoute) {
        path.append(route)
    }
    
    // Ana sayfaya (Root) dönmek için
    func popToRoot() {
        path.removeLast(path.count)
    }
}
