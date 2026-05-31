import Foundation

struct ExerciseTemplate: Identifiable, Decodable, Hashable {
    // ID eğer JSON'da yoksa Swift otomatik olarak benzersiz bir ID atayacak
    var id: String = UUID().uuidString
    
    let name: String
    let equipment: String?
    let level: String?
    let category: String?
    let primaryMuscles: [String]
    let secondaryMuscles: [String]?
    let instructions: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, equipment, level, category, primaryMuscles, secondaryMuscles, instructions
    }
    
    // Özel Çözümleyici (Custom Decoder): Yüzlerce dosyadan bazılarında eksik veri olursa uygulamayı çökertmez
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = (try? container.decodeIfPresent(String.self, forKey: .id)) ?? UUID().uuidString
        self.name = (try? container.decode(String.self, forKey: .name)) ?? "Unknown Exercise"
        self.equipment = try? container.decodeIfPresent(String.self, forKey: .equipment)
        self.level = try? container.decodeIfPresent(String.self, forKey: .level)
        self.category = try? container.decodeIfPresent(String.self, forKey: .category)
        
        // Kas grupları bazen boş dizi, bazen de nil gelebilir.
        self.primaryMuscles = (try? container.decodeIfPresent([String].self, forKey: .primaryMuscles)) ?? []
        self.secondaryMuscles = try? container.decodeIfPresent([String].self, forKey: .secondaryMuscles)
        self.instructions = try? container.decodeIfPresent([String].self, forKey: .instructions)
    }
    
    // UI için Köprü Değişkenler
    var mainMuscle: String {
        primaryMuscles.first?.capitalized ?? "Other"
    }
    
    var safeEquipment: String {
        equipment?.capitalized ?? "Bodyweight"
    }
}
