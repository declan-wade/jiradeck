import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
        NavigationSplitView {
            VStack {
                // Status Menu
                Menu {
                    Button("All", action: {
                        viewModel.selectedStatus = "All"
                        Task {
                            viewModel.selectedIssueDetails = nil
                            await viewModel.loadData()
                        }
                    })
                    Button("Backlog", action: {
                        viewModel.selectedStatus = "Backlog"
                        Task {
                            viewModel.selectedIssueDetails = nil
                            await viewModel.loadData()
                        }
                    })
                    Button("In-Progress", action: {
                        viewModel.selectedStatus = "In-Progress"
                        Task {
                            viewModel.selectedIssueDetails = nil
                            await viewModel.loadData()
                        }
                    })
                    Button("Done", action: {
                        viewModel.selectedStatus = "Done"
                        Task {
                            viewModel.selectedIssueDetails = nil
                            await viewModel.loadData()
                        }
                    })
                } label: {
                    Label("Status: \(viewModel.selectedStatus)", systemImage: "line.horizontal.3.decrease.circle")
                        .padding()
                        .foregroundColor(.blue)
                }
                .padding(.horizontal)
                
                // Issue Type Menu
                Menu {
                    Button("All", action: {
                        viewModel.selectedIssueType = "All"
                        Task {
                            viewModel.selectedIssueDetails = nil
                            await viewModel.loadData()
                        }
                    })
                    Button("Story", action: {
                        viewModel.selectedIssueType = "Story"
                        Task {
                            viewModel.selectedIssueDetails = nil
                            await viewModel.loadData()
                        }
                    })
                    Button("Bug", action: {
                        viewModel.selectedIssueType = "Bug"
                        Task {
                            viewModel.selectedIssueDetails = nil
                            await viewModel.loadData()
                        }
                    })
                    Button("Task", action: {
                        viewModel.selectedIssueType = "Task"
                        Task {
                            viewModel.selectedIssueDetails = nil
                            await viewModel.loadData()
                        }
                    })
                } label: {
                    Label("Issue Type: \(viewModel.selectedIssueType)", systemImage: "tag")
                        .padding()
                        .foregroundColor(.blue)
                }
                .padding(.horizontal)
                
                // Toggle for "Assigned to me"
                Toggle("Assigned to me", isOn: $viewModel.assignedToMe)
                    .padding(.bottom, 10)
                    .onChange(of: viewModel.assignedToMe) { _ in
                        Task {
                            viewModel.selectedIssueDetails = nil
                            await viewModel.loadData()
                        }
                    }
                
                // List of results
                List(viewModel.results, id: \.id, selection: $viewModel.selectedIssue) { item in
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
                .searchable(text: $viewModel.searchText)
                .onChange(of: viewModel.searchText) { newValue in
                    viewModel.isSearchActive = !newValue.isEmpty
                    Task {
                        if newValue.isEmpty {
                            await viewModel.loadData()
                        } else {
                            await viewModel.fetchSearchSuggestions(for: newValue)
                        }
                    }
                }
                .refreshable {
                    await viewModel.loadData()
                }
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        Button(action: {
                            viewModel.showingSettings = true
                        }) {
                            Image(systemName: "gear")
                        }
                    }
                }
                .task {
                    await viewModel.loadData()
                }
                .sheet(isPresented: $viewModel.showingSettings) {
                    SettingsView(
                        projectName: $viewModel.projectName,
                        userName: $viewModel.userName,
                        apiKey: $viewModel.apiKey,
                        onDone: {
                            Task {
                                print("Running loadData")
                                await viewModel.loadData()
                            }
                            // Save settings when the sheet is closed
                            let settings = Settings(projectName: viewModel.projectName, userName: viewModel.userName, apiKey: viewModel.apiKey)
                            settings.save()
                        }
                    )
                    .onAppear {
                        // Load settings when the settings sheet appears
                        if let loadedSettings = Settings.load() {
                            viewModel.projectName = loadedSettings.projectName
                            viewModel.userName = loadedSettings.userName
                            viewModel.apiKey = loadedSettings.apiKey
                        }
                    }
                }
                .onAppear {
                    // Also load the settings when the main view appears
                    if let loadedSettings = Settings.load() {
                        viewModel.projectName = loadedSettings.projectName
                        viewModel.userName = loadedSettings.userName
                        viewModel.apiKey = loadedSettings.apiKey
                    }
                }
            }
        } detail: {
            if let issue = viewModel.selectedIssueDetails {
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
                        await viewModel.getDetails(for: issue.key)
                    }
                }
            } else {
                Text("Select an issue")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
        }
        .onChange(of: viewModel.selectedIssue) { _, newValue in
            if let issue = newValue {
                Task {
                    await viewModel.getDetails(for: issue.key)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ContentViewModel())
}
