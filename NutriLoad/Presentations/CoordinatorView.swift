import SwiftUI

struct CoordinatorView: View {
    @ObservedObject var coordinator: AppCoordinator
    
    var body: some View {
        // Navigasyon rotasını coordinator üzerinden dinliyoruz
        NavigationStack(path: $coordinator.path) {
            // Uygulamanın açıldığı ilk sayfa
            DashboardView(coordinator: coordinator)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .dashboard:
                        DashboardView(coordinator: coordinator)
                    case .logWorkout:
                        LogWorkoutView(coordinator: coordinator)
                    case .logMeal:
                        LogMealView(coordinator: coordinator) // LogMealView'in önceden oluşturulmuş olduğundan emin ol
                    }
                }
        }
    }
}
