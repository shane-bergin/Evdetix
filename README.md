Evdetix is a native macOS SwiftUI app that integrates with the Freshdesk API to support and streamline internal IT workflows. It provides weekly ticket tracking, SLA monitoring, and CSV/XLSX export — including exports from the built-in Event Timer, which offers insight into support-related work that may not be associated with a specific ticket.

The Generate Summary feature enables optional, fully offline AI summarization powered by Ollama using the mistral:instruct model. This feature summarizes a ticket’s description and ongoing conversation, extracting context, surfacing action items, and outlining next steps — all without exposing organizational data to external services like ChatGPT or Google Gemini. While helpful for triage, the summaries aren't always perfect; I recommend comparing them to the full ticket in Freshdesk, and I plan to upgrade the underlying model in the future.

In addition, Evdetix includes a customizable event timer for tracking time spent on general IT support activities that don’t originate from tickets. Users can create their own categories, record durations and notes, and export logs to CSV for internal documentation or reporting.

Ticket data is retrieved securely from Freshdesk using your API credentials, and the dashboard refreshes manually on demand. Evdetix is ideal for monitoring SLA performance, reviewing weekly support metrics, and quickly summarizing ticket content — best used alongside the Freshdesk web portal as a focused enhancement.

Feel free to copy, modify, and build upon this project. Copy it all and make a different app entirely, it's fine- just an API with a nice UI for MacOS. Best of luck!
