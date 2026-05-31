import Foundation
import CoreData

// Arayüzde kullanılacak öğün tipleri için güvenli Enum yapısı
enum MealType: String, CaseIterable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
}

@MainActor
final class LogMealViewModel: ObservableObject {
    // Kullanıcıdan alınacak girdiler
    @Published var name: String = ""
    @Published var protein: String = ""
    @Published var calories: String = ""
    @Published var selectedMealType: MealType = .breakfast // Seçilen öğün tipi
    @Published var isSaving: Bool = false
    
    // Core Data Context
    private let context = CoreDataManager.shared.viewContext
    
    func saveMeal(completion: @escaping () -> Void) {
        // Girdilerin doğruluğunu kontrol et (Validation)
        guard let proteinVal = Double(protein),
              let caloriesVal = Double(calories),
              !name.isEmpty else {
            return
        }
        
        isSaving = true
        
        // Yeni FoodItemEntity oluşturma
        let newFood = FoodItemEntity(context: context)
        newFood.id = UUID()
        newFood.name = name
        newFood.protein = proteinVal
        newFood.calories = caloriesVal
        newFood.date = Date()
        
        // İŞTE ÇÖZÜM: Enum'ın arkasındaki String değeri veri tabanına yazıyoruz
        newFood.meal = selectedMealType.rawValue
        
        do {
            try context.save()
            isSaving = false
            completion() // Başarıyla kaydedildiğinde ekranı kapatmak için
        } catch {
            print("Failed to log meal: \(error)")
            isSaving = false
        }
    }
}
