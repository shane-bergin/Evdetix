import SwiftUI

func registerMistralInstructModelIfNeeded() {
    guard let resourceURL = Bundle.main.resourceURL else { return }
    let ollamaURL = resourceURL.appendingPathComponent("ollama")
    let modelfileURL = resourceURL.appendingPathComponent("Modelfile")
    let modelDir = resourceURL.path

    let checkProcess = Process()
    let outputPipe = Pipe()
    checkProcess.executableURL = ollamaURL
    checkProcess.arguments = ["list"]
    checkProcess.standardOutput = outputPipe
    checkProcess.environment = ["OLLAMA_MODELS": modelDir]
    try? checkProcess.run()
    checkProcess.waitUntilExit()

    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    let outputString = String(data: outputData, encoding: .utf8) ?? ""

    guard !outputString.contains("mistral:instruct") else {
        print("mistral:instruct model already registered in bundled Ollama")
        return
    }

    let registerProcess = Process()
    registerProcess.executableURL = ollamaURL
    registerProcess.arguments = ["create", "mistral:instruct", "-f", modelfileURL.path]
    registerProcess.environment = ["OLLAMA_MODELS": modelDir]
    let regPipe = Pipe()
    registerProcess.standardOutput = regPipe
    registerProcess.standardError = regPipe
    try? registerProcess.run()
    registerProcess.waitUntilExit()
    let regOutput = regPipe.fileHandleForReading.readDataToEndOfFile()
    print("Ollama model registration output: \(String(data: regOutput, encoding: .utf8) ?? "")")
}

struct ContentView: View {
    @State private var allFetchedTickets: [Ticket] = []
    @State private var filteredTickets: [Ticket] = []
    @State private var showCredentialsPrompt = false
    @State private var showOnboardingWindow = false

    let weeks = WeekGenerator.generateWeeks2025()
    @State private var selectedWeek: WeekRange = WeekGenerator.currentWeek(in: WeekGenerator.generateWeeks2025())
    @State private var tickets: [Ticket] = []
    @State private var isLoading = false
    @State private var didLoadCache = false
    @State private var selectedAgent: String = "All Agents"

    var totalTimeSpent: Int { tickets.reduce(0) { $0 + $1.minutesSpent } }
    var totalTickets: Int { tickets.count }
    var ticketsClosed: Int { tickets.filter { $0.statusText == "Closed" }.count }
    var totalSlaViolatedThisWeek: Int { filteredTickets.reduce(0) { $0 + $1.violation } }
    var totalSlaViolatedYTD: Int { allFetchedTickets.reduce(0) { $0 + $1.violation } }
    var overallTicketsClosed: Int {
        tickets.filter {
            guard let closed = $0.closedAt else { return false }
            return closed >= selectedWeek.start && closed <= selectedWeek.end.addingTimeInterval(86399)
        }.count
    }

    var body: some View {
        TabView {
            
            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Weekly Ticket Dashboard")
                        .font(.largeTitle)
                        .bold()

                    Button("Refresh") {
                        refreshTicketData()
                    }
                    .help("Check for updates to ticket data")

                    Picker("Select Week", selection: $selectedWeek) {
                        ForEach(weeks, id: \.self) { week in
                            Text(week.description).tag(week)
                        }
                    }
                    .help("Select a Mon–Fri timeframe")
                    .pickerStyle(PopUpButtonPickerStyle())
                    .onChange(of: selectedWeek) { _, newWeek in
                        Task { await filterTickets(for: newWeek) }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 24) {
                            Text("Total Time Spent: \(totalTimeSpent) minutes")
                            Text("Week Tickets Created: \(totalTickets)")
                            Text("SLA Violated (Week): \(totalSlaViolatedThisWeek)")
                            Text("Week Tickets Closed: \(ticketsClosed)")
                        }
                    }

                    Button("Reset API Key & Domain") {
                        showCredentialsResetConfirmation()
                    }
                    .help("Reset the Freshdesk API key and domain. You will be required to enter new details to continue.")

                    Divider()

                    if isLoading {
                        ProgressView("Please wait...")
                            .progressViewStyle(LinearProgressViewStyle())
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding()
                    } else if tickets.isEmpty {
                        Text("No tickets for this week.")
                            .foregroundStyle(.secondary)
                    } else {
                        TicketTableView(tickets: tickets, selectedAgent: $selectedAgent)
                    }

                    Spacer()

                    Button("Rebuild Contact Cache") {
                        isLoading = true
                        Task {
                            await FreshdeskAPI.fetchAllContacts()
                            FreshdeskAPI.saveContactCache()
                            allFetchedTickets = await FreshdeskAPI.fetchAllTicketsSinceStartOfYear()
                            await filterTickets(for: selectedWeek)
                            isLoading = false
                        }
                    }
                    .help("Rebuilds the contact cache from Freshdesk.")
                }
                .frame(minWidth: 700)

                EventTimerView()
                    .frame(minWidth: 400)
            }
            .tabItem {
                Label("Dashboard", systemImage: "person.badge.plus")
            }
        }
        .onAppear {
            registerMistralInstructModelIfNeeded()
            ensureOllamaIsRunning()
            if FreshdeskAPI.apiKey.isEmpty || FreshdeskAPI.domain.isEmpty {
                showCredentialsPrompt = true
            }

            if !didLoadCache {
                FreshdeskAPI.loadContactCache()
                didLoadCache = true

                Task {
                    isLoading = true
                    await FreshdeskAPI.fetchSLAPolicies()
                    allFetchedTickets = await FreshdeskAPI.fetchAllTicketsSinceStartOfYear()
                    await filterTickets(for: selectedWeek)

                    let current = selectedWeek
                    selectedWeek = weeks.first ?? current
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        selectedWeek = current
                    }

                    isLoading = false
                }
            }
        }
        .sheet(isPresented: $showCredentialsPrompt) {
            CredentialsPromptView(isPresented: $showCredentialsPrompt)
        }
    }

    private func showCredentialsResetConfirmation() {
        let alert = NSAlert()
        alert.messageText = "Reset API Key & Domain"
        alert.informativeText = "This cannot be undone and you will need to enter a valid API key and domain to use the app. Proceed?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")

        if alert.runModal() == .alertFirstButtonReturn {
            FreshdeskAPI.clearCredentials()
            DispatchQueue.main.async {
                showCredentialsPrompt = true
            }
        }
    }

    private func refreshTicketData() {
        isLoading = true
        Task {
            allFetchedTickets = await FreshdeskAPI.fetchAllTicketsSinceStartOfYear()
            await filterTickets(for: selectedWeek)
            isLoading = false
        }
    }

    private func filterTickets(for week: WeekRange) async {
        filteredTickets = allFetchedTickets.filter {
            $0.createdAt >= week.start && $0.createdAt <= week.end.addingTimeInterval(86399)
        }
        tickets = filteredTickets
    }
}
