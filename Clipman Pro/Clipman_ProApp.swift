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

         Settings {
             EmptyView()
         }
     }
 }

 class AppDelegate: NSObject, NSApplicationDelegate {
     var statusItem: NSStatusItem?
     var clipboardManager: ClipboardManager?
     var settingsWindow: NSWindow?

     func applicationDidFinishLaunching(_ notification: Notification) {
         clipboardManager = ClipboardManager()
         clipboardManager?.onClipboardUpdate = { [weak self] in
             self?.updateMenu()
         }

         // Only show menu bar icon if setting is enabled
         if SettingsManager.shared.showMenuBarIcon {
             createStatusItem()
         }
     }

     private func createStatusItem() {
         // Create menu bar item
         statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

         if let button = statusItem?.button {
             button.image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "Clipboard Manager")
             button.action = #selector(statusBarButtonClicked)
             button.target = self
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

         // Add clipboard items
         let maxItems = SettingsManager.shared.maxItems
         let items = clipboardManager?.getClipboardItems(limit: maxItems) ?? []

         if items.isEmpty {
             let emptyItem = NSMenuItem(title: "No clipboard items", action: nil, keyEquivalent: "")
             emptyItem.isEnabled = false
             menu.addItem(emptyItem)
         } else {
             for (index, item) in items.enumerated() {
                 let menuItem = NSMenuItem(title: item.displayText, action: #selector(clipboardItemClicked(_:)), keyEquivalent: "")
                 menuItem.target = self
                 menuItem.tag = index
                 menuItem.toolTip = item.content
                 menu.addItem(menuItem)
             }
         }

         menu.addItem(NSMenuItem.separator())

         // Settings
         let settingsItem = NSMenuItem(title: "Settings", action: #selector(showSettings), keyEquivalent: "")
         settingsItem.target = self
         menu.addItem(settingsItem)

         // About
         let aboutItem = NSMenuItem(title: "About", action: #selector(showAbout), keyEquivalent: "")
         aboutItem.target = self
         menu.addItem(aboutItem)

         menu.addItem(NSMenuItem.separator())

         // Hide icon option
         let hideIconItem = NSMenuItem(title: "Hide Menu Bar Icon", action: #selector(hideIcon), keyEquivalent: "")
         hideIconItem.target = self
         menu.addItem(hideIconItem)

         // Quit option
         let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
         quitItem.target = self
         menu.addItem(quitItem)
     }

     @objc func statusBarButtonClicked() {
         statusItem?.button?.performClick(nil)
     }

     @objc func clipboardItemClicked(_ sender: NSMenuItem) {
         let maxItems = SettingsManager.shared.maxItems
         let items = clipboardManager?.getClipboardItems(limit: maxItems) ?? []

         if sender.tag < items.count {
             let item = items[sender.tag]
             clipboardManager?.copyToClipboard(item)
         }
     }

     @objc func showSettings() {
         if settingsWindow == nil {
             let settingsView = SettingsView()
             let hostingController = NSHostingController(rootView: settingsView)
             hostingController.view.frame.size = CGSize(width: 400, height: 300)

             settingsWindow = NSWindow(contentViewController: hostingController)
             settingsWindow?.title = "Clipboard Manager Settings"
             settingsWindow?.styleMask = [.titled, .closable, .miniaturizable]
             settingsWindow?.center()
         }

         settingsWindow?.makeKeyAndOrderFront(nil)
         NSApp.activate(ignoringOtherApps: true)
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

     @objc func hideIcon() {
         let alert = NSAlert()
         alert.messageText = "Hide Menu Bar Icon"
         alert.informativeText = "The menu bar icon will be hidden. To show it again, relaunch the Clipboard Manager app."
         alert.alertStyle = .warning
         alert.addButton(withTitle: "Hide")
         alert.addButton(withTitle: "Cancel")

         let response = alert.runModal()
         if response == .alertFirstButtonReturn {
             SettingsManager.shared.showMenuBarIcon = false
             statusItem?.statusBar?.removeStatusItem(statusItem!)
             statusItem = nil
         }
     }

     @objc func quitApp() {
         NSApplication.shared.terminate(self)
     }
 }

 extension AppDelegate: NSMenuDelegate {
     func menuWillOpen(_ menu: NSMenu) {
         updateMenu()
     }
 }
