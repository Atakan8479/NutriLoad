import Foundation

@MainActor
final class LogMealViewModel: ObservableObject {
    @Published var mealName: String = ""
    @Published var proteinAmount: String = ""
    @Published var isSaving: Bool = false
    
    // Gerçek senaryoda MealRepositoryProtocol üzerinden soyutlanmalıdır
    private let coreDataManager = CoreDataManager.shared
    
    func saveMeal(completion: @escaping () -> Void) async {
        guard let proteinVal = Double(proteinAmount), !mealName.isEmpty else { return }
        
        isSaving = true
        let context = coreDataManager.newBackgroundContext()
        
        do {
            try await context.perform {
                let newMeal = MealEntity(context: context)
                newMeal.id = UUID()
                newMeal.date = Date()
                newMeal.totalProtein = proteinVal
                newMeal.syncStatus = 0 // Offline-first pending status
                
                let foodItem = FoodItemEntity(context: context)
                foodItem.id = UUID()
                foodItem.name = self.mealName
                foodItem.protein = proteinVal
                foodItem.meal = newMeal
                
                self.coreDataManager.saveContext(context)
            }
            
            isSaving = false
            completion()
        } catch {
            print("Failed to save meal: \(error)")
            isSaving = false
        }
    }
}
