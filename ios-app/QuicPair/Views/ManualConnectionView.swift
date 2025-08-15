import SwiftUI

struct ManualConnectionView: View {
    @EnvironmentObject var connectionManager: ConnectionManager
    @Environment(\.dismiss) var dismiss
    @State private var serverAddress = ""
    @State private var port = "8443"
    
    var body: some View {
        NavigationView {
            Form {
                Section("Server Details") {
                    TextField("Server Address", text: $serverAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    TextField("Port", text: $port)
                        .keyboardType(.numberPad)
                }
                
                Section {
                    Button(action: connect) {
                        Text("Connect")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(serverAddress.isEmpty)
                }
            }
            .navigationTitle("Manual Connection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func connect() {
        guard let url = URL(string: "https://\(serverAddress):\(port)") else { return }
        connectionManager.connectToServer(url: url)
        dismiss()
    }
}
