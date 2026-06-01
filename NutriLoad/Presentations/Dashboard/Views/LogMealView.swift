import SwiftUI
import CoreData

struct LogMealView: View {
    @ObservedObject var coordinator: AppCoordinator
    
    // Core Data Bağlantısı
    @Environment(\.managedObjectContext) private var viewContext
    
    // API ve Arama Durumları (State)
    @State private var searchText = ""
    @State private var searchResults: [OFFProduct] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Kullanıcının seçeceği öğün tipi
    @State private var selectedMealType: MealType = .breakfast
    
    // YENİ: Seçilen ürünü detay ekranına taşımak için state
    @State private var selectedProduct: OFFProduct? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            
            // 1. Öğün Tipi Seçici
            Picker("Meal Type", selection: $selectedMealType) {
                ForEach(MealType.allCases, id: \.self) { meal in
                    Text(meal.rawValue).tag(meal)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .background(Color(UIColor.systemGroupedBackground))
            
            // 2. Yükleniyor veya Hata Durumu
            if isLoading {
                Spacer()
                ProgressView("Searching database...")
                    .scaleEffect(1.2)
                Spacer()
            } else if let error = errorMessage {
                Spacer()
                Text(error)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            } else {
                // 3. Arama Sonuçları Listesi
                List(searchResults) { product in
                    Button(action: {
                        // DİREKT KAYDETMEK YERİNE ÜRÜNÜ SEÇ VE SHEET AÇ
                        selectedProduct = product
                    }) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(product.productName ?? "Unknown Food")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                Label(String(format: "%.1f kcal", product.nutriments?.energyKcal100g ?? 0), systemImage: "flame.fill")
                                    .foregroundColor(.orange)
                                Spacer()
                                Label(String(format: "%.1f g Protein", product.nutriments?.proteins100g ?? 0), systemImage: "bolt.fill")
                                    .foregroundColor(.green)
                            }
                            .font(.caption)
                            .padding(.top, 2)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Log Food")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search food (e.g. Oats, Chicken)...")
        .onSubmit(of: .search) {
            performSearch()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    coordinator.navigate(to: .dashboard)
                }
            }
        }
        // YENİ: Yiyecek seçildiğinde açılacak Porsiyon (Gramaj) Ekranı
        .sheet(item: $selectedProduct) { product in
            FoodPortionSheet(
                product: product,
                selectedMealType: selectedMealType,
                viewContext: viewContext,
                onSave: {
                    coordinator.navigate(to: .dashboard) // Kayıttan sonra ana ekrana dön
                }
            )
        }
    }
    
    // MARK: - API Arama Fonksiyonu
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        searchResults = []
        
        Task {
            do {
                let results = try await FoodNetworkManager.shared.searchFood(query: searchText)
                
                await MainActor.run {
                    self.searchResults = results
                    self.isLoading = false
                    
                    if results.isEmpty {
                        self.errorMessage = "No matching foods found."
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to fetch data. Please check your connection."
                    self.isLoading = false
                }
            }
        }
    }
}

// YENİ BİLEŞEN: Gramaj Girme ve Dinamik Hesaplama Ekranı (Bottom Sheet)
struct FoodPortionSheet: View {
    let product: OFFProduct
    let selectedMealType: MealType
    let viewContext: NSManagedObjectContext
    
    // YENİ: Varsa günceller (Edit), yoksa nil kalır ve yeni oluşturur (Log)
    var existingFood: FoodItemEntity? = nil
    
    let onSave: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var amountString: String = ""
    
    var baseCalories: Double { product.nutriments?.energyKcal100g ?? 0.0 }
    var baseProtein: Double { product.nutriments?.proteins100g ?? 0.0 }
    
    var calculatedCalories: Double {
        let amount = Double(amountString) ?? 0.0
        return (baseCalories / 100.0) * amount
    }
    var calculatedProtein: Double {
        let amount = Double(amountString) ?? 0.0
        return (baseProtein / 100.0) * amount
    }
    
    var body: some View {
        // ... (Arayüz kodların aynı kalacak, sadece saveCalculatedFood fonksiyonu değişecek)
        NavigationView {
            Form {
                Section(header: Text("Food Info (per 100g)")) {
                    Text(product.productName ?? "Unknown Food").font(.headline)
                    HStack {
                        Text("\(String(format: "%.1f", baseCalories)) kcal")
                        Spacer()
                        Text("\(String(format: "%.1f", baseProtein)) g Protein")
                    }
                    .font(.caption).foregroundColor(.secondary)
                }
                
                Section(header: Text("How much did you eat?")) {
                    HStack {
                        TextField("Amount (e.g. 250)", text: $amountString)
                            .keyboardType(.decimalPad)
                        Text("grams / ml").foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Calculated Macros")) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Calories").font(.caption).foregroundColor(.secondary)
                            Text("\(Int(calculatedCalories)) kcal").font(.title3).foregroundColor(.orange).fontWeight(.bold)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Protein").font(.caption).foregroundColor(.secondary)
                            Text("\(String(format: "%.1f", calculatedProtein)) g").font(.title3).foregroundColor(.green).fontWeight(.bold)
                        }
                    }
                }
            }
            .navigationTitle("Log Portion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveCalculatedFood() }
                    .fontWeight(.bold)
                    .disabled(amountString.isEmpty || (Double(amountString) ?? 0) <= 0)
                }
            }
        }
    }
    
    private func saveCalculatedFood() {
        // İŞTE SİHİR BURADA: Varsa eskisini kullan, yoksa yeni yarat
        let foodToSave = existingFood ?? FoodItemEntity(context: viewContext)
        
        if existingFood == nil {
            foodToSave.id = UUID()
            foodToSave.date = Date()
        }
        
        foodToSave.name = product.productName ?? "Unknown Food"
        foodToSave.meal = selectedMealType.rawValue
        foodToSave.calories = calculatedCalories
        foodToSave.protein = calculatedProtein
        
        do {
            try viewContext.save()
            dismiss()
            onSave()
        } catch {
            print("❌ KAYIT HATASI: \(error.localizedDescription)")
        }
    }
}
