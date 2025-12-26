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
    private let defaults = UserDefaults.standard
    private let clipboardItemsKey = "clipboardItems"

    var onClipboardUpdate: (() -> Void)?

    override init() {
        super.init()
        loadClipboardItems()
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

    private func saveClipboardItems() {
        do {
            let data = try JSONEncoder().encode(clipboardItems)
            defaults.set(data, forKey: clipboardItemsKey)
        } catch {
            print("Failed to save clipboard items: \(error)")
        }
    }

    private func loadClipboardItems() {
        guard let data = defaults.data(forKey: clipboardItemsKey) else {
            return
        }

        do {
            clipboardItems = try JSONDecoder().decode([ClipboardItem].self, from: data)
        } catch {
            print("Failed to load clipboard items: \(error)")
            // Clear corrupted data
            defaults.removeObject(forKey: clipboardItemsKey)
        }
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
        let maxItems = SettingsManager.shared.maxItems
        if updatedItems.count > maxItems {
            updatedItems = Array(updatedItems.prefix(maxItems))
        }

        clipboardItems = updatedItems
        saveClipboardItems()
    }

     func getClipboardItems(limit: Int? = nil) -> [ClipboardItem] {
         if let limit = limit {
             return Array(clipboardItems.prefix(limit))
         }
         return clipboardItems
     }

     func getStoredItemsCount() -> Int {
         return clipboardItems.count
     }

    func copyToClipboard(_ item: ClipboardItem) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.content, forType: .string)

        if let index = clipboardItems.firstIndex(where: { $0.id == item.id }) {
            if item.isPinned {
                // For pinned items, always move to top when copied
                var updatedItems = clipboardItems
                let movedItem = updatedItems.remove(at: index)
                updatedItems.insert(movedItem, at: 0)
                clipboardItems = updatedItems
                saveClipboardItems()
            } else if SettingsManager.shared.autoMoveToTop {
                // For unpinned items, follow the auto move to top setting
                var updatedItems = clipboardItems
                let movedItem = updatedItems.remove(at: index)
                updatedItems.insert(movedItem, at: 0)
                clipboardItems = updatedItems
                saveClipboardItems()
            }
        }
    }

    func clearClipboardHistory() {
        clipboardItems.removeAll()
        saveClipboardItems()
        onClipboardUpdate?()
    }

    func truncateItems(to count: Int) {
        if clipboardItems.count > count {
            clipboardItems = Array(clipboardItems.prefix(count))
            saveClipboardItems()
            onClipboardUpdate?()
        }
    }

    func togglePin(for item: ClipboardItem) {
        if let index = clipboardItems.firstIndex(where: { $0.id == item.id }) {
            let wasPinned = clipboardItems[index].isPinned
            clipboardItems[index].isPinned.toggle()

            if !wasPinned { // Item is now being pinned
                // Move the newly pinned item after the last pinned item
                let itemToMove = clipboardItems.remove(at: index)

                // Find the index of the last pinned item
                var lastPinnedIndex = -1
                for i in 0..<clipboardItems.count {
                    if clipboardItems[i].isPinned {
                        lastPinnedIndex = i
                    }
                }

                // Insert after the last pinned item (or at beginning if no pinned items)
                let insertIndex = lastPinnedIndex + 1
                clipboardItems.insert(itemToMove, at: insertIndex)
            }
            // If unpinning, leave it in current position

            saveClipboardItems()
            onClipboardUpdate?()
        }
    }

    func deleteItem(_ item: ClipboardItem) {
        clipboardItems.removeAll { $0.id == item.id }
        saveClipboardItems()
        onClipboardUpdate?()
    }

    func getPinnedItems() -> [ClipboardItem] {
        return clipboardItems.filter { $0.isPinned }
    }

    func getUnpinnedItems() -> [ClipboardItem] {
        return clipboardItems.filter { !$0.isPinned }
    }
 }

 // ObservableObject wrapper for ClipboardManager
 class ObservableClipboardManager: ObservableObject {
     @Published private(set) var clipboardItems: [ClipboardItem] = []

     let clipboardManager: ClipboardManager
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
        let effectiveLimit = limit ?? SettingsManager.shared.maxItems
        return clipboardManager.getClipboardItems(limit: effectiveLimit)
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

     func truncateItems(to count: Int) {
         clipboardManager.truncateItems(to: count)
         updateItems()
     }

     func getStoredItemsCount() -> Int {
         return clipboardManager.getStoredItemsCount()
     }

     func togglePin(for item: ClipboardItem) {
         clipboardManager.togglePin(for: item)
         updateItems()
     }

     func deleteItem(_ item: ClipboardItem) {
         clipboardManager.deleteItem(item)
         updateItems()
     }

     func getPinnedItems() -> [ClipboardItem] {
         return clipboardManager.getPinnedItems()
     }

     func getUnpinnedItems() -> [ClipboardItem] {
         return clipboardManager.getUnpinnedItems()
     }
 }

struct ClipboardItem: Identifiable, Equatable, Codable {
    let id: UUID
    let content: String
    let timestamp: Date
    var isPinned: Bool

    init(content: String, timestamp: Date = Date(), isPinned: Bool = false) {
        self.id = UUID()
        self.content = content
        self.timestamp = timestamp
        self.isPinned = isPinned
    }

    // Custom decoding to handle migration from older versions without isPinned
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
    }

    var displayText: String {
        let maxLength = 50
        if content.count <= maxLength {
            return content
        }
        return String(content.prefix(maxLength)) + "..."
    }
}
