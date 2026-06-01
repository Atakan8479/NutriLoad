import Foundation

// API hatalarını yönetmek için özel bir Hata (Error) enum'ı
enum FoodNetworkError: Error {
    case invalidURL
    case invalidResponse
    case dataDecodingError
}

final class FoodNetworkManager {
    // Tüm uygulamadan tek noktadan erişim (Singleton)
    static let shared = FoodNetworkManager()
    
    private init() {} // Dışarıdan yeni bir instance oluşturulmasını engeller
    
    // İnternetten arama yapan asenkron fonksiyon
    func searchFood(query: String) async throws -> [OFFProduct] {
        // 1. Kullanıcının yazdığı metindeki boşlukları (örn: "oat meal") URL formatına (%20) çevir
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://tr.openfoodfacts.org/cgi/search.pl?search_terms=\(encodedQuery)&search_simple=1&action=process&json=1") else {
            throw FoodNetworkError.invalidURL
        }
        
        // 2. İnternet isteğini at ve veriyi bekle (Thread'i dondurmaz!)
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // 3. Gelen cevabın 200 (Başarılı) olup olmadığını kontrol et
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw FoodNetworkError.invalidResponse
        }
        
        // 4. Gelen karmaşık JSON'ı bizim yarattığımız temiz DTO modeline çevir
        do {
            let decoder = JSONDecoder()
            let offResponse = try decoder.decode(OFFResponse.self, from: data)
            
            // İçinde isim ve makro bilgisi olmayan çöp ürünleri filtrele ve geri döndür
            let validProducts = offResponse.products.filter {
                $0.productName != nil && $0.productName?.isEmpty == false
            }
            return validProducts
            
        } catch {
            print("❌ API Çözümleme Hatası: \(error)")
            throw FoodNetworkError.dataDecodingError
        }
    }
}
