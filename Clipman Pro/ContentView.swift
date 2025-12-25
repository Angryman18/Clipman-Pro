//
 //  ContentView.swift
 //  Clipman Pro
 //
 //  Created by Shyam Mahanta on 25/12/25.
 //

 import SwiftUI

struct ContentView: View {
    @EnvironmentObject var clipboardManager: ObservableClipboardManager
    @State private var selectedItem: ClipboardItem?
    @State private var maxItems: Int = 0
    @State private var previousMaxItems: Int = 0

    init() {
        let currentMaxItems = SettingsManager.shared.maxItems
        _maxItems = State(initialValue: currentMaxItems)
        _previousMaxItems = State(initialValue: currentMaxItems)
    }

     var body: some View {
         VStack(spacing: 0) {
             // Header
             VStack(spacing: 12) {
                 HStack {
                     Text("Clipboard Manager")
                         .font(.title2)
                         .fontWeight(.semibold)

                     Spacer()

                     Button(action: {
                         let alert = NSAlert()
                         alert.messageText = "Clear All Items"
                         alert.informativeText = "Are you sure you want to delete all clipboard items? This action cannot be undone."
                         alert.alertStyle = .warning
                         alert.addButton(withTitle: "Clear All")
                         alert.addButton(withTitle: "Cancel")

                         let response = alert.runModal()
                         if response == .alertFirstButtonReturn {
                             clipboardManager.clearClipboardHistory()
                         }
                     }) {
                         Text("Clear All")
                             .foregroundColor(.red)
                             .font(.caption)
                     }
                     .buttonStyle(.plain)
                     .help("Clear all clipboard items")
                 }

                 // Settings controls
                 HStack(spacing: 16) {
                     HStack(spacing: 8) {
                         Text("Show items:")
                             .font(.caption)
                             .foregroundColor(.secondary)

                        Picker("", selection: $maxItems) {
                            ForEach([25, 50, 75, 100, 150, 200, 300], id: \.self) { number in
                                Text("\(number)").tag(number)
                            }
                        }
                        .frame(width: 80)
                        .onChange(of: maxItems) { newValue in
                            print("DEBUG: onChange triggered - previous value: \(previousMaxItems), new value: \(newValue)")
                            if newValue < previousMaxItems {
                                print("DEBUG: Lowering value detected - showing alert")
                                // Show NSAlert when lowering the value
                                let alert = NSAlert()
                                alert.messageText = "Confirm Change"
                                alert.informativeText = "You are lowering the maximum items from \(previousMaxItems) to \(newValue). Some clipboard items may be deleted. Continue?"
                                alert.alertStyle = .warning
                                alert.addButton(withTitle: "Continue")
                                alert.addButton(withTitle: "Cancel")

                                print("DEBUG: About to show NSAlert")
                                let response = alert.runModal()
                                print("DEBUG: Alert response received: \(response)")
                                if response == .alertFirstButtonReturn {
                                    print("DEBUG: User clicked Continue")
                                    // User clicked Continue
                                    SettingsManager.shared.maxItems = newValue
                                    clipboardManager.truncateItems(to: newValue)
                                    previousMaxItems = newValue
                                } else {
                                    print("DEBUG: User clicked Cancel - reverting selection")
                                    // User clicked Cancel, revert the selection
                                    maxItems = previousMaxItems
                                }
                            } else {
                                print("DEBUG: Increasing or same value - updating directly")
                                // Increasing the value, update directly
                                SettingsManager.shared.maxItems = newValue
                                previousMaxItems = newValue
                            }
                        }
                     }

                     Spacer()
                 }
                 .padding(.horizontal, 4)
             }
             .padding(.horizontal)
             .padding(.vertical, 12)
             .background(Color(.windowBackgroundColor))

             Divider()

             // Clipboard items list
             if clipboardManager.getClipboardItems().isEmpty {
                 VStack(spacing: 16) {
                     Spacer()
                     Image(systemName: "clipboard")
                         .font(.system(size: 48))
                         .foregroundColor(.secondary)
                     Text("No clipboard items yet")
                         .font(.title3)
                         .foregroundColor(.secondary)
                     Text("Copy some text to see it appear here")
                         .font(.body)
                         .foregroundColor(.secondary)
                         .multilineTextAlignment(.center)
                     Spacer()
                 }
                 .padding()
             } else {
                 ScrollView {
                     VStack(spacing: 0) {
                         ForEach(clipboardManager.getClipboardItems(), id: \.id) { item in
                             ClipboardItemRow(item: item, isSelected: selectedItem == item)
                                 .onTapGesture {
                                     selectedItem = item
                                     clipboardManager.copyToClipboard(item)
                                 }
                                 .contextMenu {
                                     Button(action: {
                                         clipboardManager.copyToClipboard(item)
                                     }) {
                                         Label("Copy to Clipboard", systemImage: "doc.on.doc")
                                     }

                                     Divider()

                                     Button(action: {
                                         let pasteboard = NSPasteboard.general
                                         pasteboard.clearContents()
                                         pasteboard.setString(item.content, forType: .string)
                                     }) {
                                         Label("Copy Full Text", systemImage: "text.quote")
                                     }
                                 }
                         }
                     }
                 }
             }

             // Footer
             Divider()
             HStack {
                 Text("\(clipboardManager.getClipboardItems().count) items")
                     .font(.caption)
                     .foregroundColor(.secondary)

                 Spacer()
             }
             .padding(.horizontal)
             .padding(.vertical, 8)
             .background(Color(.windowBackgroundColor))
         }
        .frame(minWidth: 400, minHeight: 300)
        .background(Color(.windowBackgroundColor))
     }
 }

 struct ClipboardItemRow: View {
     let item: ClipboardItem
     let isSelected: Bool
     @State private var isHovered = false

     var body: some View {
         VStack(alignment: .leading, spacing: 4) {
            Text(item.content)
                .font(.system(size: 13))
                .lineLimit(1)
                .multilineTextAlignment(.leading)
                 .frame(maxWidth: .infinity, alignment: .leading)

             HStack {
                 Text(item.timestamp, style: .time)
                     .font(.system(size: 11))
                     .foregroundColor(.secondary)

                 Spacer()

                 if item.content.count > 50 {
                     Text("+\(item.content.count - 50) chars")
                         .font(.system(size: 11))
                         .foregroundColor(.secondary)
                 }
             }
         }
         .padding(.horizontal)
         .padding(.vertical, 8)
         .background(isSelected ? Color(.selectedContentBackgroundColor) : (isHovered ? Color.gray.opacity(0.1) : Color.clear))
         .contentShape(Rectangle())
         .onHover { hovering in
             isHovered = hovering
             if hovering {
                 NSCursor.pointingHand.set()
             } else {
                 NSCursor.arrow.set()
             }
         }
     }
 }

 struct ContentView_Previews: PreviewProvider {
     static var previews: some View {
         ContentView()
             .environmentObject(ObservableClipboardManager())
     }
 }
