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

     var body: some View {
         VStack(spacing: 0) {
             // Header
             HStack {
                 Text("Clipboard Manager")
                     .font(.title2)
                     .fontWeight(.semibold)

                 Spacer()

                 Button(action: {
                     clipboardManager.clearClipboardHistory()
                 }) {
                     Image(systemName: "trash")
                         .foregroundColor(.red)
                 }
                 .buttonStyle(.plain)
                 .help("Clear clipboard history")

                 Button(action: {
                     NSApp.keyWindow?.close()
                 }) {
                     Image(systemName: "xmark")
                         .foregroundColor(.secondary)
                 }
                 .buttonStyle(.plain)
                 .help("Close window")
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

             // Footer with settings
             Divider()
             HStack {
                 Text("\(clipboardManager.getClipboardItems().count) items")
                     .font(.caption)
                     .foregroundColor(.secondary)

                 Spacer()

                 Button("Settings") {
                     if let appDelegate = NSApp.delegate as? AppDelegate {
                         appDelegate.showSettings()
                     }
                 }
                 .buttonStyle(.plain)
                 .font(.caption)
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

     var body: some View {
         VStack(alignment: .leading, spacing: 4) {
             Text(item.content)
                 .font(.system(size: 13))
                 .lineLimit(2)
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
         .background(isSelected ? Color(.selectedContentBackgroundColor) : Color.clear)
         .contentShape(Rectangle())
     }
 }

 struct ContentView_Previews: PreviewProvider {
     static var previews: some View {
         ContentView()
             .environmentObject(ObservableClipboardManager())
     }
 }
