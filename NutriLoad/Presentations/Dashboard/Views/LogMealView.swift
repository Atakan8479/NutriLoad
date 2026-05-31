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
    
    // Kullanıcının seçeceği öğün tipi (Önceki adımdan gelen enum)
    @State private var selectedMealType: MealType = .breakfast
    
    var body: some View {
        VStack(spacing: 0) {
            
            // 1. Öğün Tipi Seçici (Segmented Control)
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
                        // Tıklanan yemeği Core Data'ya kaydet
                        saveFoodToCoreData(product: product)
                    }) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(product.productName ?? "Unknown Food")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                // Kalori formatlama (virgülden sonra 1 hane)
                                Label(String(format: "%.1f kcal", product.nutriments?.energyKcal100g ?? 0), systemImage: "flame.fill")
                                    .foregroundColor(.orange)
                                Spacer()
                                // Protein formatlama
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
        // SwiftUI'ın yerleşik arama çubuğu
        .searchable(text: $searchText, prompt: "Search food (e.g. Oats, Chicken)...")
        // Kullanıcı klavyede "Ara/Enter" tuşuna bastığında tetiklenir
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
    }
    
    // MARK: - API Arama Fonksiyonu
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        searchResults = []
        
        // async/await yapısını SwiftUI arayüzünde kullanabilmek için Task bloğu açıyoruz
        Task {
            do {
                // İnternetten veriyi çek (Thread'i dondurmaz)
                let results = try await FoodNetworkManager.shared.searchFood(query: searchText)
                
                // Arayüz güncellemeleri ana thread'de (MainActor) yapılmalıdır
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
    
    // MARK: - Core Data Kayıt İşlemi
    private func saveFoodToCoreData(product: OFFProduct) {
        let newFood = FoodItemEntity(context: viewContext)
        newFood.id = UUID()
        newFood.date = Date()
        newFood.name = product.productName ?? "Unknown Food"
        newFood.meal = selectedMealType.rawValue
        
        // API'den null (nil) gelirse, varsayılan olarak 0.0 değerini ata
        newFood.calories = product.nutriments?.energyKcal100g ?? 0.0
        newFood.protein = product.nutriments?.proteins100g ?? 0.0
        
        do {
            try viewContext.save()
            print("✅ BAŞARILI: '\(newFood.name ?? "")' Core Data'ya eklendi.")
            coordinator.navigate(to: .dashboard) // Ana ekrana dön
        } catch {
            print("❌ KAYIT HATASI: \(error.localizedDescription)")
        }
    }
}
