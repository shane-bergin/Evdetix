import SwiftUI

struct EventTimerView: View {
    @State private var selectedCategory: String = "Choose Category"
    @State private var startTime: Date?
    @State private var elapsedTime: TimeInterval = 0
    @State private var isRunning = false
    @State private var showCommentPrompt = false
    @State private var commentText = ""
    @State private var timer: Timer?
    @State private var logs: [EventLog] = EventLogger.load()
    @State private var showAllLogs = false
    @State private var showExportSuccess = false
    @State private var categories: [String] = EventLogger.loadCategories()
    @State private var newCategoryName = ""
    @State private var categoryToDelete: String?
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Event Timer")
                    .font(.title2)
                    .bold()
                
                HStack(spacing: 16) {
                    Picker("Time Category", selection: $selectedCategory) {
                        Text("Choose Category").tag("Choose Category")
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(minWidth: 220)
                    .onChange(of: selectedCategory) { _, category in
                        if category != "Choose Category" {
                            startTimer()
                        }
                    }

                    if isRunning {
                        Text("\(formatTime(elapsedTime))")
                            .monospacedDigit()

                        Button("Stop") {
                            stopTimer()
                            showCommentPrompt = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Divider()

            Text(" Logged Events (This Week)")
                .font(.headline)

            Toggle("Show All Logs", isOn: $showAllLogs)
                .toggleStyle(SwitchToggleStyle())
            
            Divider()

            Text("Manage Categories")
                .font(.headline)

            HStack(spacing: 10) {
                TextField("New Category", text: $newCategoryName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)

                Button("Add") {
                    let trimmed = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty && !categories.contains(trimmed) else { return }
                    categories.append(trimmed)
                    EventLogger.saveCategories(categories)
                    newCategoryName = ""
                }
                .disabled(newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(categories.filter { $0 != "Choose Category" }, id: \.self) { category in
                        HStack {
                            Text(category)
                            Spacer()
                            Button("Delete") {
                                categoryToDelete = category
                                showDeleteConfirmation = true
                            }
                            .foregroundColor(.red)
                            .buttonStyle(.plain)
                        }
                        Divider()
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(height: 120)

            Table(filteredLogs(), selection: .constant(nil)) {
                TableColumn("Timestamp") { log in
                    Text(log.timestamp.formatted(date: .abbreviated, time: .shortened))
                }
                TableColumn("Duration") { log in
                    Text(formatTime(TimeInterval(log.elapsedSeconds)))
                }
                TableColumn("Category") { log in
                    Text(log.category)
                }
                TableColumn("Note") { log in
                    Text(log.comment)
                }
            }
            .frame(height: 240)
            .background(Color.black.opacity(0.05))
            .cornerRadius(8)

            HStack {
                Button("Export All Logs to CSV") {
                    DispatchQueue.main.async {
                        exportLogsToCSV(allLogs: true)
                    }
                }
                .buttonStyle(.bordered)

                Button("Export This Week Only") {
                    DispatchQueue.main.async {
                        exportLogsToCSV(allLogs: false)
                    }
                }
                .buttonStyle(.bordered)
            }
            .alert("Export Successful!", isPresented: $showExportSuccess) {
                Button("Okay", role: .cancel) {}
            }
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showCommentPrompt) {
            VStack(spacing: 16) {
                Text("Add a note about this event:")
                    .font(.headline)

                TextEditor(text: $commentText)
                    .frame(height: 100)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5)))

                Button("Save") {
                    saveLog()
                    commentText = ""
                    selectedCategory = "Choose Category"
                    showCommentPrompt = false
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            .frame(minWidth: 400, minHeight: 220)
        }
        .alert("Delete Category?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let category = categoryToDelete {
                    categories.removeAll { $0 == category }
                    EventLogger.saveCategories(categories)
                    if selectedCategory == category {
                        selectedCategory = "Choose Category"
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this category? This cannot be undone.")
        }
    }

    func startTimer() {
        guard !selectedCategory.isEmpty else { return }
        startTime = Date()
        elapsedTime = 0
        isRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if let start = startTime {
                elapsedTime = Date().timeIntervalSince(start)
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        isRunning = false
    }

    func saveLog() {
        guard let start = startTime else { return }
        let log = EventLog(
            timestamp: start,
            elapsedSeconds: Int(elapsedTime),
            category: selectedCategory,
            comment: commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        EventLogger.append(log)
        logs.append(log)
    }

    func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func filteredLogs() -> [EventLog] {
        if showAllLogs {
            return logs.sorted { $0.timestamp > $1.timestamp }
        } else {
            let calendar = Calendar.current
            let now = Date()
            let weekOfYear = calendar.component(.weekOfYear, from: now)
            let year = calendar.component(.yearForWeekOfYear, from: now)

            return logs.filter { log in
                let logWeek = calendar.component(.weekOfYear, from: log.timestamp)
                let logYear = calendar.component(.yearForWeekOfYear, from: log.timestamp)
                return logWeek == weekOfYear && logYear == year
            }
            .sorted { $0.timestamp > $1.timestamp }
        }
    }

    func exportLogsToCSV(allLogs: Bool) {
        let exportLogs = allLogs ? logs : filteredLogs()
        export(logs: exportLogs, fileName: allLogs ? "EventLogs_All.csv" : "EventLogs_ThisWeek.csv")
    }

    func exportLogsByCategory(category: String) {
        let exportLogs = logs.filter { $0.category == category }
        export(logs: exportLogs, fileName: "EventLogs_\(category).csv")
    }

    private func export(logs: [EventLog], fileName: String) {
        let header = "Timestamp,Duration (Minutes),Category,Comment\n"
        let rows = logs.map { log in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let timestamp = formatter.string(from: log.timestamp)
            let durationMinutes = String(format: "%.2f", Double(log.elapsedSeconds) / 60.0)
            let category = log.category.replacingOccurrences(of: ",", with: ";")
            let comment = log.comment.replacingOccurrences(of: ",", with: ";")
            return "\(timestamp),\(durationMinutes),\(category),\(comment)"
        }.joined(separator: "\n")

        let csvString = header + rows

        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = fileName
        savePanel.allowedContentTypes = [.commaSeparatedText]

        if savePanel.runModal() == .OK, let url = savePanel.url {
            do {
                let bom = "\u{FEFF}" // UTF-8 Byte Order Mark
                let csvStringWithBOM = bom + csvString
                try csvStringWithBOM.write(to: url, atomically: true, encoding: .utf8)
                showExportSuccess = true
            } catch {
                print("Failed to export CSV: \(error)")
            }
        }
    }
}
