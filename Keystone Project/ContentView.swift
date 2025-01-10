//
//  ContentView.swift
//  Keystone Project
//
//  Created by Daniel Eybelman on 10/25/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var dataController = DataController()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NoteListView()
                .environmentObject(dataController)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Notes")
                }
                .tag(0)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(1)
        }
    }
}

#Preview {
    ContentView()
}
