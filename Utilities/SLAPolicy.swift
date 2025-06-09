struct SLAPolicy: Codable, Identifiable {
    struct Escalation: Codable {
        let priority: Int
        let response: Int?
        let resolve: Int?
    }

    let name: String
    let description: String?
    let id: Int
    let escalations: [Escalation]
}
