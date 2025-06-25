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
    @State private var isHovering = false // For hover effect

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if node.isExpandable {
                DisclosureGroup(isExpanded: $node.isExpanded) {
                    // Content when expanded
                    if node.isExpanded {
                        Group {
                            ForEach(node.children) { childNode in
                                JSONTreeView(node: childNode, fontSize: fontSize, selectedNode: $selectedNode)
                            }
                        }
                        .padding(.leading, 20) // Increased indentation
                    }
                } label: {
                    NodeLabel(node: node, fontSize: fontSize, isSelected: selectedNode?.id == node.id)
                        .contentShape(Rectangle()) // Make the whole row tappable
                        .onTapGesture {
                            selectedNode = node
                            // Toggle expansion only if it's an object or array
                            if node.isExpandable {
                                node.isExpanded.toggle()
                            }
                        }
                        .background(isHovering ? Color.gray.opacity(0.1) : Color.clear) // Hover effect
                        .onHover { hover in
                            isHovering = hover
                        }
                }
            } else {
                NodeLabel(node: node, fontSize: fontSize, isSelected: selectedNode?.id == node.id)
                    .contentShape(Rectangle()) // Make the whole row tappable
                    .onTapGesture {
                        selectedNode = node
                    }
                    .background(isHovering ? Color.gray.opacity(0.1) : Color.clear) // Hover effect
                    .onHover { hover in
                        isHovering = hover
                    }
            }
        }
    }
}

struct NodeLabel: View {
    @ObservedObject var node: JSONNode
    let fontSize: CGFloat
    let isSelected: Bool

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
                // Display logic based on node.rawValue
                if node.rawValue is [String: Any] { // Object
                    Image(systemName: node.isExpanded ? "folder.fill.badge.minus" : "folder.fill.badge.plus") // Icon for object
                        .font(.system(size: fontSize - 2))
                        .foregroundColor(.blue)
                    Text(node.isExpanded ? "{" : "{...}")
                        .font(.system(size: fontSize, design: .monospaced))
                        .foregroundColor(.primary)
                    if !node.isExpanded {
                        Text("(\(node.children.count) items)")
                            .font(.system(size: fontSize - 3, design: .monospaced)) // Smaller font for count
                            .foregroundColor(.secondary) // More subtle color
                    }
                } else if node.rawValue is [Any] { // Array
                    Image(systemName: node.isExpanded ? "list.bullet.rectangle.portrait.fill" : "list.bullet.rectangle.portrait") // Icon for array
                        .font(.system(size: fontSize - 2))
                        .foregroundColor(.green)
                    Text(node.isExpanded ? "[" : "[...]")
                        .font(.system(size: fontSize, design: .monospaced))
                        .foregroundColor(.primary)
                    if !node.isExpanded {
                        Text("(\(node.children.count) items)")
                            .font(.system(size: fontSize - 3, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                } else if let str = node.rawValue as? String {
                    Text("\"\(str)\"")
                        .font(.system(size: fontSize, design: .monospaced))
                        .foregroundColor(.brown) // Changed string color
                } else if let num = node.rawValue as? NSNumber {
                    Text("\(num)")
                        .font(.system(size: fontSize, design: .monospaced))
                        .foregroundColor(.blue)
                } else if let bool = node.rawValue as? Bool {
                    Text("\(bool.description)")
                        .font(.system(size: fontSize, design: .monospaced))
                        .foregroundColor(.orange)
                } else if node.rawValue is NSNull {
                    Text("null")
                        .font(.system(size: fontSize, design: .monospaced))
                        .foregroundColor(.red)
                }
            }
            Spacer()
        }
        .padding(.vertical, 3) // Slightly more vertical padding
        .background(isSelected ? Color.accentColor.opacity(0.3) : Color.clear) // Stronger selection highlight
        .cornerRadius(4)
    }
}
