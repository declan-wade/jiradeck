import SwiftUI

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
