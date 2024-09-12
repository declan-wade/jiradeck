import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var projectName: String
    @Binding var userName: String
    @Binding var apiKey: String
    var onDone: () -> Void
    
    var body: some View {
        Form {
            Section(header: Text("Project Settings")) {
                TextField("Project Name", text: $projectName)
                TextField("User Name", text: $userName)
                SecureField("API Key", text: $apiKey)
            }
        }
        .padding()
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    onDone()
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .frame(width: 500)
    }
}
