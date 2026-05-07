//
//  MainTabView.swift
//  ColorPalleteSCH
//
//  Created by seyedeh sepideh sadeghi far on 07/05/26.
//


import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    
    enum Tab {
        case home
        case discover
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Palettes", systemImage: selectedTab == .home ? "square.grid.2x2.fill" : "square.grid.2x2")
                }
                .tag(Tab.home)
            
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: selectedTab == .discover ? "sparkle.magnifyingglass" : "magnifyingglass")
                }
                .tag(Tab.discover)
        }
        .tint(Color(hex: "#1A1A1A"))
    }
}
