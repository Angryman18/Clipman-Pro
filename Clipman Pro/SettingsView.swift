//
 //  SettingsView.swift
 //  Clipman Pro
 //
 //  Created by Shyam Mahanta on 25/12/25.
 //

 import SwiftUI

 struct SettingsView: View {
     @State private var maxItems: String = String(SettingsManager.shared.maxItems)
     @State private var autoMoveToTop: Bool = SettingsManager.shared.autoMoveToTop

     var body: some View {
         VStack(alignment: .leading, spacing: 20) {
             Text("Clipboard Manager Settings")
                 .font(.title2)
                 .padding(.bottom, 10)

             VStack(alignment: .leading, spacing: 10) {
                 Text("Maximum clipboard items to show:")
                     .font(.headline)

                 TextField("Number of items", text: $maxItems)
                     .textFieldStyle(RoundedBorderTextFieldStyle())
                     .frame(width: 100)
                     .onChange(of: maxItems) { newValue in
                         if let intValue = Int(newValue), intValue > 0 && intValue <= 100 {
                             SettingsManager.shared.maxItems = intValue
                         } else if newValue.isEmpty {
                             // Allow empty field temporarily
                         } else {
                             // Reset to valid value
                             maxItems = String(SettingsManager.shared.maxItems)
                         }
                     }
             }

             VStack(alignment: .leading, spacing: 10) {
                 Text("Behavior:")
                     .font(.headline)

                 Toggle("Auto-move copied items to top", isOn: $autoMoveToTop)
                     .onChange(of: autoMoveToTop) { newValue in
                         SettingsManager.shared.autoMoveToTop = newValue
                     }
             }

             Spacer()

             HStack {
                 Spacer()
                 Button("Close") {
                     NSApp.keyWindow?.close()
                 }
                 .keyboardShortcut(.escape)
             }
         }
         .padding(20)
         .frame(minWidth: 350, minHeight: 250)
     }
 }

 struct SettingsView_Previews: PreviewProvider {
     static var previews: some View {
         SettingsView()
     }
 }
