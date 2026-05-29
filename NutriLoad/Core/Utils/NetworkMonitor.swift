import Foundation
import Network

final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")
    
    @Published var isConnected: Bool = false
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let connected = path.status == .satisfied
                self?.isConnected = connected
                
                // İnternet bağlantısı geldiği an senkronizasyon motorunu tetikliyoruz
                if connected {
                    Task { await SyncManager.shared.syncPendingWorkouts() }
                }
            }
        }
        monitor.start(queue: queue)
    }
}
