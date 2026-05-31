import Foundation

// 1. En Dıştaki Kapsayıcı (Wrapper): API bize doğrudan liste dönmez, "products" adında bir dizi döner.
struct OFFResponse: Decodable {
    let products: [OFFProduct]
}

// 2. Ürünün Kendisi: Sadece ID, İsim ve Besin Değerlerini çekiyoruz.
struct OFFProduct: Identifiable, Decodable {
    let id: String
    let productName: String? // Bazı ürünlerin adı girilmemiş olabilir, uygulamanın çökmemesi için Optional (?) yapıyoruz
    let nutriments: OFFNutriments?

    // API'den gelen saçma isimleri (örneğin _id) Swift'in temiz yapısına (id) bağlıyoruz
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case productName = "product_name"
        case nutriments
    }
}

// 3. İç İçe Geçmiş (Nested) Besin Değerleri: Sadece Kalori ve Protein
struct OFFNutriments: Decodable {
    let energyKcal100g: Double?
    let proteins100g: Double?

    // API'deki tireli ve alt tireli karmaşık anahtarları (keys) temiz değişkenlere eşliyoruz
    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case proteins100g = "proteins_100g"
    }
}
