import SwiftUI

struct CreateIssueView: View {
    @StateObject private var viewModel = ContentViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    // Constants
    let issueTypes = ["Bug", "Story", "Task"]
    let statuses = ["To Do", "In Progress", "Done"]
    
    // State variables
    @State private var selectedIssueTypeCreate: String
    @State private var selectedStatusCreate: String
    @State private var summary: String
    @State private var description: String
    
    // Callback
    var onDone: () async -> Void
    
    // Initializer
    init(onDone: @escaping () async -> Void) {
        self.onDone = onDone
        // Initialize state variables
        _selectedIssueTypeCreate = State(initialValue: "Bug")
        _selectedStatusCreate = State(initialValue: "To Do")
        _summary = State(initialValue: "")
        _description = State(initialValue: "")
    }
    
    var body: some View {
        Form {
            Section(header: Text("Issue Type")) {
                Picker("Issue Type", selection: $selectedIssueTypeCreate) {
                    ForEach(issueTypes, id: \.self) { type in
                        Text(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            Section(header: Text("Status")) {
                Picker("Status", selection: $selectedStatusCreate) {
                    ForEach(statuses, id: \.self) { status in
                        Text(status)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            Section(header: Text("Summary")) {
                TextField("Enter summary", text: $summary)
            }
            
            Section(header: Text("Description")) {
                TextEditor(text: $description)
                    .frame(height: 150)
            }
            
            Button(action: {
                Task {
                    await onDone()
                    presentationMode.wrappedValue.dismiss()
                }
            }) {
                Text("Create Issue")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}
