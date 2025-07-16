//
//  JSONTreeView.swift
//  iJSON
//
//  Created by blakberrisigma on 25/06/2025.
//

import SwiftUI

struct JSONTreeView: View {
    @ObservedObject var node: JSONNode
    let fontSize: CGFloat
    @Binding var selectedNode: JSONNode?
    
    // Add performance optimization for large trees
    @State private var isVisible: Bool = true
    // Virtualization for large collections
    private let maxVisibleItems = 1000 // Limit visible items for performance
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if node.isExpandable {
                DisclosureGroup(isExpanded: $node.isExpanded) {
                    // Content when expanded - use LazyVStack with proper view recycling
                    if node.isExpanded && isVisible {
                        let children = node.children
                        let isLargeCollection = children.count > maxVisibleItems
                        
                        if isLargeCollection {
                            // For very large collections, show a warning and limit items
                            VStack(alignment: .leading, spacing: 4) {
                                Text("⚠️ Large collection with \(children.count) items - showing first \(maxVisibleItems)")
                                    .font(.system(size: fontSize - 2, design: .monospaced))
                                    .foregroundColor(.orange)
                                    .padding(.leading, 20)
                                    .padding(.vertical, 2)
                                
                                LazyVStack(alignment: .leading, spacing: 0) {
                                    ForEach(0..<min(maxVisibleItems, children.count), id: \.self) { index in
                                        JSONTreeView(
                                            node: children[index], 
                                            fontSize: fontSize, 
                                            selectedNode: $selectedNode
                                        )
                                        .id("\(node.id)-\(index)") // Stable view identity
                                    }
                                }
                                .padding(.leading, 20)
                                
                                if children.count > maxVisibleItems {
                                    Text("... and \(children.count - maxVisibleItems) more items")
                                        .font(.system(size: fontSize - 2, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 20)
                                        .padding(.vertical, 2)
                                }
                            }
                        } else {
                            LazyVStack(alignment: .leading, spacing: 0) {
                                ForEach(children.indices, id: \.self) { index in
                                    if index < children.count {
                                        JSONTreeView(
                                            node: children[index], 
                                            fontSize: fontSize, 
                                            selectedNode: $selectedNode
                                        )
                                        .id("\(node.id)-\(index)") // Stable view identity
                                    }
                                }
                            }
                            .padding(.leading, 20) // Increased indentation
                        }
                    }
                } label: {
                    NodeLabel(node: node, fontSize: fontSize, isSelected: selectedNode?.id == node.id)
                        .contentShape(Rectangle()) // Make the whole row tappable
                        .onTapGesture {
                            selectedNode = node
                        }
                }
                .disclosureGroupStyle(PlainDisclosureGroupStyle())
            } else {
                NodeLabel(node: node, fontSize: fontSize, isSelected: selectedNode?.id == node.id)
                    .contentShape(Rectangle()) // Make the whole row tappable
                    .onTapGesture {
                        selectedNode = node
                    }
            }
        }
        .onAppear {
            isVisible = true
        }
        .onDisappear {
            // Optimize memory by marking as not visible
            isVisible = false
        }
    }
}

struct PlainDisclosureGroupStyle: DisclosureGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Button(action: {
                    // Remove animation for better performance with large datasets
                    configuration.isExpanded.toggle()
                }) {
                    Image(systemName: configuration.isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .rotationEffect(.degrees(configuration.isExpanded ? 0 : 0))
                }
                .buttonStyle(PlainButtonStyle())
                
                configuration.label
            }
            
            if configuration.isExpanded {
                configuration.content
            }
        }
    }
}

struct NodeLabel: View {
    @ObservedObject var node: JSONNode
    let fontSize: CGFloat
    let isSelected: Bool
    @State private var isHovering = false // For hover effect
    
    // Cache computed properties for better performance
    @State private var displayText: String = ""
    @State private var nodeColor: Color = .primary
    @State private var nodeIcon: String = ""

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) { // Align text baselines
            if let key = node.key {
                Text("\"\(key)\"")
                    .font(.system(size: fontSize, design: .monospaced))
                    .fontWeight(.semibold) // Make key bolder
                    .foregroundColor(.purple)
                Text(":")
                    .font(.system(size: fontSize, design: .monospaced))
                    .foregroundColor(.gray)
            }

            Group {
                // Use cached display properties for better performance
                if !nodeIcon.isEmpty {
                    Image(systemName: nodeIcon)
                        .font(.system(size: fontSize - 2))
                        .foregroundColor(nodeColor)
                }
                
                Text(displayText)
                    .font(.system(size: fontSize, design: .monospaced))
                    .foregroundColor(nodeColor)
                    .fixedSize(horizontal: false, vertical: true) // Allow vertical expansion for long text
                    .multilineTextAlignment(.leading) // Ensure proper text alignment
                
                // Show count for collapsed containers
                if !node.isExpanded && node.isExpandable {
                    Text("(\(node.childrenCount) items)")
                        .font(.system(size: fontSize - 3, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 3) // Slightly more vertical padding
        .background(isSelected ? Color.accentColor.opacity(0.3) : (isHovering ? Color.gray.opacity(0.1) : Color.clear)) // Stronger selection highlight
        .cornerRadius(4)
        .onHover { hover in
            isHovering = hover
        }
        .onAppear {
            updateDisplayProperties()
        }
        .onChange(of: node.isExpanded) {
            updateDisplayProperties()
        }
    }
    
    private func updateDisplayProperties() {
        // Cache the display properties to avoid recomputing on every render
        if node.rawValue is [String: Any] { // Object
            nodeIcon = node.isExpanded ? "folder.fill.badge.minus" : "folder.fill.badge.plus"
            nodeColor = .blue
            displayText = node.isExpanded ? "{" : "{...}"
        } else if node.rawValue is [Any] { // Array
            nodeIcon = node.isExpanded ? "list.bullet.rectangle.portrait.fill" : "list.bullet.rectangle.portrait"
            nodeColor = .green
            displayText = node.isExpanded ? "[" : "[...]"
        } else if let str = node.rawValue as? String {
            nodeIcon = ""
            nodeColor = .brown
            // Show complete string content - no truncation
            // Use proper text wrapping and layout to handle long strings
            displayText = "\"\(str)\""
        } else if let num = node.rawValue as? NSNumber {
            nodeIcon = ""
            nodeColor = .blue
            displayText = "\(num)"
        } else if let bool = node.rawValue as? Bool {
            nodeIcon = ""
            nodeColor = .orange
            displayText = "\(bool.description)"
        } else if node.rawValue is NSNull {
            nodeIcon = ""
            nodeColor = .red
            displayText = "null"
        } else {
            nodeIcon = ""
            nodeColor = .primary
            displayText = "unknown"
        }
    }
}
