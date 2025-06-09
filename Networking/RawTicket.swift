import SwiftUI

struct RawTicket: Codable {
    let id: Int
    let subject: String
    let priority: Int
    let created_at: Date
    let updated_at: Date
    let responder_id: Int?
    let due_by: String?
    let status: Int
    let requester_id: Int?
    let description: String?
    let custom_fields: CustomFields?

    static func priorityString(from code: Int) -> String {
        switch code {
        case 1: return "Low"
        case 2: return "Medium"
        case 3: return "High"
        case 4: return "Urgent"
        default: return "Unknown"
        }
    }
}

struct CustomFields: Codable {
    let hours_spent: Double?
    let resolved_at: String?
    let closed_at: String?
}
