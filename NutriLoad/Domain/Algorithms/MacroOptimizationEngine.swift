import Foundation

// İş mantığını (Business Logic) arayüzden ayıran saf Swift hesaplama motoru
final class MacroOptimizationEngine {
    
    // Singleton olarak tek bir noktadan yönetiyoruz
    static let shared = MacroOptimizationEngine()
    
    private init() {}
    
    /// 1. Antrenman Hacmi (Tonaj) Hesaplama
    /// Formül: Ağırlık * Tekrar Sayısı * RPE (Zorluk Derecesi)
    func calculateTonnage(for sets: [SetEntity]) -> Double {
        var totalVolume: Double = 0
        
        for workoutSet in sets {
            // Core Data tiplerini güvenli şekilde matematiksel işleme sokuyoruz
            let weight = workoutSet.weight
            let reps = Double(workoutSet.reps)
            let rpe = workoutSet.rpe
            
            let setVolume = weight * reps * rpe
            totalVolume += setVolume
        }
        
        return totalVolume
    }
    
    /// 2. Dinamik Protein İhtiyacı Hesaplama
    /// Günlük hacim dalgalanmasına göre 150g ile 165g arasında esnek bir hedef döndürür.
    func calculateDynamicProteinTarget(currentVolume: Double, targetVolume: Double) -> ClosedRange<Double> {
        let baseProtein: Double = 150.0
        let maxProtein: Double = 165.0
        let proteinDelta = maxProtein - baseProtein // Maksimum 15g ekstra esneme payı
        
        // Eğer antrenman yapılmamışsa veya hedef geçersizse direkt bazal değeri aralık olarak döndür
        guard targetVolume > 0, currentVolume > 0 else {
            return baseProtein...baseProtein
        }
        
        // Hacim oranını hesapla (Örn: Hedefin %80'ine ulaşıldı)
        let volumeRatio = currentVolume / targetVolume
        
        // Orana göre ek protein miktarını hesapla
        let additionalProtein = proteinDelta * volumeRatio
        
        // Tavan değeri aşmasını (165g üstü) engelle
        let calculatedTarget = min(baseProtein + additionalProtein, maxProtein)
        
        return baseProtein...calculatedTarget
    }
}
