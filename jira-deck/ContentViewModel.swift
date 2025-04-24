import Foundation
import SwiftUI

class ContentViewModel: ObservableObject {
    @Published var results: [Issue] = []
    @Published var selectedIssue: Issue?
    @Published var selectedIssue2: Issue2?
    @Published var selectedIssueDetails: Issue2?
    @Published var showingSettings = false
    @Published var showingAdd = false
    @Published var projectName = ""
    @Published var userName = ""
    @Published var apiKey = ""
    @Published var selectedStatus: String = "All"
    @Published var selectedIssueType: String = "All"
    @Published var searchText = ""
    @Published var searchSuggestions: [Issue] = []
    @Published var isSearchActive = false
    @Published var assignedToMe = false
    @Published var selectedIssueTypeCreate = "Bug"
    @Published var selectedStatusCreate = "To Do"
    @Published var summary = ""
    @Published var description = ""
    
    // Helper function to build URLs safely using URLComponents
    func createURL(apiVersion: String, path: String, queryItems: [URLQueryItem]? = nil) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "\(projectName).atlassian.net"
        components.path = "/rest/api/\(apiVersion)/\(path)"
        components.queryItems = queryItems
        return components.url
    }
    
    // Helper function to create a URLRequest with necessary headers and authentication
    func createRequest(with url: URL) -> URLRequest? {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let loginString = "\(userName):\(apiKey)"
        guard let loginData = loginString.data(using: .utf8) else {
            print("Failed to encode login string to Data")
            return nil
        }
        let base64LoginString = loginData.base64EncodedString()
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        return request
    }
    
    // Generic function to perform network requests and decode responses
    func performRequest<T: Decodable>(with request: URLRequest, decodeTo type: T.Type) async throws -> T {
        let (data, _) = try await URLSession.shared.data(for: request)
        let decodedResponse = try JSONDecoder().decode(T.self, from: data)
        return decodedResponse
    }
    
    // Refactored loadData function
    func loadData() async {
        var jqlQuery = "project=daco"
        
        // Append status filter if a specific status is selected (i.e., not "All")
        if selectedStatus != "All" {
            jqlQuery += " AND status=\"\(selectedStatus)\""
        }
        
        // Append issue type filter if a specific issue type is selected (i.e., not "All")
        if selectedIssueType != "All" {
            jqlQuery += " AND issuetype=\"\(selectedIssueType)\""
        }
        
        if assignedToMe {
            jqlQuery += " AND assignee=currentUser()"
        }
        
        let queryItems = [
            URLQueryItem(name: "fields", value: "id,key,name,summary,status,issuetype"),
            URLQueryItem(name: "jql", value: jqlQuery)
        ]
        
        guard let url = createURL(apiVersion: "3", path: "search", queryItems: queryItems),
              let request = createRequest(with: url) else {
            print("Invalid URL or failed to create request")
            return
        }
        
        do {
            let decodedResponse: Response = try await performRequest(with: request, decodeTo: Response.self)
            results = decodedResponse.issues
        } catch {
            print("Failed to load data with error: \(error)")
        }
    }
    
    // Refactored getDetails function
    func getDetails(for key: String) async {
        guard let url = createURL(apiVersion: "2", path: "issue/\(key)"),
              let request = createRequest(with: url) else {
            print("Invalid URL or failed to create request")
            return
        }
        
        do {
            let issueResponse: IssueResponse2 = try await performRequest(with: request, decodeTo: IssueResponse2.self)
            selectedIssueDetails = Issue2(expand: "", id: key, selfURL: "", key: key, fields: issueResponse.fields)
        } catch {
            print("Failed to get details with error: \(error)")
        }
    }
    
    // Refactored fetchSearchSuggestions function
    func fetchSearchSuggestions(for query: String) async {
        guard !query.isEmpty else {
            searchSuggestions = []
            return
        }
        let jql = "summary ~ \"\(query)\" OR description ~ \"\(query)\""
        let queryItems = [URLQueryItem(name: "jql", value: jql)]
        
        guard let url = createURL(apiVersion: "3", path: "search", queryItems: queryItems),
              let request = createRequest(with: url) else {
            print("Invalid URL or failed to create request")
            return
        }
        
        do {
            let decodedResponse: Response = try await performRequest(with: request, decodeTo: Response.self)
            results = decodedResponse.issues ?? []
        } catch {
            print("Failed to fetch suggestions: \(error)")
        }
    }
    
    func createIssue() async {
        guard let url = URL(string: "https://\(projectName).atlassian.net/rest/api/3/issue") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let loginString = "\(userName):\(apiKey)"
        guard let loginData = loginString.data(using: .utf8) else {
            print("Failed to encode login string")
            return
        }
        let base64LoginString = loginData.base64EncodedString()
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        // Set headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prepare the payload
        let payload: [String: Any] = [
            "fields": [
                "project": [
                    "key": "TST"
                ],
                "summary": summary,
                "description": description,
                "issuetype": [
                    "name": selectedIssueType
                ]
            ]
        ]
        print(payload)
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            request.httpBody = jsonData
        } catch {
            print("Failed to encode payload: \(error)")
            return
        }
        
        // Perform the request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                return
            }
            if (200...299).contains(httpResponse.statusCode) {
                print("Issue created successfully")
                // Parse the response to get the issue key
                if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let issueKey = jsonResponse["key"] as? String {
                    // Transition the issue to the desired status
                    await transitionIssue(issueKey: issueKey)
                }
            } else {
                print("Server error: \(httpResponse.statusCode)")
            }
        } catch {
            print("Request error: \(error)")
        }
    }
    
    func transitionIssue(issueKey: String) async {
        // Fetch available transitions
        guard let transitionsURL = URL(string: "https://\(projectName).atlassian.net/rest/api/3/issue/\(issueKey)/transitions") else {
            print("Invalid URL for transitions")
            return
        }
        
        var request = URLRequest(url: transitionsURL)
        request.httpMethod = "GET"
        let loginString = "\(userName):\(apiKey)"
        guard let loginData = loginString.data(using: .utf8) else {
            print("Failed to encode login string")
            return
        }
        let base64LoginString = loginData.base64EncodedString()
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let transitions = jsonResponse["transitions"] as? [[String: Any]] {
                // Find the transition ID for the selected status
                if let transition = transitions.first(where: { ($0["name"] as? String) == selectedStatus }),
                   let transitionId = transition["id"] as? String {
                    // Perform the transition
                    await performTransition(issueKey: issueKey, transitionId: transitionId)
                } else {
                    print("Transition to '\(selectedStatus)' not found")
                }
            }
        } catch {
            print("Failed to fetch transitions: \(error)")
        }
    }
    
    func performTransition(issueKey: String, transitionId: String) async {
        guard let url = URL(string: "https://\(projectName).atlassian.net/rest/api/3/issue/\(issueKey)/transitions") else {
            print("Invalid URL for performing transition")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let loginString = "\(userName):\(apiKey)"
        guard let loginData = loginString.data(using: .utf8) else {
            print("Failed to encode login string")
            return
        }
        let base64LoginString = loginData.base64EncodedString()
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "transition": [
                "id": transitionId
            ]
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            request.httpBody = jsonData
        } catch {
            print("Failed to encode transition payload: \(error)")
            return
        }
        
        // Perform the request
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                return
            }
            if (200...299).contains(httpResponse.statusCode) {
                print("Issue transitioned to '\(selectedStatus)' successfully")
            } else {
                print("Failed to transition issue: \(httpResponse.statusCode)")
            }
        } catch {
            print("Transition request error: \(error)")
        }
    }
    
}
