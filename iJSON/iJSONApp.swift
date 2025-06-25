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
            
            CommandGroup(replacing: .newItem) { // Replace default File menu
                Button("Open JSON File...") {
                    NotificationCenter.default.post(name: .openJSONFile, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Button("Save JSON File...") {
                    NotificationCenter.default.post(name: .saveJSONFile, object: nil)
                }
                .keyboardShortcut("s", modifiers: .command)
            }
            
            CommandGroup(after: .pasteboard) { // Add to Edit menu
                Button("Copy JSON Output") {
                    NotificationCenter.default.post(name: .copyOutput, object: nil)
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
            }
            
            CommandGroup(after: .windowArrangement) { // Add View menu after Window Arrangement (standard placement)
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
                
                Divider()
                
                Button("Toggle Input Pane") {
                    NotificationCenter.default.post(name: .toggleLeftSidebar, object: nil)
                }
                .keyboardShortcut("1", modifiers: [.command, .option])
                
                Button("Toggle Inspector Pane") {
                    NotificationCenter.default.post(name: .toggleRightSidebar, object: nil)
                }
                .keyboardShortcut("2", modifiers: [.command, .option])
            }
        }
    }
}
