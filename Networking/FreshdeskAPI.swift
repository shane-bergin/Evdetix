import Foundation

struct Conversation: Codable, Identifiable {
    let id: Int
    let body_text: String?
    let user_id: Int?
    let created_at: String?
}

enum FreshdeskAPI {
    static var apiKey: String {
        UserDefaults.standard.string(forKey: "FreshdeskAPIKey") ?? ""
    }

    static var domain: String {
        UserDefaults.standard.string(forKey: "FreshdeskDomain") ?? ""
    }

    static var slaLimitsByPriority: [String: TimeInterval] = [:]

    // MARK: - SLA Policies

    static func fetchSLAPolicies() async {
        let urlString = "\(domain)/api/v2/sla_policies"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        let credentials = "\(apiKey):X"
        if let credentialData = credentials.data(using: .utf8) {
            let base64 = credentialData.base64EncodedString()
            request.setValue("Basic \(base64)", forHTTPHeaderField: "Authorization")
        }

        struct SLATarget: Codable {
            let resolve_within: Int?
        }

        struct SLAPolicy: Codable {
            let id: Int
            let name: String
            let sla_target: [String: SLATarget]
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                print("Failed to fetch SLA policies: HTTP \(statusCode)")
                return
            }

            let policies = try JSONDecoder().decode([SLAPolicy].self, from: data)
            guard let defaultPolicy = policies.first else {
                print("No SLA policies returned.")
                return
            }

            let mapping: [String: String] = [
                "priority_1": "Low",
                "priority_2": "Medium",
                "priority_3": "High",
                "priority_4": "Urgent"
            ]

            for (key, target) in defaultPolicy.sla_target {
                if let humanKey = mapping[key], let seconds = target.resolve_within {
                    slaLimitsByPriority[humanKey] = TimeInterval(seconds)
                }
            }

            print("Loaded SLA limits: \(slaLimitsByPriority)")
        } catch {
            print("SLA policy fetch error: \(error)")
        }
    }

    static func saveCredentials(apiKey: String, domain: String) {
        UserDefaults.standard.set(apiKey, forKey: "FreshdeskAPIKey")
        UserDefaults.standard.set(domain, forKey: "FreshdeskDomain")
    }

    static func clearCredentials() {
        UserDefaults.standard.removeObject(forKey: "FreshdeskAPIKey")
        UserDefaults.standard.removeObject(forKey: "FreshdeskDomain")
    }

    // MARK: - Contact Cache

    static var contactCache: [Int: String] = [:]
    static var contactCacheURL: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = directory.appendingPathComponent("Evdetix", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("contactCache.json")
    }

    static func loadContactCache() {
        if let data = try? Data(contentsOf: contactCacheURL),
           let cached = try? JSONDecoder().decode([Int: String].self, from: data) {
            contactCache = cached
            print("Loaded contact cache with \(cached.count) entries.")
        } else {
            print("No cached contacts found.")
        }
    }

    static func saveContactCache() {
        do {
            let data = try JSONEncoder().encode(contactCache)
            try data.write(to: contactCacheURL)
            print("Saved contact cache with \(contactCache.count) entries.")
        } catch {
            print("Failed to save contact cache: \(error)")
        }
    }

    static func fetchAllContacts() async {
        var page = 1
        while true {
            let urlString = "\(domain)/api/v2/contacts?page=\(page)"
            guard let url = URL(string: urlString) else { break }

            var request = URLRequest(url: url)
            let credentials = "\(apiKey):X"
            if let credentialData = credentials.data(using: .utf8) {
                let base64Credentials = credentialData.base64EncodedString()
                request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
            }

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    print("Failed to fetch contacts: HTTP \(String(describing: (response as? HTTPURLResponse)?.statusCode))")
                    break
                }

                struct Contact: Codable {
                    let id: Int
                    let email: String?
                    let name: String?
                }

                let decoder = JSONDecoder()
                let contacts = try decoder.decode([Contact].self, from: data)
                if contacts.isEmpty {
                    break
                }

                for contact in contacts {
                    let display = contact.email ?? contact.name ?? "-"
                    contactCache[contact.id] = display
                }

                page += 1
            } catch {
                print("Error fetching contacts: \(error)")
                break
            }
        }
        saveContactCache()
    }

    // MARK: - Agent Cache

    static var agentCache: [Int: String] = [:]
    static var agentCacheURL: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = directory.appendingPathComponent("Evdetix", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("agentCache.json")
    }

    static func loadAgentCache() {
        if let data = try? Data(contentsOf: agentCacheURL),
           let cached = try? JSONDecoder().decode([Int: String].self, from: data) {
            agentCache = cached
            print("Loaded agent cache with \(cached.count) entries.")
        } else {
            print("No cached agents found.")
        }
    }

    static func saveAgentCache() {
        do {
            let data = try JSONEncoder().encode(agentCache)
            try data.write(to: agentCacheURL)
            print("Saved agent cache with \(agentCache.count) entries.")
        } catch {
            print("Failed to save agent cache: \(error)")
        }
    }

    static func fetchAllAgents() async {
        var page = 1
        while true {
            let urlString = "\(domain)/api/v2/agents?page=\(page)"
            guard let url = URL(string: urlString) else { break }

            var request = URLRequest(url: url)
            let credentials = "\(apiKey):X"
            if let credentialData = credentials.data(using: .utf8) {
                let base64Credentials = credentialData.base64EncodedString()
                request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
            }

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    print("Failed to fetch agents: HTTP \(String(describing: (response as? HTTPURLResponse)?.statusCode))")
                    break
                }

                struct Agent: Codable {
                    let id: Int
                    let contact: AgentContact?
                    let email: String?
                    let first_name: String?
                    let last_name: String?
                    let full_name: String?

                    struct AgentContact: Codable {
                        let first_name: String?
                        let last_name: String?
                        let full_name: String?
                        let email: String?
                    }
                }

                let decoder = JSONDecoder()
                let agents = try decoder.decode([Agent].self, from: data)
                if agents.isEmpty { break }

                for agent in agents {
                    var name: String? = nil
                    if let n = agent.contact?.full_name, !n.isEmpty {
                        name = n
                    } else if let n = agent.full_name, !n.isEmpty {
                        name = n
                    } else if let fn = agent.contact?.first_name, !fn.isEmpty {
                        name = fn
                    } else if let fn = agent.first_name, !fn.isEmpty {
                        name = fn
                    } else if let e = agent.email, !e.isEmpty {
                        name = e
                    } else if let e = agent.contact?.email, !e.isEmpty {
                        name = e
                    } else {
                        name = "(No Name)"
                    }
                    agentCache[agent.id] = name!
                }
                page += 1
            } catch {
                print("Error fetching agents: \(error)")
                break
            }
        }
        print("Fetched agentCache:", agentCache)
        saveAgentCache()
    }

    // MARK: - Ticket Fetching

    static func fetchAllTicketsSinceStartOfYear() async -> [Ticket] {
        print("Starting fetchAllTicketsSinceStartOfYear")
        print("API Key: \(apiKey)")
        print("Domain: \(domain)")

        let updatedSince = "2025-01-01T00:00:00Z"
        var page = 1
        var allTickets: [RawTicket] = []

        if contactCache.isEmpty {
            await fetchAllContacts()
            saveContactCache()
        }

        if agentCache.isEmpty {
            await fetchAllAgents()
            saveAgentCache()
        }

        while true {
            let urlString = "\(domain)/api/v2/tickets?updated_since=\(updatedSince)&page=\(page)&include=stats"
            print("Fetching URL: \(urlString)")
            guard let url = URL(string: urlString) else {
                print("Invalid URL: \(urlString)")
                break
            }

            var request = URLRequest(url: url)
            let credentials = "\(apiKey):X"
            if let credentialData = credentials.data(using: .utf8) {
                let base64Credentials = credentialData.base64EncodedString()
                request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
                print(" Authorization Header: \(request.value(forHTTPHeaderField: "Authorization") ?? "None")")
            }

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    print("Unexpected response")
                    break
                }

                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let pageTickets = try decoder.decode([RawTicket].self, from: data)

                if pageTickets.isEmpty {
                    break
                } else {
                    allTickets.append(contentsOf: pageTickets)
                    page += 1
                }
            } catch {
                print("Fetch failed: \(error)")
                break
            }
        }

        return allTickets.compactMap { raw in
            let priority = RawTicket.priorityString(from: raw.priority)
            let fallbackSLA: TimeInterval = 7 * 24 * 60 * 60
            let slaLimit = slaLimitsByPriority[priority] ?? fallbackSLA
            let responderId = raw.responder_id ?? -1
            let agent = agentCache[responderId] ?? "-"
            print("Ticket \(raw.id) responder_id: \(String(describing: raw.responder_id)), mapped agent: \(agent)")
            let minutesSpent = Int(raw.custom_fields?.hours_spent ?? 0)
            let requester = contactCache[raw.requester_id ?? -1] ?? "-"

            let createdAt = raw.created_at

            let resolvedAt: Date? = {
                if let resolvedStr = raw.custom_fields?.resolved_at {
                    return ISO8601DateFormatter().date(from: resolvedStr)
                }
                return nil
            }()

            let closedAt: Date? = {
                if let closedStr = raw.custom_fields?.closed_at {
                    return ISO8601DateFormatter().date(from: closedStr)
                }
                if raw.status == 4 || raw.status == 5 {
                    return raw.updated_at // fallback
                }
                return nil
            }()

            let statusText: String = {
                switch raw.status {
                case 2: return "Open"
                case 3: return "Pending"
                case 4, 5: return "Closed"
                case 6: return "Resolved"
                case 7: return "Waiting on Customer"
                case 8: return "Waiting on Third Party"
                default: return "Other (\(raw.status))"
                }
            }()

            let unresolvedDuration: TimeInterval = {
                if let endTime = closedAt ?? resolvedAt {
                    return endTime.timeIntervalSince(createdAt)
                } else {
                    return Date().timeIntervalSince(createdAt)
                }
            }()

            let violation = unresolvedDuration > slaLimit ? 1 : 0

            return Ticket(
                id: raw.id,
                createdAt: createdAt,
                subject: raw.subject,
                priority: priority,
                minutesSpent: minutesSpent,
                agent: agent,
                status: raw.status,
                statusText: statusText,
                closedAt: closedAt,
                violation: violation,
                requester: requester,
                description: raw.description
            )
        }
    }

    // MARK: - Conversation Fetching

    static func fetchConversations(for ticketId: Int) async -> [Conversation] {
        let urlString = "\(domain)/api/v2/tickets/\(ticketId)/conversations"
        guard let url = URL(string: urlString) else { return [] }

        var request = URLRequest(url: url)
        let credentials = "\(apiKey):X"
        if let credentialData = credentials.data(using: .utf8) {
            let base64Credentials = credentialData.base64EncodedString()
            request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Failed to fetch conversations for ticket \(ticketId)")
                return []
            }

            let decoder = JSONDecoder()
            return try decoder.decode([Conversation].self, from: data)
        } catch {
            print("Conversation fetch error: \(error)")
            return []
        }
    }
}
