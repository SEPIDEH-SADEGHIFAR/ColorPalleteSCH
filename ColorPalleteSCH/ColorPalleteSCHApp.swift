//
//  ColorPalleteSCHApp.swift
//  ColorPalleteSCH
//
//  Created by seyedeh sepideh sadeghi far on 10/02/26.
//

import SwiftUI
import SwiftData

@main
  struct AWBYApp: App {
      @AppStorage("hasSeenOnboarding") var onboarded = false
       var body: some Scene {
          WindowGroup {
               if onboarded {
                  MainTabView()
                      .modelContainer(for: [SavedPalette.self, SavedColor.self])
             } else {
                  OnboardingView()
             }
           }
       }
   }
