import SwiftUI
import CoreData

struct DashboardView: View {
    @ObservedObject var coordinator: AppCoordinator
    @Environment(\.managedObjectContext) private var viewContext
    
    // YENİ: Dark/Light Mode için AppStorage (Kullanıcının tercihini cihazda hatırlar)
    @AppStorage("isDarkMode") private var isDarkMode = true
    
    // Uygulamanın kalbi: Seçili Tarih ve Seçili Sekme
    @State private var selectedDate = Date()
    @State private var selectedTab = 0 // 0: Nutrition, 1: Workouts
    
    // Tüm verileri çekiyoruz, filtrelemeyi aşağıda anlık yapacağız
    @FetchRequest(
        entity: FoodItemEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \FoodItemEntity.date, ascending: false)]
    ) var allMeals: FetchedResults<FoodItemEntity>
    
    @FetchRequest(
        entity: ExerciseEntity.entity(),
        sortDescriptors: [NSSortDescriptor(key: "workout.date", ascending: false)]
    ) var allExercises: FetchedResults<ExerciseEntity>
    
    // MARK: - Tarih Filtreleme (Sadece seçili günün verilerini al)
    var dailyMeals: [FoodItemEntity] {
        allMeals.filter { Calendar.current.isDate($0.date ?? Date(), inSameDayAs: selectedDate) }
    }
    
    var dailyExercises: [ExerciseEntity] {
        allExercises.filter { Calendar.current.isDate($0.workout?.date ?? Date(), inSameDayAs: selectedDate) }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                
                // 1. GÜN SEÇİCİ (Tarih Navigasyonu)
                DateSelectorView(selectedDate: $selectedDate)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.systemBackground))
                
                // 2. SEKME SEÇİCİ (Beslenme vs Antrenman)
                Picker("Tracker", selection: $selectedTab) {
                    Text("Nutrition").tag(0)
                    Text("Workouts").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // 3. DİNAMİK İÇERİK EKRANLARI
                ScrollView {
                    if selectedTab == 0 {
                        NutritionTabView(meals: dailyMeals, coordinator: coordinator)
                    } else {
                        WorkoutTabView(exercises: dailyExercises, coordinator: coordinator)
                    }
                }
            }
            .navigationTitle("Daily Log")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.bottom))
            
            // YENİ: Dark/Light Mode Geçiş Butonu
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation { isDarkMode.toggle() }
                    }) {
                        Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                            .foregroundColor(isDarkMode ? .yellow : .orange)
                            .font(.system(size: 18, weight: .bold))
                    }
                }
            }
        }
        // YENİ: Tüm uygulamayı seçili temaya zorla
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

// MARK: - ALT BİLEŞEN 1: Tarih Seçici Çubuğu
struct DateSelectorView: View {
    @Binding var selectedDate: Date
    
    var dateString: String {
        if Calendar.current.isDateInToday(selectedDate) { return "Today" }
        if Calendar.current.isDateInYesterday(selectedDate) { return "Yesterday" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, EEEE" // Örn: May 30, Saturday
        return formatter.string(from: selectedDate)
    }
    
    var body: some View {
        HStack {
            Button(action: {
                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
            }) {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Text(dateString)
                .font(.headline)
                .fontWeight(.bold)
            
            Spacer()
            
            Button(action: {
                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
            }) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(Calendar.current.isDateInToday(selectedDate) ? .gray : .blue)
            }
            .disabled(Calendar.current.isDateInToday(selectedDate)) // Geleceğe gidilmesini engelle
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - ALT BİLEŞEN 2: Beslenme Ekranı (Öğünlere Göre Gruplanmış)
struct NutritionTabView: View {
    var meals: [FoodItemEntity]
    var coordinator: AppCoordinator
    
    @Environment(\.managedObjectContext) private var viewContext
    
    var groupedMeals: [String: [FoodItemEntity]] {
        Dictionary(grouping: meals, by: { $0.meal ?? "Snack" })
    }
    
    let mealOrder = ["Breakfast", "Lunch", "Dinner", "Snack"]
    
    var body: some View {
        VStack(spacing: 16) {
            
            let totalCal = meals.reduce(0) { $0 + $1.calories }
            let totalPro = meals.reduce(0) { $0 + $1.protein }
            
            HStack(spacing: 40) {
                VStack {
                    Text("Calories").font(.caption).foregroundColor(.secondary)
                    Text("\(Int(totalCal))").font(.title2).fontWeight(.bold).foregroundColor(.orange)
                }
                VStack {
                    Text("Protein").font(.caption).foregroundColor(.secondary)
                    Text("\(Int(totalPro))g").font(.title2).fontWeight(.bold).foregroundColor(.green)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
            
            if meals.isEmpty {
                Text("No food logged for this day.")
                    .foregroundColor(.secondary)
                    .padding(.top, 40)
            } else {
                ForEach(mealOrder, id: \.self) { mealName in
                    if let foodsInMeal = groupedMeals[mealName] {
                        VStack(alignment: .leading) {
                            Text(mealName.uppercased())
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            ForEach(foodsInMeal) { food in
                                HStack {
                                    Text(food.name ?? "Unknown")
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(Int(food.calories)) kcal")
                                        .font(.caption).foregroundColor(.orange)
                                    Text("\(String(format: "%.1f", food.protein))g")
                                        .font(.caption).foregroundColor(.green)
                                    
                                    Button(action: { deleteFood(food) }) {
                                        Image(systemName: "trash").foregroundColor(.red).opacity(0.8)
                                    }
                                    .padding(.leading, 6)
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(8)
                                .padding(.horizontal)
                                .contextMenu {
                                    Button(role: .destructive, action: { deleteFood(food) }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 8)
                    }
                }
            }
            
            Button("Add Food") { coordinator.navigate(to: .logMeal) }
                .buttonStyle(.borderedProminent)
                .padding(.top, 10)
        }
        .padding(.vertical)
    }
    
    private func deleteFood(_ food: FoodItemEntity) {
        viewContext.delete(food)
        do { try viewContext.save() } catch { print("❌ Yemek silinirken hata: \(error)") }
    }
}

// MARK: - ALT BİLEŞEN 3: Antrenman Ekranı (Hacim Hesaplamalı)
struct WorkoutTabView: View {
    let exercises: [ExerciseEntity]
    let coordinator: AppCoordinator
        
    @Environment(\.managedObjectContext) private var viewContext
    
    // YENİ: Günlük Toplam Hacmi (Volume) Hesaplayan Değişken
    var dailyTotalVolume: Double {
        exercises.reduce(0) { total, exercise in
            let setArray = exercise.sets?.allObjects as? [SetEntity] ?? []
            let exerciseVolume = setArray.reduce(0) { sum, set in
                sum + (Double(set.sets) * Double(set.reps) * set.weight)
            }
            return total + exerciseVolume
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            
            // YENİ: Toplam Hacim Gösterge Kartı (Nutrition ekranındaki gibi şık)
            VStack {
                Text("Total Volume").font(.caption).foregroundColor(.secondary)
                Text("\(String(format: "%.0f", dailyTotalVolume)) kg")
                    .font(.title).fontWeight(.heavy).foregroundColor(.blue)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
            
            if exercises.isEmpty {
                Text("No workouts logged for this day.")
                    .foregroundColor(.secondary)
                    .padding(.top, 20)
            } else {
                VStack(alignment: .leading) {
                    Text("COMPLETED EXERCISES")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    ForEach(exercises, id: \.self) { (exercise: ExerciseEntity) in
                        
                        let setArray = exercise.sets?.allObjects as? [SetEntity] ?? []
                        let detail = setArray.first
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.name ?? "Unknown Exercise")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                
                                if let detail = detail {
                                    Text("\(detail.sets) Set x \(detail.reps) Reps @ \(String(format: "%.1f", detail.weight)) kg")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            Spacer()
                            
                            if let detail = detail {
                                let volume = Double(detail.sets) * Double(detail.reps) * detail.weight
                                Text(String(format: "%.0f kg", volume))
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .padding(6)
                                    .background(Color.green.opacity(0.2))
                                    .foregroundColor(.green)
                                    .cornerRadius(6)
                            }
                            
                            Button(action: { deleteExercise(exercise) }) {
                                Image(systemName: "trash").foregroundColor(.red).opacity(0.8)
                            }
                            .padding(.leading, 8)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .contextMenu {
                            Button(role: .destructive, action: { deleteExercise(exercise) }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            
            Button("Log Workout") { coordinator.navigate(to: .logWorkout) }
                .buttonStyle(.borderedProminent)
                .padding(.top, 10)
        }
        .padding(.vertical)
    }
    
    private func deleteExercise(_ exercise: ExerciseEntity) {
        viewContext.delete(exercise)
        do { try viewContext.save() } catch { print("❌ Hata: \(error)") }
    }
}
