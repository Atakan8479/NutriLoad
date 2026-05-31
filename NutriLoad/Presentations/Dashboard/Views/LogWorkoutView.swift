import SwiftUI
import CoreData

struct LogWorkoutView: View {
    @ObservedObject var coordinator: AppCoordinator
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var searchText = ""
    @State private var selectedMuscle = "All"
    @State private var selectedExercise: ExerciseTemplate? // Detay ekranı için tetikleyici
    
    let exerciseManager = LocalExerciseManager.shared
    
    var muscleGroups: [String] {
        let allGroups = exerciseManager.allExercises.map { $0.mainMuscle }
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
                    // Artık direkt kaydetmiyoruz, detay ekranını açıyoruz
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

// MARK: - DETAY EKRANI (Set, Reps, Weight)
struct ExerciseDetailSheet: View {
    let exercise: ExerciseTemplate
    var viewContext: NSManagedObjectContext
    var coordinator: AppCoordinator
    
    @Environment(\.dismiss) var dismiss
    
    @State private var sets: String = "3"
    @State private var reps: String = "10"
    @State private var weight: String = "0"
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("WORKOUT METRICS")) {
                    TextField("Sets", text: $sets).keyboardType(.numberPad)
                    TextField("Reps", text: $reps).keyboardType(.numberPad)
                    TextField("Weight (kg)", text: $weight).keyboardType(.decimalPad)
                }
            }
            .navigationTitle(exercise.name)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveExerciseWithDetails() }.fontWeight(.bold)
                }
            }
        }
    }
    
    private func saveExerciseWithDetails() {
        let newWorkout = WorkoutEntity(context: viewContext)
        newWorkout.id = UUID()
        newWorkout.date = Date()
        
        let newExercise = ExerciseEntity(context: viewContext)
        newExercise.id = UUID()
        newExercise.name = exercise.name
        newExercise.workout = newWorkout
        
        let newSet = SetEntity(context: viewContext)
        newSet.id = UUID()
        newSet.sets = Int16(sets) ?? 0
        newSet.reps = Int16(reps) ?? 0
        newSet.weight = Double(weight.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        newSet.exercise = newExercise // İLİŞKİ KURULDU
        
        do {
            try viewContext.save()
            dismiss()
            coordinator.navigate(to: .dashboard)
        } catch {
            print("❌ KAYIT HATASI: \(error)")
        }
    }
}
