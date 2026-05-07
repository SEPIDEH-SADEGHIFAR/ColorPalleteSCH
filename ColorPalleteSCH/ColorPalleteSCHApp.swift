//
//  ColorPalleteSCHApp.swift
//  ColorPalleteSCH
//
//  Created by seyedeh sepideh sadeghi far on 10/02/26.
//

import SwiftUI
import SwiftData

@main
struct ColorPalleteSCHApp: App {
    var body: some Scene {
        WindowGroup {
           
            MainTabView()
        }
        .modelContainer(for: SavedPalette.self)
    }
}
