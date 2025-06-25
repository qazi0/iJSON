//
//  InspectionView.swift
//  iJSON
//
//  Created by blakberrisigma on 25/06/2025.
//

import SwiftUI
import AppKit // For NSPasteboard

// MARK: - Helper View for Node Details Row
struct NodeDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text("\(label):")
                .fontWeight(.bold)
                .frame(width: 70, alignment: .leading) // Align labels
            Text(value)
                .font(.system(size: 13, design: .monospaced)) // Monospaced for values
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Node Details Section View
struct NodeDetailsSection: View {
    let node: JSONNode

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Details")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.accentColor)

            NodeDetailRow(label: "Key", value: node.key ?? "N/A")
            NodeDetailRow(label: "Type", value: node.type)

                            if node.type == "Object" || node.type == "Array" {
                                NodeDetailRow(label: "Children", value: "\(node.children.count)")
                            }
            
            if node.type == "Object" || node.type == "Array" {
                NodeDetailRow(label: "Expanded", value: node.isExpanded ? "Yes" : "No")
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Raw Value Section View
struct RawValueSection: View {
    let node: JSONNode
    let fontSize: CGFloat
    let displayValue: (JSONNode) -> String // Pass the function or the string directly

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Raw Value")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
                Spacer()
                Button(action: {
                    copyToPasteboard(displayValue(node))
                }) {
                    Image(systemName: "doc.on.doc.fill")
                        .font(.caption)
                    Text("Copy")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            ScrollView {
                Text(displayValue(node))
                    .font(.system(size: fontSize, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.05)) // Slightly darker for code
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                    )
            }
            .frame(maxHeight: 300) // Increased height limit for value display
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
    
    // Helper function to copy text to pasteboard
    private func copyToPasteboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

struct InspectionView: View {
    @Binding var selectedNode: JSONNode?
    let fontSize: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 0) { // Set spacing to 0 for custom control
            Text("Node Inspector")
                .font(.title2)
                .fontWeight(.bold)
                .padding([.horizontal, .top])
                .padding(.bottom, 5)
                .foregroundColor(.primary)

            Divider()
                .padding(.horizontal)

            if let node = selectedNode {
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        NodeDetailsSection(node: node)
                        RawValueSection(node: node, fontSize: fontSize, displayValue: displayValue)
                    }
                    .padding(.horizontal) // Padding for the scrollable content
                    .padding(.bottom)
                }
            } else {
                Spacer()
                Text("Select a node in the JSON tree to inspect its properties.")
                    .font(.system(size: fontSize))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            }
        }
        .frame(minWidth: 250, maxWidth: 450, alignment: .topLeading) // Adjusted width
        .background(Color.white.opacity(0.08)) // Slightly more prominent background
        .cornerRadius(12)
        .shadow(radius: 5)
        .padding(10) // Outer padding for the entire inspector view
    }

    private func displayValue(for node: JSONNode) -> String {
        let rawValue = node.rawValue
        
        if JSONSerialization.isValidJSONObject(rawValue) {
            // If the rawValue itself is a valid JSON object/array, pretty print it
            if let data = try? JSONSerialization.data(withJSONObject: rawValue, options: [.prettyPrinted, .sortedKeys]),
               let str = String(data: data, encoding: .utf8) {
                return str
            }
        }
        
        // Handle primitive types or fallback for complex types that couldn't be serialized
        if let str = rawValue as? String {
            return str
        } else if let num = rawValue as? NSNumber {
            return "\(num)"
        } else if let bool = rawValue as? Bool {
            return "\(bool)"
        } else if rawValue is NSNull {
            return "null"
        }
        
        // Fallback for any other unhandled type or if serialization failed
        return "\(rawValue)"
    }
}
