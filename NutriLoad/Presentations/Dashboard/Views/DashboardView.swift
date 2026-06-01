import SwiftUI
import CoreData

struct DashboardView: View {
    @ObservedObject var coordinator: AppCoordinator
    @Environment(\.managedObjectContext) private var viewContext
    
    @AppStorage("isDarkMode") private var isDarkMode = true
    
    @State private var selectedDate = Date()
    @State private var selectedTab = 0
    
    // 🌟 SİHİRLİ DEĞİŞKEN: Core Data güncellendiğinde tüm ekranı zorla yeniler
    @State private var refreshID = UUID()
    
    @FetchRequest(
        entity: FoodItemEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \FoodItemEntity.date, ascending: false)]
    ) var allMeals: FetchedResults<FoodItemEntity>
    
    @FetchRequest(
        entity: ExerciseEntity.entity(),
        sortDescriptors: [NSSortDescriptor(key: "workout.date", ascending: false)]
    ) var allExercises: FetchedResults<ExerciseEntity>
    
    var dailyMeals: [FoodItemEntity] {
        allMeals.filter { Calendar.current.isDate($0.date ?? Date(), inSameDayAs: selectedDate) }
    }
    
    var dailyExercises: [ExerciseEntity] {
        allExercises.filter { Calendar.current.isDate($0.workout?.date ?? Date(), inSameDayAs: selectedDate) }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                DateSelectorView(selectedDate: $selectedDate)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.systemBackground))
                
                Picker("Tracker", selection: $selectedTab) {
                    Text("Nutrition").tag(0)
                    Text("Workouts").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                ScrollView {
                    if selectedTab == 0 {
                        NutritionTabView(meals: dailyMeals, coordinator: coordinator)
                    } else {
                        WorkoutTabView(exercises: dailyExercises, coordinator: coordinator)
                    }
                }
                .id(refreshID) // 🌟 SAYFAYI BU ID'YE BAĞLADIK
                // 🌟 BİLDİRİM DİNLEYİCİ: Veritabanına (Core Data) kayıt yapıldığı saniye tetiklenir!
                .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
                    refreshID = UUID() // Ana ekrana "Uyan ve kendini güncelle!" emri verilir
                }
            }
            .navigationTitle("Daily Log")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.bottom))
            
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
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

// MARK: - ALT BİLEŞEN 1: Tarih Seçici
struct DateSelectorView: View {
    @Binding var selectedDate: Date
    
    var dateString: String {
        if Calendar.current.isDateInToday(selectedDate) { return "Today" }
        if Calendar.current.isDateInYesterday(selectedDate) { return "Yesterday" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, EEEE"
        return formatter.string(from: selectedDate)
    }
    
    var body: some View {
        HStack {
            Button(action: {
                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
            }) {
                Image(systemName: "chevron.left.circle.fill").font(.title2).foregroundColor(.blue)
            }
            Spacer()
            Text(dateString).font(.headline).fontWeight(.bold)
            Spacer()
            Button(action: {
                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
            }) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(Calendar.current.isDateInToday(selectedDate) ? .gray : .blue)
            }
            .disabled(Calendar.current.isDateInToday(selectedDate))
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - ALT BİLEŞEN 2: Beslenme Ekranı
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
                Text("No food logged for this day.").foregroundColor(.secondary).padding(.top, 40)
            } else {
                ForEach(mealOrder, id: \.self) { mealName in
                    if let foodsInMeal = groupedMeals[mealName] {
                        VStack(alignment: .leading) {
                            Text(mealName.uppercased())
                                .font(.caption).fontWeight(.bold).foregroundColor(.secondary).padding(.horizontal)
                            
                            ForEach(foodsInMeal) { food in
                                // 🌟 Yemek satırını bağımsız, anında güncellenen bir yapıya ayırdık
                                MealRowView(food: food, coordinator: coordinator) {
                                    deleteFood(food)
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
        do { try viewContext.save() } catch { print("❌ Hata: \(error)") }
    }
}

// MARK: - ALT BİLEŞEN 3: Antrenman Ekranı
struct WorkoutTabView: View {
    let exercises: [ExerciseEntity]
    let coordinator: AppCoordinator
        
    @Environment(\.managedObjectContext) private var viewContext
    
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
                Text("No workouts logged for this day.").foregroundColor(.secondary).padding(.top, 20)
            } else {
                VStack(alignment: .leading) {
                    Text("COMPLETED EXERCISES")
                        .font(.caption).fontWeight(.bold).foregroundColor(.secondary).padding(.horizontal)
                    
                    ForEach(exercises, id: \.self) { (exercise: ExerciseEntity) in
                        // 🌟 Antrenman satırını bağımsız, anında güncellenen bir yapıya ayırdık
                        WorkoutRowView(exercise: exercise, coordinator: coordinator) {
                            deleteExercise(exercise)
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

// MARK: - 🌟 ANINDA GÜNCELLENEN BAĞIMSIZ SATIRLAR (Gözlemlenebilir Objeler) 🌟

struct MealRowView: View {
    @ObservedObject var food: FoodItemEntity // Sadece kendi verisini dinler!
    var coordinator: AppCoordinator
    var deleteAction: () -> Void
    
    var body: some View {
        HStack {
            Text(food.name ?? "Unknown").font(.subheadline)
            Spacer()
            Text("\(Int(food.calories)) kcal").font(.caption).foregroundColor(.orange)
            Text("\(String(format: "%.1f", food.protein))g").font(.caption).foregroundColor(.green)
            
            Button(action: { coordinator.navigate(to: .editMeal(food)) }) {
                Image(systemName: "pencil.circle.fill").foregroundColor(.blue).font(.title3)
            }.padding(.leading, 6)
            
            Button(action: deleteAction) {
                Image(systemName: "trash.circle.fill").foregroundColor(.red).font(.title3)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
        .padding(.horizontal)
        .contextMenu {
            Button(action: { coordinator.navigate(to: .editMeal(food)) }) {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive, action: deleteAction) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct WorkoutRowView: View {
    @ObservedObject var exercise: ExerciseEntity // Sadece kendi verisini dinler!
    var coordinator: AppCoordinator
    var deleteAction: () -> Void
    
    var body: some View {
        let setArray = exercise.sets?.allObjects as? [SetEntity] ?? []
        let detail = setArray.first
        
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name ?? "Unknown Exercise").font(.subheadline).fontWeight(.bold)
                
                if let detail = detail {
                    Text("\(detail.sets) Set x \(detail.reps) Reps @ \(String(format: "%.1f", detail.weight)) kg")
                        .font(.caption).foregroundColor(.blue)
                }
            }
            Spacer()
            
            if let detail = detail {
                let volume = Double(detail.sets) * Double(detail.reps) * detail.weight
                Text(String(format: "%.0f kg", volume))
                    .font(.caption2).fontWeight(.bold).padding(6)
                    .background(Color.green.opacity(0.2)).foregroundColor(.green).cornerRadius(6)
            }
            
            Button(action: { coordinator.navigate(to: .editWorkout(exercise)) }) {
                Image(systemName: "pencil.circle.fill").foregroundColor(.blue).font(.title3)
            }.padding(.leading, 8)
            
            Button(action: deleteAction) {
                Image(systemName: "trash.circle.fill").foregroundColor(.red).font(.title3)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
        .padding(.horizontal)
        .contextMenu {
            Button(action: { coordinator.navigate(to: .editWorkout(exercise)) }) {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive, action: deleteAction) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
