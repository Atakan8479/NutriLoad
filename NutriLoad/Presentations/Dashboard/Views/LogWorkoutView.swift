import SwiftUI
import CoreData

struct LogWorkoutView: View {
    @ObservedObject var coordinator: AppCoordinator
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var searchText = ""
    @State private var selectedMuscle = "All"
    @State private var selectedExercise: ExerciseTemplate? // Detay ekranı için tetikleyici
    
    let exerciseManager = LocalExerciseManager.shared
    
    // HATA BURADAYDI: Artık "exercises" olarak doğru şekilde çağırılıyor.
    var muscleGroups: [String] {
        let allGroups = exerciseManager.exercises.map { $0.mainMuscle }
        let uniqueGroups = Array(Set(allGroups)).sorted()
        return ["All"] + uniqueGroups
    }
    
    var filteredExercises: [ExerciseTemplate] {
        exerciseManager.search(query: searchText, muscleGroup: selectedMuscle)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Muscle Group", selection: $selectedMuscle) {
                ForEach(muscleGroups, id: \.self) { group in
                    Text(group).tag(group)
                }
            }
            .pickerStyle(.menu)
            .padding()
            .background(Color(UIColor.systemBackground))
            
            List(filteredExercises) { exercise in
                Button(action: {
                    // Artık direkt kaydetmiyoruz, detay ekranını (çoklu set) açıyoruz
                    selectedExercise = exercise
                }) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(exercise.name)
                            .font(.headline)
                        HStack {
                            Label(exercise.mainMuscle, systemImage: "figure.strengthtraining.traditional")
                            Spacer()
                            Label(exercise.safeEquipment, systemImage: "dumbbell.fill")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Search exercises...")
        }
        .navigationTitle("Add Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { coordinator.navigate(to: .dashboard) }
            }
        }
        // SEÇİLEN HAREKET İÇİN DETAY EKRANI (SHEET)
        .sheet(item: $selectedExercise) { exercise in
            ExerciseDetailSheet(
                exercise: exercise,
                viewContext: viewContext,
                coordinator: coordinator
            )
        }
    }
}

// MARK: - DETAY EKRANI (Çoklu Set Desteği)
struct ExerciseDetailSheet: View {
    let exercise: ExerciseTemplate
    var viewContext: NSManagedObjectContext
    var coordinator: AppCoordinator
    
    @Environment(\.dismiss) var dismiss
    
    // UI'da listelemek için geçici bir yapı
    struct TempSet: Identifiable {
        let id = UUID()
        var reps: String = ""
        var weight: String = ""
    }
    
    // Uygulama her zaman en az 1 set satırı ile başlar
    @State private var loggedSets: [TempSet] = [TempSet()]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("LOG SETS")) {
                    // Dinamik Set Listesi
                    ForEach(loggedSets.indices, id: \.self) { index in
                        HStack {
                            Text("Set \(index + 1)")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .frame(width: 50, alignment: .leading)
                            
                            TextField("kg", text: $loggedSets[index].weight)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(8)
                            
                            Text("x")
                                .foregroundColor(.secondary)
                            
                            TextField("reps", text: $loggedSets[index].reps)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(8)
                            
                            // 1'den fazla set varsa silme butonu göster
                            if loggedSets.count > 1 {
                                Button(action: {
                                    loggedSets.remove(at: index)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                                .padding(.leading, 4)
                            }
                        }
                    }
                }
                
                // Yeni Set Ekleme Butonu
                Section {
                    Button(action: {
                        // Yeni set ekle (Bir önceki setin değerlerini kopyalar)
                        let lastSet = loggedSets.last
                        loggedSets.append(TempSet(reps: lastSet?.reps ?? "", weight: lastSet?.weight ?? ""))
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                            Text("Add Set")
                            Spacer()
                        }
                        .foregroundColor(.blue)
                        .fontWeight(.bold)
                    }
                }
            }
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveExerciseWithMultipleSets() }
                        .fontWeight(.bold)
                        .disabled(loggedSets.isEmpty || loggedSets.allSatisfy { $0.reps.isEmpty && $0.weight.isEmpty })
                }
            }
        }
    }
    
    private func saveExerciseWithMultipleSets() {
        let newWorkout = WorkoutEntity(context: viewContext)
        newWorkout.id = UUID()
        newWorkout.date = Date()
        
        let newExercise = ExerciseEntity(context: viewContext)
        newExercise.id = UUID()
        newExercise.name = exercise.name
        newExercise.workout = newWorkout
        
        for tempSet in loggedSets {
            guard let repsVal = Int16(tempSet.reps), let weightVal = Double(tempSet.weight.replacingOccurrences(of: ",", with: ".")) else {
                continue
            }
            
            let coreDataSet = SetEntity(context: viewContext)
            coreDataSet.id = UUID()
            coreDataSet.sets = 1
            coreDataSet.reps = repsVal
            coreDataSet.weight = weightVal
            coreDataSet.exercise = newExercise
        }
        
        do {
            try viewContext.save()
            dismiss()
            coordinator.navigate(to: .dashboard)
        } catch {
            print("❌ KAYIT HATASI: \(error)")
        }
    }
}
