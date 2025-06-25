//
//  iJSONApp.swift
//  iJSON
//
//  Created by blakberrisigma on 25/06/2025.
//

import SwiftUI

@main
struct iJSONApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(replacing: .appInfo) { // Replace default About menu
                Button("About iJSON") {
                    NotificationCenter.default.post(name: .showAboutSheet, object: nil)
                }
            }
            
            CommandGroup(after: .appInfo) { // Add File menu after App Info
                Menu("File") {
                    Button("Open JSON File...") {
                        NotificationCenter.default.post(name: .openJSONFile, object: nil)
                    }
                    .keyboardShortcut("o", modifiers: .command)
                    
                    Button("Save JSON File...") {
                        NotificationCenter.default.post(name: .saveJSONFile, object: nil)
                    }
                    .keyboardShortcut("s", modifiers: .command)
                }
            }
            
            CommandGroup(after: .newItem) { // Add View menu after New Item (standard placement)
                Menu("View") {
                    Button("Zoom In") {
                        NotificationCenter.default.post(name: .zoomIn, object: nil)
                    }
                    .keyboardShortcut("+", modifiers: .command)
                    
                    Button("Zoom Out") {
                        NotificationCenter.default.post(name: .zoomOut, object: nil)
                    }
                    .keyboardShortcut("-", modifiers: .command)
                    
                    Divider()
                    
                    Button("Expand All") {
                        NotificationCenter.default.post(name: .expandAll, object: nil)
                    }
                    Button("Collapse All") {
                        NotificationCenter.default.post(name: .collapseAll, object: nil)
                    }
                }
            }
            
        }
    }
}
