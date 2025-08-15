import Foundation

struct RecentConnection: Identifiable, Codable {
    let id = UUID()
    let deviceName: String
    let serverURL: String
    let lastConnected: Date
}
