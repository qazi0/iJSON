//
//  InspectionView.swift
//  iJSON
//
//  Created by blakberrisigma on 25/06/2025.
//

import SwiftUI

struct InspectionView: View {
    @Binding var selectedNode: JSONNode?
    let fontSize: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Node Inspector")
                .font(.headline)
                .padding(.bottom, 5)

            if let node = selectedNode {
                Group {
                    HStack {
                        Text("Key:")
                            .fontWeight(.bold)
                        Text(node.key ?? "N/A")
                    }
                    HStack {
                        Text("Type:")
                            .fontWeight(.bold)
                        Text(node.type)
                    }
                    VStack(alignment: .leading) {
                        Text("Value:")
                            .fontWeight(.bold)
                        ScrollView {
                            Text(displayValue(for: node))
                                .font(.system(size: fontSize, design: .monospaced))
                                .textSelection(.enabled)
                                .padding(4)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(4)
                        }
                        .frame(maxHeight: 200) // Limit height of value display
                    }
                }
                .font(.system(size: fontSize))
            } else {
                Text("Select a node in the JSON tree to inspect its properties.")
                    .font(.system(size: fontSize))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding()
        .frame(minWidth: 200, maxWidth: 400, alignment: .topLeading)
        .background(Color.white.opacity(0.05)) // Subtle background
        .cornerRadius(8)
        .shadow(radius: 2)
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
