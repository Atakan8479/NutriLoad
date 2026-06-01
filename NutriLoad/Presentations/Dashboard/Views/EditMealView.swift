import SwiftUI
import CoreData

struct EditMealView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var food: FoodItemEntity
    
    @State private var selectedMealType: MealType = .breakfast
    @State private var showingSearchSheet = false
    
    // 🌟 SİHİRLİ DEĞİŞKEN: Bu değiştiği an sayfa kendini tamamen baştan çizer
    @State private var forceRefreshID = UUID()
    
    var body: some View {
        Form {
            Section(header: Text("Current Entry")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(food.name ?? "Unknown Food")
                        .font(.headline)
                    
                    HStack {
                        Label("\(Int(food.calories)) kcal", systemImage: "flame.fill").foregroundColor(.orange)
                        Spacer()
                        Label("\(String(format: "%.1f", food.protein))g Protein", systemImage: "bolt.fill").foregroundColor(.green)
                    }
                    .font(.subheadline)
                }
                .padding(.vertical, 4)
                
                Picker("Meal Type", selection: $selectedMealType) {
                    ForEach(MealType.allCases, id: \.self) { meal in
                        Text(meal.rawValue).tag(meal)
                    }
                }
            }
            
            Section(header: Text("Replace Item")) {
                Button(action: {
                    showingSearchSheet = true
                }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Search & Replace Food")
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .id(forceRefreshID) // 🌟 Formu bu ID'ye bağladık
        .navigationTitle("Edit Meal")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let savedMeal = food.meal, let type = MealType(rawValue: savedMeal) {
                selectedMealType = type
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    food.meal = selectedMealType.rawValue
                    try? viewContext.save()
                    dismiss()
                }
            }
        }
        // 🌟 onDismiss: Arama ekranı kapanır kapanmaz çalışır!
        .sheet(isPresented: $showingSearchSheet, onDismiss: {
            viewContext.refresh(food, mergeChanges: true) // Core Data'dan taze veriyi çek
            forceRefreshID = UUID() // Arayüzü zorla baştan çiz!
        }) {
            EditFoodSearchSheet(foodToUpdate: food, viewContext: viewContext, onComplete: {
                showingSearchSheet = false
            })
        }
    }
}

// MARK: - Arama ve Değiştirme Sheet'i (EditMealView İçin Özel)
struct EditFoodSearchSheet: View {
    let foodToUpdate: FoodItemEntity
    let viewContext: NSManagedObjectContext
    let onComplete: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var searchResults: [OFFProduct] = []
    @State private var selectedProduct: OFFProduct? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                List(searchResults) { product in
                    Button(action: {
                        selectedProduct = product
                    }) {
                        VStack(alignment: .leading) {
                            Text(product.productName ?? "Unknown").font(.headline).foregroundColor(.primary)
                            HStack {
                                Text("\(String(format: "%.1f", product.nutriments?.energyKcal100g ?? 0)) kcal").foregroundColor(.orange)
                                Spacer()
                                Text("\(String(format: "%.1f", product.nutriments?.proteins100g ?? 0)) g").foregroundColor(.green)
                            }
                            .font(.caption)
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search to replace...")
                .onSubmit(of: .search) {
                    Task {
                        if let results = try? await FoodNetworkManager.shared.searchFood(query: searchText) {
                            await MainActor.run { searchResults = results }
                        }
                    }
                }
            }
            .navigationTitle("Replace Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            // Ürün seçilince Porsiyon (Gramaj) ekranını aç
            .sheet(item: $selectedProduct) { product in
                            FoodPortionSheet(
                                product: product,
                                selectedMealType: MealType(rawValue: foodToUpdate.meal ?? "Snack") ?? .snack,
                                viewContext: viewContext,
                                existingFood: foodToUpdate, // YENİ: Eski kaydı içine gönderiyoruz!
                                onSave: {
                                    onComplete()
                                }
                            )
                        }
        }
    }
}
