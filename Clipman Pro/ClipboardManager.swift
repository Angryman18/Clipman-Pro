//
 //  ClipboardManager.swift
 //  Clipman Pro
 //
 //  Created by Shyam Mahanta on 25/12/25.
 //

 import Foundation
 import AppKit
 import Combine

 class ClipboardManager: NSObject {
     private var clipboardItems: [ClipboardItem] = []
     private var lastChangeCount: Int = 0
     private var timer: Timer?
     private let maxItems = 50 // Maximum clipboard items to store

     var onClipboardUpdate: (() -> Void)?

     override init() {
         super.init()
         startMonitoring()
     }

     deinit {
         stopMonitoring()
     }

     private func startMonitoring() {
         lastChangeCount = NSPasteboard.general.changeCount

         // Check clipboard every 0.5 seconds
         timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
             self?.checkClipboard()
         }
     }

     private func stopMonitoring() {
         timer?.invalidate()
         timer = nil
     }

     private func checkClipboard() {
         let currentChangeCount = NSPasteboard.general.changeCount

         if currentChangeCount != lastChangeCount {
             lastChangeCount = currentChangeCount

             if let clipboardContent = getClipboardContent() {
                 addClipboardItem(clipboardContent)
                 onClipboardUpdate?()
             }
         }
     }

     private func getClipboardContent() -> String? {
         guard let pasteboardString = NSPasteboard.general.string(forType: .string) else {
             return nil
         }

         // Skip if it's the same as the last item
         if let lastItem = clipboardItems.first, lastItem.content == pasteboardString {
             return nil
         }

         return pasteboardString.trimmingCharacters(in: .whitespacesAndNewlines)
     }

     private func addClipboardItem(_ content: String) {
         let newItem = ClipboardItem(content: content, timestamp: Date())

         // Remove duplicates and add to front
         var updatedItems = clipboardItems
         updatedItems.removeAll { $0.content == content }
         updatedItems.insert(newItem, at: 0)

         // Keep only the maximum number of items
         if updatedItems.count > maxItems {
             updatedItems = Array(updatedItems.prefix(maxItems))
         }

         clipboardItems = updatedItems
     }

     func getClipboardItems(limit: Int? = nil) -> [ClipboardItem] {
         if let limit = limit {
             return Array(clipboardItems.prefix(limit))
         }
         return clipboardItems
     }

     func copyToClipboard(_ item: ClipboardItem) {
         NSPasteboard.general.clearContents()
         NSPasteboard.general.setString(item.content, forType: .string)

         // Move item to front if setting is enabled
         if SettingsManager.shared.autoMoveToTop {
             if let index = clipboardItems.firstIndex(where: { $0.id == item.id }) {
                 var updatedItems = clipboardItems
                 let movedItem = updatedItems.remove(at: index)
                 updatedItems.insert(movedItem, at: 0)
                 clipboardItems = updatedItems
             }
         }
     }

     func clearClipboardHistory() {
         clipboardItems.removeAll()
         onClipboardUpdate?()
     }
 }

 // ObservableObject wrapper for ClipboardManager
 class ObservableClipboardManager: ObservableObject {
     @Published private(set) var clipboardItems: [ClipboardItem] = []

     private let clipboardManager: ClipboardManager
     private var cancellables = Set<AnyCancellable>()

     init() {
         clipboardManager = ClipboardManager()
         clipboardManager.onClipboardUpdate = { [weak self] in
             self?.updateItems()
         }
         updateItems()
     }

     private func updateItems() {
         clipboardItems = clipboardManager.getClipboardItems()
     }

     func getClipboardItems(limit: Int? = nil) -> [ClipboardItem] {
         return clipboardManager.getClipboardItems(limit: limit)
     }

     func copyToClipboard(_ item: ClipboardItem) {
         clipboardManager.copyToClipboard(item)
         // Update items after a short delay to allow the manager to process
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
             self?.updateItems()
         }
     }

     func clearClipboardHistory() {
         clipboardManager.clearClipboardHistory()
         updateItems()
     }
 }

 struct ClipboardItem: Identifiable, Equatable {
     let id = UUID()
     let content: String
     let timestamp: Date

     var displayText: String {
         let maxLength = 50
         if content.count <= maxLength {
             return content
         }
         return String(content.prefix(maxLength)) + "..."
     }
 }
