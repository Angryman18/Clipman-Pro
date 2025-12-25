//
 //  SettingsManager.swift
 //  Clipman Pro
 //
 //  Created by Shyam Mahanta on 25/12/25.
 //

import Foundation
import Combine
import AppKit

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

     private let defaults = UserDefaults.standard

     // Settings keys
     private let maxItemsKey = "maxItems"
     private let autoMoveToTopKey = "autoMoveToTop"

    private init() {
        // Set default values
        if defaults.object(forKey: maxItemsKey) == nil {
            defaults.set(50, forKey: maxItemsKey)
        }
        if defaults.object(forKey: autoMoveToTopKey) == nil {
            defaults.set(true, forKey: autoMoveToTopKey)
        }

        // Initialize published properties
        self.maxItems = defaults.integer(forKey: maxItemsKey)
        self.autoMoveToTop = defaults.bool(forKey: autoMoveToTopKey)
    }

    @Published var maxItems: Int {
        didSet {
            defaults.set(maxItems, forKey: maxItemsKey)
        }
    }

    @Published var autoMoveToTop: Bool {
        didSet {
            defaults.set(autoMoveToTop, forKey: autoMoveToTopKey)
        }
    }

 }
