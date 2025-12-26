//
 //  ContentView.swift
 //  Clipman Pro
 //
 //  Created by Shyam Mahanta on 25/12/25.
 //

 import SwiftUI

struct ContentView: View {
    @EnvironmentObject var clipboardManager: ObservableClipboardManager
    @State private var maxItems: Int = 0
    @State private var previousMaxItems: Int = 0

    init() {
        let currentMaxItems = SettingsManager.shared.maxItems
        _maxItems = State(initialValue: currentMaxItems)
        _previousMaxItems = State(initialValue: currentMaxItems)
    }

     var body: some View {
         VStack(spacing: 12) {
             Text("Clipman Pro")
                 .font(.title)
                 .fontWeight(.bold)

             VStack(spacing: 8) {
                 Text("Max items:")
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
         }
         .frame(maxWidth: .infinity, maxHeight: .infinity)
     }
 }

 struct ContentView_Previews: PreviewProvider {
     static var previews: some View {
         ContentView()
             .environmentObject(ObservableClipboardManager())
     }
 }
