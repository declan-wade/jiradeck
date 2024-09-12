import Foundation
import SwiftUI

class ContentViewModel: ObservableObject {
    @Published var results: [Issue] = []
    @Published var selectedIssue: Issue?
    @Published var selectedIssue2: Issue2?
    @Published var selectedIssueDetails: Issue2?
    @Published var showingSettings = false
    @Published var projectName = ""
    @Published var userName = ""
    @Published var apiKey = ""
    @Published var selectedStatus: String = "All"
    @Published var selectedIssueType: String = "All"
    @Published var searchText = ""
    @Published var searchSuggestions: [Issue] = []
    @Published var isSearchActive = false
    @Published var assignedToMe = false
    
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
        
        if assignedToMe == true {
            jqlQuery += " AND assignee=currentUser()"
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
    
}
