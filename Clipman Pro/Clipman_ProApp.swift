//
 //  Clipman_ProApp.swift
 //  Clipman Pro
 //
 //  Created by Shyam Mahanta on 25/12/25.
 //

 import SwiftUI
 import AppKit

 @main
 struct Clipman_ProApp: App {
     @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
     @StateObject private var clipboardManager = ObservableClipboardManager()

     var body: some Scene {
         WindowGroup {
             ContentView()
                 .environmentObject(clipboardManager)
         }
         .windowStyle(.titleBar)
         .windowToolbarStyle(.unified)
     }
 }

class ClipboardMenuItemView: NSView {
    private let item: ClipboardItem
    private let target: AnyObject

    private let textField: NSTextField
    private let pinButton: NSButton
    private let deleteButton: NSButton

    private let pinImage: NSImage
    private let unpinImage: NSImage
    private let deleteImage: NSImage

    init(item: ClipboardItem, target: AnyObject) {
        self.item = item
        self.target = target

        // Create images
        self.pinImage = NSImage(systemSymbolName: "pin.fill", accessibilityDescription: "Pin")!
        self.unpinImage = NSImage(systemSymbolName: "pin.slash.fill", accessibilityDescription: "Unpin")!
        self.deleteImage = NSImage(systemSymbolName: "trash", accessibilityDescription: "Delete")!

        // Create text field
        self.textField = NSTextField()
        self.textField.isEditable = false
        self.textField.isBordered = false
        self.textField.drawsBackground = false
        self.textField.isSelectable = false
        self.textField.stringValue = item.displayText
        self.textField.font = NSFont.systemFont(ofSize: 13)
        self.textField.textColor = .labelColor

        // Create buttons
        self.pinButton = NSButton(image: item.isPinned ? unpinImage : pinImage, target: target, action: #selector(AppDelegate.pinUnpinItem(_:)))
        self.pinButton.imageScaling = .scaleProportionallyUpOrDown
        self.pinButton.isBordered = false
        self.pinButton.bezelStyle = .regularSquare
        self.pinButton.cell?.representedObject = item
        self.pinButton.toolTip = item.isPinned ? "Unpin" : "Pin"

        self.deleteButton = NSButton(image: deleteImage, target: target, action: #selector(AppDelegate.deleteItem(_:)))
        self.deleteButton.imageScaling = .scaleProportionallyUpOrDown
        self.deleteButton.isBordered = false
        self.deleteButton.bezelStyle = .regularSquare
        self.deleteButton.cell?.representedObject = item
        self.deleteButton.toolTip = "Delete"

        super.init(frame: .zero)

        addSubview(textField)
        addSubview(pinButton)
        addSubview(deleteButton)

        // Set initial frame size
        frame = NSRect(x: 0, y: 0, width: 400, height: 24)

        // Manual layout
        layoutSubviews()
        setupTrackingArea()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutSubviews() {
        let bounds = self.bounds
        let buttonWidth: CGFloat = 16
        let buttonHeight: CGFloat = 16
        let margin: CGFloat = 16
        let buttonSpacing: CGFloat = 4

        // Position delete button (rightmost)
        deleteButton.frame = NSRect(
            x: bounds.width - margin - buttonWidth,
            y: (bounds.height - buttonHeight) / 2,
            width: buttonWidth,
            height: buttonHeight
        )

        // Position pin button (to the left of delete button)
        pinButton.frame = NSRect(
            x: deleteButton.frame.minX - buttonSpacing - buttonWidth,
            y: (bounds.height - buttonHeight) / 2,
            width: buttonWidth,
            height: buttonHeight
        )

        // Position text field (fills remaining space)
        let textX = margin
        let textWidth = pinButton.frame.minX - margin - 8
        textField.frame = NSRect(
            x: textX,
            y: (bounds.height - 16) / 2,
            width: textWidth,
            height: 16
        )
    }

    private func setupTrackingArea() {
        let trackingArea = NSTrackingArea(rect: bounds,
                                        options: [.activeInActiveApp, .mouseEnteredAndExited, .inVisibleRect],
                                        owner: self,
                                        userInfo: nil)
        addTrackingArea(trackingArea)
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        updateBackgroundColor(isHovered: true)
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        updateBackgroundColor(isHovered: false)
    }

    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)

        // Check if click is on text area (left of pin button)
        if location.x < pinButton.frame.minX {
            // Trigger copy to clipboard
            _ = target.perform(#selector(AppDelegate.clipboardItemClicked(_:)),
                             with: item)
            return
        }

        // Let the buttons handle their own clicks
        super.mouseDown(with: event)
    }

    private func updateBackgroundColor(isHovered: Bool) {
        wantsLayer = true
        layer?.backgroundColor = isHovered ?
            NSColor.selectedMenuItemColor.cgColor :
            NSColor.clear.cgColor
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach { removeTrackingArea($0) }
        setupTrackingArea()
    }

    override var intrinsicContentSize: NSSize {
        return NSSize(width: 400, height: 24)
    }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        layoutSubviews()
        // Update tracking area when view resizes
        updateTrackingAreas()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        // Ensure tracking area is set up when view is added to window
        updateTrackingAreas()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
     var statusItem: NSStatusItem?
     var clipboardManager: ClipboardManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        clipboardManager = ClipboardManager()
        clipboardManager?.onClipboardUpdate = { [weak self] in
            DispatchQueue.main.async {
                self?.updateMenu()
            }
        }

        // Always show menu bar icon
        createStatusItem()
    }

     func createStatusItem() {
        // Prevent creating multiple status items (which can orphan an old one and make it impossible to remove).
        guard statusItem == nil else { return }

         // Create menu bar item
         statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

         if let button = statusItem?.button {
             button.image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "Clipboard Manager")
            // When a menu is assigned, AppKit will show it on click. Avoid wiring an action that can recurse.
            button.action = nil
            button.target = nil
         }

         setupMenu()
     }

     func setupMenu() {
         let menu = NSMenu()
         menu.delegate = self
         statusItem?.menu = menu
         updateMenu()
     }

    func updateMenu() {
        guard let menu = statusItem?.menu else { return }

        // Clear existing items
        menu.removeAllItems()

        // Add clipboard items (pinned items first)
        let maxItems = SettingsManager.shared.maxItems
        let allItems = clipboardManager?.getClipboardItems(limit: maxItems) ?? []
        let items = allItems.sorted { (item1, item2) -> Bool in
            if item1.isPinned && !item2.isPinned {
                return true
            } else if !item1.isPinned && item2.isPinned {
                return false
            } else {
                // Both pinned or both unpinned - maintain original order
                return allItems.firstIndex(of: item1)! < allItems.firstIndex(of: item2)!
            }
        }

        if items.isEmpty {
            let emptyItem = NSMenuItem(title: "No clipboard items", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for item in items {
                let customView = ClipboardMenuItemView(item: item, target: self)
                let menuItem = NSMenuItem()
                menuItem.view = customView
                menuItem.isEnabled = true
                menu.addItem(menuItem)
            }
        }

        menu.addItem(NSMenuItem.separator())

        // Clear All
        let clearAllItem = NSMenuItem(title: "Clear All", action: #selector(clearAll), keyEquivalent: "")
        clearAllItem.target = self
        menu.addItem(clearAllItem)

        // About
        let aboutItem = NSMenuItem(title: "About", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        // Quit option
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

     @objc func clipboardItemClicked(_ sender: Any?) {
         var item: ClipboardItem?

         if let clipboardItem = sender as? ClipboardItem {
             item = clipboardItem
         } else if let menuItem = sender as? NSMenuItem {
             // Fallback for any legacy menu items
             if let tag = menuItem.tag as Int? {
                 let maxItems = SettingsManager.shared.maxItems
                 let items = clipboardManager?.getClipboardItems(limit: maxItems) ?? []
                 if tag < items.count {
                     item = items[tag]
                 }
             }
         }

         guard let item = item else { return }

         clipboardManager?.copyToClipboard(item)
         // Close the menu after copying
         statusItem?.menu?.cancelTracking()
     }

     @objc func pinUnpinItem(_ sender: NSButton) {
         if let item = sender.cell?.representedObject as? ClipboardItem {
             clipboardManager?.togglePin(for: item)
             // Update menu after pin/unpin
             updateMenu()
         }
     }

     @objc func deleteItem(_ sender: NSButton) {
         guard let item = sender.cell?.representedObject as? ClipboardItem else { return }

         if item.isPinned {
             // Show confirmation for pinned items
             let alert = NSAlert()
             alert.messageText = "Delete Pinned Item"
             alert.informativeText = "This item is pinned. Are you sure you want to delete it?"
             alert.alertStyle = .warning
             alert.addButton(withTitle: "Delete")
             alert.addButton(withTitle: "Cancel")

             let response = alert.runModal()
             if response == .alertFirstButtonReturn {
                 clipboardManager?.deleteItem(item)
                 // Update menu after deletion
                 updateMenu()
             }
         } else {
             // Delete unpinned items without confirmation
             clipboardManager?.deleteItem(item)
             // Update menu after deletion
             updateMenu()
         }
     }

     @objc func clearAll() {
         let alert = NSAlert()
         alert.messageText = "Clear All Items"
         alert.informativeText = "Are you sure you want to delete all clipboard items? This action cannot be undone."
         alert.alertStyle = .warning
         alert.addButton(withTitle: "Clear All")
         alert.addButton(withTitle: "Cancel")

         let response = alert.runModal()
         if response == .alertFirstButtonReturn {
             clipboardManager?.clearClipboardHistory()
         }
     }

     @objc func showAbout() {
         let alert = NSAlert()
         alert.messageText = "Clipboard Manager"
         alert.informativeText = """
         A simple clipboard manager for macOS.

         Features:
         • Store multiple copied texts
         • Quick access from menu bar
         • Customizable number of items
         • Auto-move copied items to top

         Version 1.0
         """
         alert.alertStyle = .informational
         alert.addButton(withTitle: "OK")
         alert.runModal()
     }

    @objc func quitApp() {
        NSApplication.shared.terminate(self)
    }
}

 extension AppDelegate: NSMenuDelegate {
     func menuWillOpen(_ menu: NSMenu) {
         DispatchQueue.main.async { [weak self] in
             self?.updateMenu()
         }
     }
 }
    

