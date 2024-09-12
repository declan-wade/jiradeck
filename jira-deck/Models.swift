import Foundation

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
    let assignee: Assignee?
}

// Nested Structs for Specific Fields
struct IssueType: Codable, Hashable {
    let name: String
}

struct Assignee: Codable, Hashable {
    let displayName: String
    let emailAddress: String
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
