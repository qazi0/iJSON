//
//  JSONNode.swift
//  iJSON
//
//  Created by blakberrisigma on 25/06/2025.
//

import Foundation
import Combine // Required for ObservableObject

class JSONNode: ObservableObject, Identifiable {
    let id = UUID()
    let key: String?
    let type: String
    let rawValue: Any // Stores the actual value (String, NSNumber, Bool, [String: Any], [Any], NSNull)
    @Published var isExpanded: Bool = false

    var children: [JSONNode] {
        if let dict = rawValue as? [String: Any] {
            return dict.sorted(by: { $0.key < $1.key }).map { JSONNode.from(json: $0.value, key: $0.key) }
        } else if let array = rawValue as? [Any] {
            return array.map { JSONNode.from(json: $0) }
        }
        return []
    }

    var isExpandable: Bool {
        return rawValue is [String: Any] || rawValue is [Any]
    }

    init(key: String?, type: String, rawValue: Any, isExpanded: Bool = false) {
        self.key = key
        self.type = type
        self.rawValue = rawValue
        self.isExpanded = isExpanded
    }

    // Helper to convert Any to JSONNode
    static func from(json: Any, key: String? = nil) -> JSONNode {
        if let dict = json as? [String: Any] {
            return JSONNode(key: key, type: "Object", rawValue: dict, isExpanded: false)
        } else if let arr = json as? [Any] {
            return JSONNode(key: key, type: "Array", rawValue: arr, isExpanded: false)
        } else if let str = json as? String {
            return JSONNode(key: key, type: "String", rawValue: str)
        } else if let num = json as? NSNumber {
            return JSONNode(key: key, type: "Number", rawValue: num)
        } else if let bool = json as? Bool {
            return JSONNode(key: key, type: "Boolean", rawValue: bool)
        } else {
            return JSONNode(key: key, type: "Null", rawValue: NSNull())
        }
    }

    // Function to recursively set expansion state
    func setExpansion(to expanded: Bool) {
        self.isExpanded = expanded
        for child in children {
            child.setExpansion(to: expanded)
        }
    }
}
