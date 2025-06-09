import SwiftUI

struct TicketTableView: View {
    let tickets: [Ticket]
    @Binding var selectedAgent: String
    @State private var copiedTicketID: Int? = nil
    @State private var showTicketDetailPopup = false
    @State private var selectedDetailTicket: Ticket? = nil
    @State private var selectedTicketSummary: String? = nil
    @State private var isGeneratingSummary = false
    @State private var reducedSummaryText: String? = nil

    var filteredTickets: [Ticket] {
        selectedAgent == "All Agents"
            ? tickets
            : tickets.filter { $0.agent == selectedAgent }
    }

    var allAgents: [String] {
        let names = Set(tickets.map { $0.agent })
        return ["All Agents"] + names.sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Filter by Agent", selection: $selectedAgent) {
                ForEach(allAgents, id: \.self) { agent in
                    Text(agent)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(width: 240)

            Table(of: Ticket.self) {
                TableColumn("Ticket #") { ticket in
                    let displayText = "#\(ticket.id.description)"
                    let ticketURL = "\(FreshdeskAPI.domain)/a/tickets/\(ticket.id)"

                    VStack(alignment: .leading, spacing: 2) {
                        Button(action: {
                            
                            if selectedDetailTicket?.id != ticket.id {
                                selectedTicketSummary = nil
                                reducedSummaryText = nil
                            }

                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(ticketURL, forType: .string)
                            copiedTicketID = ticket.id
                            selectedDetailTicket = ticket
                            showTicketDetailPopup = true

                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                if copiedTicketID == ticket.id {
                                    copiedTicketID = nil
                                }
                            }
                        }) {
                            Text(displayText)
                                .underline()
                                .foregroundColor(ticket.violation == 1 ? .red : .blue)
                                .help("Click to view ticket details and copy Freshdesk ticket link")
                        }
                        .buttonStyle(.plain)

                        if copiedTicketID == ticket.id {
                            Text("✅ Copied!")
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .transition(.opacity)
                        }
                    }
                }
                TableColumn("Status") { ticket in Text(ticket.statusText) }
                TableColumn("Subject") { ticket in Text(ticket.subject) }
                TableColumn("Priority") { ticket in Text(ticket.priority) }
                TableColumn("Minutes Spent") { ticket in Text("\(ticket.minutesSpent)") }
                TableColumn("Agent") { ticket in Text(ticket.agent) }
                TableColumn("Requester") { ticket in Text(ticket.requester) }
            } rows: {
                ForEach(filteredTickets) { ticket in
                    TableRow(ticket)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: copiedTicketID)
        .sheet(isPresented: $showTicketDetailPopup, onDismiss: {

            selectedTicketSummary = nil
            reducedSummaryText = nil
        }) {
            if let ticket = selectedDetailTicket {
                TicketDetailView(
                    ticket: ticket,
                    summaryText: $selectedTicketSummary,
                    reducedSummaryText: $reducedSummaryText,
                    isGeneratingSummary: $isGeneratingSummary
                )
            }
        }
    }
}
