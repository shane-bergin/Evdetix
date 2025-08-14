***depending on system configuration the below commands may be required in the Macintosh Terminal application***
chmod +x Evdetix.app/Contents/Resources/ollama
chmod +x Evdetix.app/Contents/Resources/run_ollama.rb

**********************************************

Evdetix is a native macOS SwiftUI app that integrates with the Freshdesk API to support and streamline internal IT workflows. It provides weekly ticket tracking, SLA monitoring, and CSV/XLSX export; including exports from the built-in Event Timer, which offers insight into support-related work that may not be associated with a specific ticket.

The Generate Summary feature enables optional, fully offline AI summarization powered by Ollama using the mistral:instruct model. This feature summarizes a ticket’s description and ongoing conversation, extracting context, surfacing action items, and outlining next steps — all without exposing organizational data to external services like ChatGPT or Google Gemini. While helpful for triage, the summaries aren't always perfect; I recommend comparing them to the full ticket in Freshdesk, and I plan to upgrade the underlying model in the future.

In addition, Evdetix includes a customizable event timer for tracking time spent on general IT support activities that don’t originate from tickets. Users can create their own categories, record durations and notes, and export logs to CSV for internal documentation or reporting.

Ticket data is retrieved securely from Freshdesk using your API credentials, and the dashboard refreshes manually on demand. Evdetix is ideal for monitoring SLA performance, reviewing weekly support metrics, and quickly summarizing ticket content — best used alongside the Freshdesk web portal as a focused enhancement.

**********************************************
             Macintosh System Requirements
                     for Evdetix
**********************************************

Computer......... Apple Macintosh with Apple Silicon (M1 or later)
                  * Intel-based Macs (i7, 8th Gen or newer) supported
                    with Rosetta 2, but not recommended for AI tasks.

Operating System. macOS 15.0 (Sonoma) or later
                  * On macOS 16.0+ (Sequoia), some window drawing
                    artifacts may occur due to SwiftUI rendering changes.
                    These can typically be resolved by resizing the window.

Memory........... Minimum 16 MB of RAM

Hard Disk Space.. At least 10–15 GB free for Ollama model files
                  and application cache.

Graphics......... Apple Neural Engine or Metal-compatible GPU
                  * No discrete graphics card required.

Network.......... Internet connection required for accessing Freshdesk's API & first-time setup
                  of AI models.

Input Device..... Keyboard and pointing device required.
                  (Mouse, trackpad, or other compatible input)

Optional......... Terminal access to run first-time permissions fix:
                  chmod +x Evdetix.app/Contents/Resources/ollama
                  chmod +x Evdetix.app/Contents/Resources/run_ollama.rb
