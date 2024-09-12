import SwiftUI

struct Response: Codable {
    var expand: String?
    var startAt: Int?
    var maxResults: Int?
    var total: Int?
    var issues: [Issue]
}

struct Issue: Identifiable, Codable, Hashable {
    var expand: String?
    var id: String
    var selfURL: String // Renamed from `self` to `selfURL`
    var key: String
    var fields: IssueFields
    
    private enum CodingKeys: String, CodingKey {
        case expand
        case id
        case selfURL = "self" // Map the JSON key `self` to `selfURL`
        case key
        case fields
    }
}

struct IssueFields: Codable, Hashable {
    let summary: String
    let status: Status
    let issuetype: IssueType
}

// Root Response Object for Single Issue
struct IssueResponse2: Codable {
    let fields: IssueFields2
}

struct Issue2: Identifiable, Codable, Hashable {
    var expand: String
    var id: String
    var selfURL: String // Renamed from `self` to `selfURL`
    var key: String
    var fields: IssueFields2 // Handle nested fields
    
    private enum CodingKeys: String, CodingKey {
        case expand
        case id
        case selfURL = "self"
        case key
        case fields
    }
}

// Fields Object
struct IssueFields2: Codable, Hashable {
    let issuetype: IssueType
    let summary: String
    let description: String?
    let creator: Creator
    let duedate: String?
    let status: Status
    let priority: Priority
}

// Nested Structs for Specific Fields
struct IssueType: Codable, Hashable {
    let name: String
}

struct Creator: Codable, Hashable {
    let displayName: String
}

struct Status: Codable, Hashable {
    let name: String
}

struct Priority: Codable, Hashable {
    let name: String
}

struct IssuePickerResponse: Codable {
    let sections: [IssueSection]
}

struct IssueSection: Codable {
    let issues: [Issue]
}

// Define the settings structure
struct Settings: Codable {
    var projectName: String
    var userName: String
    var apiKey: String
    
    // The path to the settings file in the user's home directory
    static var settingsFilePath: URL {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        print(homeDir)
        return homeDir.appendingPathComponent(".jiradeck_config.json")
    }
    
    // Load settings from the JSON file
    static func load() -> Settings? {
        let path = settingsFilePath
        guard FileManager.default.fileExists(atPath: path.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: path)
            let decoder = JSONDecoder()
            let settings = try decoder.decode(Settings.self, from: data)
            return settings
        } catch {
            print("Failed to load settings: \(error)")
            return nil
        }
    }
    
    // Save settings to the JSON file
    func save() {
        let path = Settings.settingsFilePath
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(self)
            try data.write(to: path)
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
}

struct ContentView: View {
    @State private var results: [Issue] = []
    @State private var selectedIssue: Issue?
    @State private var selectedIssue2: Issue2?
    @State private var selectedIssueDetails: Issue2?
    @State private var showingSettings = false
    @State private var projectName = ""
    @State private var userName = ""
    @State private var apiKey = ""
    @State private var selectedStatus: String = "All" // Default to "All"
    @State private var selectedIssueType: String = "All" // Default to "All"
    @State private var searchText = ""
    @State private var searchSuggestions: [Issue] = []
    @State private var isSearchActive = false
    
    var body: some View {
        NavigationSplitView {
            VStack {
                Menu {
                    Button("All", action: {
                        selectedStatus = "All"
                        Task {
                            selectedIssueDetails = nil
                            await loadData()
                        }
                    })
                    Button("Backlog", action: {
                        selectedStatus = "Backlog"
                        Task {
                            selectedIssueDetails = nil
                            await loadData()
                        }
                    })
                    Button("In-Progress", action: {
                        selectedStatus = "In-Progress"
                        Task {
                            selectedIssueDetails = nil
                            await loadData()
                        }
                    })
                    Button("Done", action: {
                        selectedStatus = "Done"
                        Task {
                            selectedIssueDetails = nil
                            await loadData()
                        }
                    })
                } label: {
                    Label("Status: \(selectedStatus ?? "All")", systemImage: "line.horizontal.3.decrease.circle")
                        .padding()
                        .foregroundColor(.blue)
                }
                .padding(.horizontal)
                
                // Issue Type Menu
                Menu {
                    Button("All", action: {
                        selectedIssueType = "All"
                        Task {
                            selectedIssueDetails = nil
                            await loadData()
                        }
                    })
                    Button("Story", action: {
                        selectedIssueType = "Story"
                        Task {
                            selectedIssueDetails = nil
                            await loadData()
                        }
                    })
                    Button("Bug", action: {
                        selectedIssueType = "Bug"
                        Task {
                            selectedIssueDetails = nil
                            await loadData()
                        }
                    })
                    Button("Task", action: {
                        selectedIssueType = "Task"
                        Task {
                            selectedIssueDetails = nil
                            await loadData()
                        }
                    })
                } label: {
                    Label("Issue Type: \(selectedIssueType ?? "All")", systemImage: "tag")
                        .padding()
                        .foregroundColor(.blue)
                }
                .padding(.horizontal)
                
                List(results, id: \.id, selection: $selectedIssue) { item in
                    NavigationLink(value: item) {
                        HStack {
                            Image(systemName: getIconName(for: item.fields.issuetype.name))
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text(item.key)
                                    .font(.headline)
                                Text(item.fields.summary)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(item.fields.status.name)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 5)
                                    .padding(.trailing, 5)
                                    .background(Capsule().fill(statusColor(for: item.fields.status.name)).shadow(radius: 3))
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
                .navigationTitle("Search Issues")
                .searchable(text: $searchText)
                .onChange(of: searchText) { newValue in
                    isSearchActive = !newValue.isEmpty
                    Task {
                        if newValue.isEmpty {
                            await loadData()
                        } else {
                            await fetchSearchSuggestions(for: newValue)
                        }
                    }
                }
                .refreshable {
                    await loadData()
                }
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gear")
                        }
                        
                    }
                }
                .task {
                    await loadData()
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView(
                        projectName: $projectName,
                        userName: $userName,
                        apiKey: $apiKey,
                        onDone: {
                            Task {
                                print("Running loadData")
                                await loadData()
                            }
                            // Save settings when the sheet is closed
                            let settings = Settings(projectName: projectName, userName: userName, apiKey: apiKey)
                            settings.save()
                        }
                    )
                    .onAppear {
                        // Load settings when the settings sheet appears
                        if let loadedSettings = Settings.load() {
                            projectName = loadedSettings.projectName
                            userName = loadedSettings.userName
                            apiKey = loadedSettings.apiKey
                        }
                    }
                }
                .onAppear {
                    // Also load the settings when the main view appears
                    if let loadedSettings = Settings.load() {
                        projectName = loadedSettings.projectName
                        userName = loadedSettings.userName
                        apiKey = loadedSettings.apiKey
                    }
                }
                
            }
            .onAppear {
                // Load settings when the view appears
                if let loadedSettings = Settings.load() {
                    projectName = loadedSettings.projectName
                    userName = loadedSettings.userName
                    apiKey = loadedSettings.apiKey
                }
            }
        } detail: {
            if let issue = selectedIssueDetails {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Issue Key and ID
                        Group {
                            Text(issue.key)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Text("Issue ID: \(issue.id)")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 20)
                        
                        // Issue Fields (e.g., Type, Creator, Description)
                        Group {
                            // Issue Type
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Issue Type")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(issue.fields.issuetype.name)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.bottom, 10)
                            
                            // Creator
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Creator")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(issue.fields.creator.displayName)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.bottom, 10)
                            
                            // Description
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Description")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(issue.fields.description ?? "No description available")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.bottom, 10)
                        }
                        
                        // Status and Priority
                        Group {
                            // Status
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Status")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(issue.fields.status.name)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.bottom, 10)
                            
                            // Priority
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Priority")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(issue.fields.priority.name)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.bottom, 10)
                            
                            // Due Date
                            if let dueDate = issue.fields.duedate {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Due Date")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(dueDate)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.bottom, 10)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .navigationTitle(issue.key)
                }
                .onAppear {
                    Task {
                        await getDetails(for: issue.key)
                    }
                }
            } else {
                Text("Select an issue")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
        }
        .onChange(of: selectedIssue) { _, newValue in
            if let issue = newValue {
                Task {
                    await getDetails(for: issue.key)
                }
            }
        }
    }
    
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
    
    func loadData() async {
        var jqlQuery = "project=test-project"
        
        // Append status filter if a specific status is selected (i.e., not "All")
        if selectedStatus != "All" {
            jqlQuery += " AND status=\"\(selectedStatus)\""
        }
        
        // Append issue type filter if a specific issue type is selected (i.e., not "All")
        if selectedIssueType != "All" {
            jqlQuery += " AND issuetype=\"\(selectedIssueType)\""
        }
        
        
        guard let url = URL(string: "https://\(projectName).atlassian.net/rest/api/3/search?fields=id,key,name,summary,status,issuetype&jql=\(jqlQuery)") else {
            print("Invalid URL")
            return
        }
        print(url)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let loginString = "\(userName):\(apiKey)"
        guard let loginData = loginString.data(using: .utf8) else {
            print("Failed to encode login string to Data")
            return
        }
        let base64LoginString = loginData.base64EncodedString()
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decodedResponse = try JSONDecoder().decode(Response.self, from: data)
            results = decodedResponse.issues
        } catch {
            print("Failed to decode list response with error: \(error)")
        }
    }
    
    func getDetails(for key: String) async {
        guard let url = URL(string: "https://\(projectName).atlassian.net/rest/api/2/issue/\(key)") else {
            print("Invalid URL")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let loginString = "\(userName):\(apiKey)"
        guard let loginData = loginString.data(using: .utf8) else {
            print("Failed to encode login string to Data")
            return
        }
        let base64LoginString = loginData.base64EncodedString()
        //print("Basic \(base64LoginString)")
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoder = JSONDecoder()
            let issueResponse = try decoder.decode(IssueResponse2.self, from: data)
            selectedIssueDetails = Issue2(expand: "", id: key, selfURL: "", key: key, fields: issueResponse.fields)
        } catch {
            print("Failed to decode detail response with error: \(error)")
        }
    }
    
    func getIconName(for issueType: String) -> String {
        switch issueType {
        case "Story":
            return "doc.text"
        case "Bug":
            return "ant" // Appropriate bug icon (you can change this if needed)
        case "Task":
            return "checklist" // Task-related icon
        default:
            return "questionmark.circle" // Default icon if no match
        }
    }
    
    func fetchSearchSuggestions(for query: String) async {
        guard !query.isEmpty else {
            searchSuggestions = []
            return
        }
        let jql = "summary ~ \"\(query)\" OR description ~ \"\(query)\""
        let baseUrl = "https://\(projectName).atlassian.net/rest/api/3/search?jql=\(jql)"
        guard let url = URL(string: baseUrl) else { return }
        let loginString = "\(userName):\(apiKey)"
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        guard let loginData = loginString.data(using: .utf8) else {
            print("Failed to encode login string to Data")
            return
        }
        print(request)
        let base64LoginString = loginData.base64EncodedString()
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decodedResponse = try JSONDecoder().decode(Response.self, from: data)
            results = decodedResponse.issues ?? []
        } catch {
            print("Failed to fetch suggestions: \(error)")
        }
    }
    
    func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "backlog":
            return Color.red
        case "in progress":
            return Color.orange
        case "done":
            return Color.green
        default:
            return Color.gray
        }
    }
}

#Preview {
    ContentView()
}
