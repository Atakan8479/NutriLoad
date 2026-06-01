import SwiftUI
import CoreData

struct EditWorkoutView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var exercise: ExerciseEntity
    
    @State private var name: String = ""
    @State private var sets: String = ""
    @State private var reps: String = ""
    @State private var weight: String = ""
    @State private var showingExerciseSearch = false
    
    var body: some View {
        Form {
            Section(header: Text("Exercise")) {
                HStack {
                    TextField("Exercise Name", text: $name)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Button(action: {
                        showingExerciseSearch = true
                    }) {
                        Text("Change")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                            .padding(6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
            }
            
            Section(header: Text("Workout Metrics")) {
                HStack {
                    Text("Sets").frame(width: 80, alignment: .leading).foregroundColor(.secondary)
                    TextField("e.g. 3", text: $sets).keyboardType(.numberPad).multilineTextAlignment(.leading)
                }
                HStack {
                    Text("Reps").frame(width: 80, alignment: .leading).foregroundColor(.secondary)
                    TextField("e.g. 10", text: $reps).keyboardType(.numberPad).multilineTextAlignment(.leading)
                }
                HStack {
                    Text("Weight").frame(width: 80, alignment: .leading).foregroundColor(.secondary)
                    TextField("e.g. 50.5", text: $weight).keyboardType(.decimalPad).multilineTextAlignment(.leading)
                }
            }
        }
        .navigationTitle("Edit Workout")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            name = exercise.name ?? ""
            let setArray = exercise.sets?.allObjects as? [SetEntity] ?? []
            if let firstSet = setArray.first {
                sets = "\(firstSet.sets)"
                reps = "\(firstSet.reps)"
                weight = String(format: "%.1f", firstSet.weight)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Update") { updateWorkout() }
                    .fontWeight(.bold)
                    .disabled(name.isEmpty || sets.isEmpty || reps.isEmpty)
            }
        }
        .sheet(isPresented: $showingExerciseSearch) {
            // 🌟 ÇÖZÜM: $name değişkenini Binding olarak alt sayfaya gönderiyoruz.
            EditWorkoutSearchSheet(exerciseToUpdate: exercise, selectedName: $name)
        }
    }
    
    private func updateWorkout() {
        exercise.name = name
        let setArray = exercise.sets?.allObjects as? [SetEntity] ?? []
        if let firstSet = setArray.first {
            firstSet.sets = Int16(sets) ?? 1
            firstSet.reps = Int16(reps) ?? 1
            firstSet.weight = Double(weight.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        }
        
        do {
            viewContext.refresh(exercise, mergeChanges: true)
            try viewContext.save()
            dismiss()
        } catch {
            print("❌ Hata: \(error)")
        }
    }
}

// MARK: - Egzersiz Seçim Listesi (Binding Kullanımı)
struct EditWorkoutSearchSheet: View {
    let exerciseToUpdate: ExerciseEntity
    
    // 🌟 YENİ: Üst sayfadaki "name" değişkeniyle canlı bağlantı
    @Binding var selectedName: String
    
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    
    @State private var availableExercises: [ExerciseTemplate] = []
    
    var filteredExercises: [ExerciseTemplate] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return availableExercises
        } else {
            return availableExercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredExercises, id: \.id) { exercise in
                    exerciseRow(for: exercise)
                }
            }
            .searchable(text: $searchText, prompt: "Search exercise...")
            .navigationTitle("Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                self.availableExercises = LocalExerciseManager.shared.exercises
            }
        }
    }
    
    @ViewBuilder
    private func exerciseRow(for exercise: ExerciseTemplate) -> some View {
        Button(action: {
            // 🌟 SİHİRLİ DOKUNUŞ: Tıklandığı an üst sayfanın adı anında güncellenir!
            selectedName = exercise.name
            dismiss()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name).font(.headline).foregroundColor(.primary)
                    Text("\(exercise.mainMuscle) • \(exercise.safeEquipment)").font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                if exercise.name == (exerciseToUpdate.name ?? "") {
                    Image(systemName: "checkmark").foregroundColor(.blue).fontWeight(.bold)
                }
            }
            .padding(.vertical, 2)
        }
    }
}
    
   
