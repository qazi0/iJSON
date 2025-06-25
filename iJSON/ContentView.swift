//
//  ContentView.swift
//  iJSON
//
//  Created by blakberrisigma on 25/06/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var jsonInput: String = ""
    @State private var jsonOutput: String = "Pretty JSON" // Changed default placeholder
    @State private var fontSize: CGFloat = 14.0 // Default font size
    @State private var rootNode: JSONNode? = nil // Initialize as nil
    @State private var selectedNode: JSONNode?

    var body: some View {
        HSplitView {
            // Left Pane: JSON Input
            VStack(alignment: .leading, spacing: 0) {
                Text("JSON Input")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding([.horizontal, .top])
                    .padding(.bottom, 5)
                    .foregroundColor(.primary)

                Divider()
                    .padding(.horizontal)

                TextEditor(text: $jsonInput)
                    .font(.system(size: fontSize, design: .monospaced))
                    .lineSpacing(5)
                    .padding()
                    .frame(minWidth: 300)
                    .onChange(of: jsonInput) {
                        prettifyJSON(jsonInput)
                    }
                    .overlay(
                        Group {
                            if jsonInput.isEmpty {
                                Text("Paste JSON here...")
                                    .font(.system(size: fontSize)) // Apply font size
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 12)
                            }
                        }, alignment: .topLeading
                    )
            }
            .frame(minWidth: 300)
            .background(Color.white.opacity(0.08)) // Consistent background
            .cornerRadius(12)
            .shadow(radius: 5)
            .padding(10) // Consistent outer padding

            // Middle Pane: Prettified JSON Output (Tree View or Raw Text)
            VStack(alignment: .leading, spacing: 0) {
                Text("Pretty JSON Output") // Title for middle pane
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding([.horizontal, .top])
                    .padding(.bottom, 5)
                    .foregroundColor(.primary)

                Divider()
                    .padding(.horizontal)

                ScrollView {
                    if let node = rootNode { // Directly use the Optional JSONNode
                        JSONTreeView(node: node, fontSize: fontSize, selectedNode: $selectedNode)
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    } else {
                        Text(jsonOutput) // Fallback for invalid JSON or initial state
                            .font(.system(size: fontSize, design: .monospaced))
                            .lineSpacing(5)
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .textSelection(.enabled)
                    }
                }
            }
            .frame(minWidth: 300)
            .background(Color.white.opacity(0.08)) // Subtle background for the pane
            .cornerRadius(12)
            .shadow(radius: 5)
            .padding(10) // Outer padding for the entire middle pane

            // Right Pane: Node Inspector
            InspectionView(selectedNode: $selectedNode, fontSize: fontSize)
                .frame(minWidth: 250, idealWidth: 300, maxWidth: 400)
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: zoomIn) {
                    Label("Zoom In", systemImage: "plus.magnifyingglass")
                }
                .keyboardShortcut("+", modifiers: .command)
                
                Button(action: zoomOut) {
                    Label("Zoom Out", systemImage: "minus.magnifyingglass")
                }
                .keyboardShortcut("-", modifiers: .command)
                
                Button(action: expandAll) {
                    Label("Expand All", systemImage: "arrow.down.right.and.arrow.up.left")
                }
                Button(action: collapseAll) {
                    Label("Collapse All", systemImage: "arrow.up.left.and.arrow.down.right")
                }
                Button(action: copyOutput) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
            }
        }
    }

    private func prettifyJSON(_ input: String) {
        guard !input.isEmpty else {
            jsonOutput = "Pretty JSON" // Changed placeholder for empty input
            rootNode = nil
            selectedNode = nil
            return
        }

        if let data = input.data(using: .utf8) {
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                
                // Prettify for raw text display (if tree view fails or for copy)
                let prettyPrintedData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys])
                if let prettyPrintedString = String(data: prettyPrintedData, encoding: .utf8) {
                    jsonOutput = prettyPrintedString
                } else {
                    jsonOutput = "Error: Could not convert prettified data to string."
                }

                // Convert to JSONNode tree, passing the original string segment for ordered parsing
                rootNode = JSONNode.from(json: jsonObject, jsonStringSegment: input)
                selectedNode = nil // Clear selection on new input
                
                // Automatically expand all nodes when JSON is first entered
                expandAll()

            } catch {
                jsonOutput = "Invalid JSON: \(error.localizedDescription)"
                rootNode = nil // Clear tree on error
                selectedNode = nil
            }
        } else {
            jsonOutput = "Error: Could not convert input string to data."
            rootNode = nil
            selectedNode = nil
        }
    }

    private func zoomIn() {
        fontSize += 1.0
    }

    private func zoomOut() {
        if fontSize > 8.0 { // Prevent font size from becoming too small
            fontSize -= 1.0
        }
    }

    private func expandAll() {
        rootNode?.setExpansion(to: true)
    }

    private func collapseAll() {
        rootNode?.setExpansion(to: false)
    }

    private func copyOutput() {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        if let node = selectedNode {
            // Use rawValue for copying
            let valueToCopy = node.rawValue
            
            if JSONSerialization.isValidJSONObject(valueToCopy) {
                // If the value itself is a valid JSON object/array, pretty print it
                if let data = try? JSONSerialization.data(withJSONObject: valueToCopy, options: [.prettyPrinted, .sortedKeys]),
                   let str = String(data: data, encoding: .utf8) {
                    pasteboard.setString(str, forType: .string)
                } else {
                    pasteboard.setString("\(valueToCopy)", forType: .string) // Fallback for complex types
                }
            } else {
                // For primitive types, just convert to string
                pasteboard.setString("\(valueToCopy)", forType: .string)
            }
        } else {
            // If no node is selected, copy the entire prettified output
            pasteboard.setString(jsonOutput, forType: .string)
        }
        #endif
    }
}

#Preview {
    ContentView()
}
