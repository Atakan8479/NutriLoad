import SwiftUI

// Uygulama içindeki tüm olası sayfalarımız
enum AppRoute {
    case dashboard
    case logWorkout
    case logMeal
}

// Tüm geçişleri yönetecek merkezi sınıfımız
final class AppCoordinator: ObservableObject {
    @Published var currentRoute: AppRoute = .dashboard
    
    func navigate(to route: AppRoute) {
        // Ekran güncellemelerinin kesinlikle Main Thread'de yapılmasını garanti ediyoruz
        DispatchQueue.main.async {
            self.currentRoute = route
        }
    }
}
