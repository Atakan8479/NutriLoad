import Foundation
import CoreData

final class CoreDataManager {
    
    // Singleton Design Pattern: Tüm uygulama aynı veritabanı motorunu kullanır
    static let shared = CoreDataManager()
    
    // xcdatamodeld dosyanın birebir adıdır.
    private let modelName = "NutriLoadDataModel"
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName)
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                // Not: Prodüksiyon (Canlı) ortamında burası Crashlytics gibi bir araca loglanmalıdır.
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        // ÇAKIŞMA ÇÖZÜMÜ (Conflict Resolution):
        // Main thread ve background thread aynı veriye erişirse, hafızadaki (memory) yeni veriyi kabul et.
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    // 1. Arayüz (UI) Katmanı İçin Bağlam -> Sadece Main Thread'de kullanılır (SwiftUI View'lar için)
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // 2. Arka Plan Katmanı İçin Bağlam -> Sunucudan veri geldiğinde veya asenkron ağır hesaplamalarda kullanılır
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    // Generic ve Güvenli Kaydetme (Save) Fonksiyonu
    func saveContext(_ context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print("Lokal veritabanı kayıt hatası: \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
