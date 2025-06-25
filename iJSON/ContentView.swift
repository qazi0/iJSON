//
//  ContentView.swift
//  iJSON
//
//  Created by blakberrisigma on 25/06/2025.
//

import SwiftUI
import AppKit // Import AppKit for NSOpenPanel and NSSavePanel

struct ContentView: View {
    @State private var jsonInput: String = ""
    @State private var jsonOutput: String = "Pretty JSON" // Changed default placeholder
    @State private var fontSize: CGFloat = 14.0 // Default font size
    @State private var rootNode: JSONNode? = nil // Initialize as nil
    @State private var selectedNode: JSONNode?
    @State private var showCopySuccessToast: Bool = false // State for toast notification
    @State private var showAboutSheet: Bool = false // State for showing About sheet

    var body: some View {
        VStack(spacing: 0) { // Use VStack for overall layout: App Name, Nav Bar, HSplitView
            // App Name (Thicker Nav Bar)
            HStack {
                Text("iJSON")
                    .font(.system(size: 36, weight: .heavy, design: .rounded)) // Larger, heavier font
                    .foregroundColor(.accentColor)
                    .padding(.leading, 20) // Padding from left edge
                Spacer()
            }
            .frame(height: 60) // Thicker bar
            .background(Color.white.opacity(0.05)) // Subtle background
            .shadow(radius: 2) // Slight shadow for separation

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
                    HStack { // HStack for title and copy button
                        Text("Pretty JSON Output") // Title for middle pane
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Spacer() // Pushes copy button to the right
                        Button(action: copyOutput) {
                            Label("Copy Output", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.borderedProminent) // Make it look like a button
                    }
                    .padding([.horizontal, .top])
                    .padding(.bottom, 5)

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
            .sheet(isPresented: $showAboutSheet) {
                AboutView()
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
            .onReceive(NotificationCenter.default.publisher(for: .openJSONFile)) { _ in
                openJSONFile()
            }
            .onReceive(NotificationCenter.default.publisher(for: .saveJSONFile)) { _ in
                saveJSONFile()
            }
            .onReceive(NotificationCenter.default.publisher(for: .zoomIn)) { _ in
                zoomIn()
            }
            .onReceive(NotificationCenter.default.publisher(for: .zoomOut)) { _ in
                zoomOut()
            }
            .onReceive(NotificationCenter.default.publisher(for: .expandAll)) { _ in
                expandAll()
            }
            .onReceive(NotificationCenter.default.publisher(for: .collapseAll)) { _ in
                collapseAll()
            }
            .onReceive(NotificationCenter.default.publisher(for: .showAboutSheet)) { _ in
                showAboutSheet = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .copyOutput)) { _ in
                copyOutput()
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
                // Convert to JSONNode tree, passing the original string segment for ordered parsing
                rootNode = JSONNode.from(json: jsonObject, jsonStringSegment: input)
                selectedNode = nil // Clear selection on new input
                
                // Populate jsonOutput using the order-preserving toPrettifiedString method
                if let node = rootNode {
                    // Expand all nodes initially when JSON is first entered
                    node.expandAllInitially()
                    jsonOutput = node.toPrettifiedString()
                } else {
                    jsonOutput = "Error: Could not create JSON tree from input."
                }

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
    
    private func openJSONFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                do {
                    let data = try Data(contentsOf: url)
                    if let jsonString = String(data: data, encoding: .utf8) {
                        jsonInput = jsonString
                    }
                } catch {
                    jsonOutput = "Error reading file: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func saveJSONFile() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "output.json"
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                do {
                    try jsonOutput.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    jsonOutput = "Error saving file: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.accentColor)

            Text("About iJSON")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Version: 1.0.0")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("iJSON is a macOS application designed to prettify, inspect, and manipulate JSON data with ease. It provides a clear tree view, a powerful inspector, and robust parsing capabilities.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 10) {
                Text("Creator: Siraj")
                    .font(.subheadline)
                
                HStack {
                    Text("GitHub Repository:")
                        .font(.subheadline)
                    Link("blakberrisigma/iJSON", destination: URL(string: "https://github.com/blakberrisigma/iJSON")!)
                        .font(.subheadline)
                }
            }
            .padding(.horizontal)

            Button("Dismiss") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(30)
        .frame(width: 400, height: 500)
    }
}

#Preview {
    ContentView()
}
