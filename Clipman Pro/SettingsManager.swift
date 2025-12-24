//
 //  SettingsManager.swift
 //  Clipman Pro
 //
 //  Created by Shyam Mahanta on 25/12/25.
 //

 import Foundation

 class SettingsManager {
     static let shared = SettingsManager()

     private let defaults = UserDefaults.standard

     // Settings keys
     private let maxItemsKey = "maxItems"
     private let autoMoveToTopKey = "autoMoveToTop"
     private let showMenuBarIconKey = "showMenuBarIcon"

     private init() {
         // Set default values
         if defaults.object(forKey: maxItemsKey) == nil {
             defaults.set(10, forKey: maxItemsKey)
         }
         if defaults.object(forKey: autoMoveToTopKey) == nil {
             defaults.set(true, forKey: autoMoveToTopKey)
         }
         if defaults.object(forKey: showMenuBarIconKey) == nil {
             defaults.set(true, forKey: showMenuBarIconKey)
         }
     }

     var maxItems: Int {
         get { defaults.integer(forKey: maxItemsKey) }
         set { defaults.set(newValue, forKey: maxItemsKey) }
     }

     var autoMoveToTop: Bool {
         get { defaults.bool(forKey: autoMoveToTopKey) }
         set { defaults.set(newValue, forKey: autoMoveToTopKey) }
     }

     var showMenuBarIcon: Bool {
         get { defaults.bool(forKey: showMenuBarIconKey) }
         set { defaults.set(newValue, forKey: showMenuBarIconKey) }
     }
 }
