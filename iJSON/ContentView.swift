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
    @State private var showCopySuccessToast: Bool = false // State for toast notification

    var body: some View {
        HSplitView {
            // Left Pane: JSON Input
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) { // Use HStack for title and button, align center
                    Text("JSON Input")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Spacer()
                    Button(action: clearInput) { // Clear button
                        Label("Clear", systemImage: "xmark.circle.fill")
                            .font(.body) // Make button text slightly larger
                    }
                    .buttonStyle(.borderedProminent)
                    // Removed .controlSize(.small) to make it larger
                }
                .padding([.horizontal, .top])
                .padding(.bottom, 5)
                .frame(height: 40) // Fixed height for the title/button row

                Divider()
                    .padding(.horizontal)

                ZStack(alignment: .topLeading) { // ZStack for placeholder
                    TextEditor(text: $jsonInput)
                        .font(.system(size: fontSize, design: .monospaced))
                        .lineSpacing(5)
                        .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)) // Increased leading padding
                        .onChange(of: jsonInput) {
                            prettifyJSON(jsonInput)
                        }
                        .background(jsonInput.isEmpty ? Color.clear : Color.white.opacity(0.01)) // Make background clear when empty
                    
                    if jsonInput.isEmpty {
                        Text("Paste JSON here...")
                            .font(.system(size: fontSize, design: .monospaced))
                            .foregroundColor(.gray)
                            .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)) // Increased leading padding
                    }
                }
                .frame(minWidth: 300) // Apply frame to ZStack
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
        .overlay(
            Group {
                if showCopySuccessToast {
                    Text("Copied successfully!")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.green.opacity(0.8))
                        .cornerRadius(8)
                        .transition(.opacity) // Smooth fade in/out
                }
            }
            .animation(.easeOut(duration: 0.3), value: showCopySuccessToast)
            , alignment: .bottom // Position at the bottom
        )
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
                // Convert to JSONNode tree, passing the original string segment for ordered parsing
                rootNode = JSONNode.from(json: jsonObject, jsonStringSegment: input)
                selectedNode = nil // Clear selection on new input
                
                // Populate jsonOutput using the order-preserving toPrettifiedString method
                if let node = rootNode {
                    jsonOutput = node.toPrettifiedString()
                } else {
                    jsonOutput = "Error: Could not create JSON tree from input."
                }
                
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
        
        // Always copy the prettified and formatted JSON output string
        pasteboard.setString(jsonOutput, forType: .string)
        
        // Show toast notification
        showCopySuccessToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // Hide after 2 seconds
            showCopySuccessToast = false
        }
        #endif
    }
    
    private func clearInput() {
        jsonInput = ""
        jsonOutput = "Pretty JSON" // Reset to default placeholder
        rootNode = nil
        selectedNode = nil
    }
}

#Preview {
    ContentView()
}
