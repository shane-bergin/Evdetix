import SwiftUI

enum OllamaModel {
    static let defaultModel = "mistral:instruct"
}

struct TicketDetailView: View {
    let ticket: Ticket
    @Binding var summaryText: String?
    @Binding var reducedSummaryText: String?
    @Binding var isGeneratingSummary: Bool
    @State private var conversations: [Conversation] = []
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Ticket #\(ticket.id.description)").font(.title2).bold()
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.secondary)
                        .help("Close")
                }
                .buttonStyle(.plain)
            }

            Text("Subject: \(ticket.subject)").font(.headline)
            Text("Status: \(ticket.statusText)")
            Text("Agent: \(ticket.agent)")
            Text("Requester: \(ticket.requester)")

            Divider()

            if let desc = ticket.description, !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(desc)
                    .padding(.vertical, 4)
                    .font(.body)
                    .textSelection(.enabled)
            }

            HStack(spacing: 12) {
                Button("Generate Summary") {
                    isGeneratingSummary = true
                    Task {
                        let prompt = buildPrompt(ticket: ticket, conversations: conversations)
                        if await waitUntilOllamaIsReady() {
                            print("Ollama is ready. Proceeding to summarize...")
                            summaryText = await summarizeWithOllama(prompt: prompt) ?? "Summary generation failed."
                        } else {
                            summaryText = "Ollama server did not start in time. Try again in a moment."
                        }
                        isGeneratingSummary = false
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isGeneratingSummary)
                
            }
            .padding(.top, 4)

            if isGeneratingSummary {
                ProgressView("Summarizing...")
                    .padding(.vertical, 6)
            } else {
                if let summary = summaryText, summary.contains("Failed") || summary.contains("did not start") {
                    Text(summary)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.bottom, 4)

                    Button("Retry Summary") {
                        Task {
                            let prompt = buildPrompt(ticket: ticket, conversations: conversations)
                            if await waitUntilOllamaIsReady() {
                                summaryText = await summarizeWithOllama(prompt: prompt) ?? "Summary generation failed."
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            if let finalText = reducedSummaryText ?? summaryText,
               !finalText.contains("Failed"),
               !finalText.contains("did not start") {
                Divider()
                Text("Summary")
                    .font(.headline)
                ScrollView {
                    Text(finalText)
                        .padding(6)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 100)
            }

            Divider()

            Text("Conversation Thread")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if isLoading {
                ProgressView("Loading conversation...")
            } else if conversations.isEmpty {
                Text("(No correspondence found)").italic().foregroundColor(.secondary)
            } else {
                ScrollView {
                    ForEach(conversations) { convo in
                        VStack(alignment: .leading, spacing: 4) {
                            if let body = convo.body_text, !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(body)
                                    .font(.body)
                                    .padding(.bottom, 2)
                                    .textSelection(.enabled)
                            }
                            if let date = convo.created_at {
                                Text(date).font(.caption).foregroundColor(.gray)
                            }
                            Divider()
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
        .frame(minWidth: 540, minHeight: 400)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            Task {
                isLoading = true
                conversations = await FreshdeskAPI.fetchConversations(for: ticket.id)
                isLoading = false
            }
        }
    }

    private func buildPrompt(ticket: Ticket, conversations: [Conversation]) -> String {
        var lines: [String] = []

        lines.append("""
        You are an internal IT summarization assistant. Extract and list only the following categories:
        • Problems
        • Requests
        • Actions taken
        • Resolutions
        Use clear, concise phrasing. Avoid filler, speculation, status updates, or organizational names.
        """)

        lines.append("Subject: \(ticket.subject)")
        lines.append("Priority: \(ticket.priority)")
        lines.append("Status: \(ticket.statusText)")

        if let desc = ticket.description, !desc.isEmpty {
            lines.append("\nDescription:\n\(desc)")
        }

        let messages = conversations
            .compactMap { $0.body_text?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if !messages.isEmpty {
            lines.append("\nConversation:\n" + messages.joined(separator: "\n\n"))
        }

        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func summarizeWithOllama(prompt: String) async -> String? {
        guard let url = URL(string: "http://localhost:11434/api/generate") else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": OllamaModel.defaultModel,
            "prompt": prompt,
            "stream": false
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Unexpected response from Ollama: \(String(data: data, encoding: .utf8) ?? "Unknown")")
                return "Unexpected response from Ollama."
            }

            struct Response: Decodable { let response: String }
            let decoded = try JSONDecoder().decode(Response.self, from: data)

            return decoded.response.trimmingCharacters(in: .whitespacesAndNewlines)

        } catch {
            print("Ollama summarization error: \(error)")
            return "Failed to generate summary."
        }
    }
}
