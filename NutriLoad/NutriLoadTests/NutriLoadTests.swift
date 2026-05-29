import XCTest
// Projenin ana modülünü içe aktarıyoruz ki içindeki sınıflara erişebilelim
@testable import NutriLoad

final class MacroOptimizationEngineTests: XCTestCase {
    
    // SUT: System Under Test (Test Edilen Sistem)
    var sut: MacroOptimizationEngine!
    
    // Her testten BİR SANİYE ÖNCE çalışıp ortamı hazırlar
    override func setUp() {
        super.setUp()
        sut = MacroOptimizationEngine.shared
    }
    
    // Her testten BİR SANİYE SONRA çalışıp belleği temizler
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // TEST 1: Antrenman hacmi hedeften yüksekse, protein ihtiyacı artmalı mı?
    func test_calculateDynamicProteinTarget_withHighVolume_increasesProtein() {
        // 1. Arrange (Hazırlık)
        let currentVolume: Double = 12000.0 // Hedefin üstünde bir tonaj
        let targetVolume: Double = 10000.0
        
        // 2. Act (Eylem)
        let result = sut.calculateDynamicProteinTarget(currentVolume: currentVolume, targetVolume: targetVolume)
        
        // 3. Assert (Doğrulama)
        // Beklenen: Algoritma protein aralığının üst sınırını 165g'a çekmeli
        XCTAssertEqual(result.upperBound, 165.0, "Protein target upper bound should be 165.0 for high volume training.")
    }
    
    // TEST 2: Antrenman hacmi düşükse, protein ihtiyacı taban seviyede kalmalı mı?
    func test_calculateDynamicProteinTarget_withLowVolume_keepsBaselineProtein() {
        // 1. Arrange (Hazırlık)
        let currentVolume: Double = 5000.0 // Hedefin yarısı kadar hafif bir idman
        let targetVolume: Double = 10000.0
        
        // 2. Act (Eylem)
        let result = sut.calculateDynamicProteinTarget(currentVolume: currentVolume, targetVolume: targetVolume)
        
        // 3. Assert (Doğrulama)
        // Beklenen: Algoritma protein aralığının alt sınırını 150g'da tutmalı
        XCTAssertEqual(result.lowerBound, 150.0, "Protein target lower bound should stay at 150.0 for light recovery days.")
    }
}
