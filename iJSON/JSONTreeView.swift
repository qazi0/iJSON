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
                        .padding(.leading, 15)
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
                }
            } else {
                NodeLabel(node: node, fontSize: fontSize, isSelected: selectedNode?.id == node.id)
                    .contentShape(Rectangle()) // Make the whole row tappable
                    .onTapGesture {
                        selectedNode = node
                    }
            }
        }
    }
}

struct NodeLabel: View {
    @ObservedObject var node: JSONNode // Change to ObservedObject
    let fontSize: CGFloat
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            if let key = node.key {
                Text("\"\(key)\"")
                    .font(.system(size: fontSize, design: .monospaced))
                    .foregroundColor(.purple)
                Text(":")
                    .font(.system(size: fontSize, design: .monospaced))
                    .foregroundColor(.gray)
            }

            Group {
                // Display logic based on node.rawValue
                if node.rawValue is [String: Any] { // Object
                    Text(node.isExpanded ? "{" : "{...}")
                        .font(.system(size: fontSize, design: .monospaced))
                        .foregroundColor(.black)
                    if !node.isExpanded {
                        Text("(\(node.children.count) items)")
                            .font(.system(size: fontSize - 2, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                } else if node.rawValue is [Any] { // Array
                    Text(node.isExpanded ? "[" : "[...]")
                        .font(.system(size: fontSize, design: .monospaced))
                        .foregroundColor(.black)
                    if !node.isExpanded {
                        Text("(\(node.children.count) items)")
                            .font(.system(size: fontSize - 2, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                } else if let str = node.rawValue as? String {
                    Text("\"\(str)\"")
                        .font(.system(size: fontSize, design: .monospaced))
                        .foregroundColor(.green)
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
        .padding(.vertical, 2)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(4)
    }
}
