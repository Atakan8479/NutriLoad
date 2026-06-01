import Foundation

final class LocalExerciseManager {
    static let shared = LocalExerciseManager()
    
    // EditWorkoutView'da "exercises" olarak çağırdığımız için ismini eşitledik
    private(set) var exercises: [ExerciseTemplate] = []
    
    private init() {
        loadAllJSONFiles()
    }
    
    private func loadAllJSONFiles() {
        var loadedExercises: [ExerciseTemplate] = []
        let decoder = JSONDecoder()
        var allURLs: [URL] = []
        
        // 1. Senaryo: Dosyalar ana bundle'a (Sarı klasör) atıldıysa
        if let rootURLs = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) {
            allURLs.append(contentsOf: rootURLs)
        }
        
        // 2. Senaryo: Dosyalar "exercises" adında Mavi klasör referansı olarak atıldıysa
        if let folderURLs = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: "exercises") {
            allURLs.append(contentsOf: folderURLs)
        }
        
        // Dosyaları taramaya başla
        for url in allURLs {
            do {
                let data = try Data(contentsOf: url)
                
                // Önce: Dosya TEK BİR HAREKET içeriyorsa
                if let singleExercise = try? decoder.decode(ExerciseTemplate.self, from: data) {
                    loadedExercises.append(singleExercise)
                }
                // Alternatif: Dosya devasa bir LİSTE içeriyorsa (Birleştirilmiş versiyonsa)
                else if let exerciseArray = try? decoder.decode([ExerciseTemplate].self, from: data) {
                    loadedExercises.append(contentsOf: exerciseArray)
                }
            } catch {
                continue // Okunamayan veya bozuk formatlı dosyayı atla
            }
        }
        
        // Tüm hareketleri isme göre A'dan Z'ye sıralayıp RAM'e kaydet
        self.exercises = loadedExercises.sorted { $0.name < $1.name }
        
        print("✅ BAŞARILI: Klasörden \(exercises.count) hareket RAM'e yüklendi!")
    }
    
    // Arayüz için Arama / Filtreleme
        func search(query: String, muscleGroup: String? = nil) -> [ExerciseTemplate] {
            var results = exercises
            
            // HATA VEREN SATIR DÜZELTİLDİ: displayCategory yerine mainMuscle kullanıyoruz
            if let muscle = muscleGroup, muscle != "All" {
                results = results.filter { $0.mainMuscle.lowercased() == muscle.lowercased() }
            }
            
            if !query.isEmpty {
                results = results.filter { $0.name.lowercased().contains(query.lowercased()) }
            }
            
            return results
        }
}
