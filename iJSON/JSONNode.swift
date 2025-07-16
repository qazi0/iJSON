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
    let originalJsonStringSegment: String? // Stores the original string for ordered parsing
    @Published var isExpanded: Bool = false
    
    // Performance optimization: Use lazy loading with proper caching
    private var _children: [JSONNode]?
    private var _childrenComputed: Bool = false
    private let computationQueue = DispatchQueue(label: "json.node.computation", qos: .userInitiated)
    
    var children: [JSONNode] {
        if _childrenComputed, let cachedChildren = _children {
            return cachedChildren
        }
        
        let computedChildren: [JSONNode]
        
        // Performance optimization: Only compute children for objects and arrays
        if type == "Object", let dict = rawValue as? [String: Any] {
            if let jsonString = originalJsonStringSegment {
                computedChildren = JSONNode.parseOrderedObjectChildren(from: jsonString, parentRawValue: dict)
            } else {
                // Fallback to unordered children if no original string
                computedChildren = dict.map { key, value in
                    JSONNode.from(json: value, key: key)
                }
            }
        } else if type == "Array", let array = rawValue as? [Any] {
            if let jsonString = originalJsonStringSegment {
                computedChildren = JSONNode.parseOrderedArrayChildren(from: jsonString, parentRawValue: array)
            } else {
                // Fallback to simple array parsing
                computedChildren = array.enumerated().map { index, value in
                    JSONNode.from(json: value, key: nil)
                }
            }
        } else {
            computedChildren = []
        }
        
        _children = computedChildren
        _childrenComputed = true
        return computedChildren
    }

    var isExpandable: Bool {
        return type == "Object" || type == "Array"
    }
    
    // Performance optimization: Cache the children count
    private var _childrenCount: Int?
    var childrenCount: Int {
        if let cached = _childrenCount {
            return cached
        }
        
        let count: Int
        if type == "Object", let dict = rawValue as? [String: Any] {
            count = dict.count
        } else if type == "Array", let array = rawValue as? [Any] {
            count = array.count
        } else {
            count = 0
        }
        
        _childrenCount = count
        return count
    }

    init(key: String?, type: String, rawValue: Any, originalJsonStringSegment: String? = nil, isExpanded: Bool = false) {
        self.key = key
        self.type = type
        self.rawValue = rawValue
        self.originalJsonStringSegment = originalJsonStringSegment
        self.isExpanded = isExpanded
        self._children = nil
        self._childrenComputed = false
    }

    // Helper to convert Any to JSONNode
    // Now takes jsonStringSegment for ordered parsing
    static func from(json: Any, key: String? = nil, jsonStringSegment: String? = nil) -> JSONNode {
        if let bool = json as? Bool { // Direct Bool check
            return JSONNode(key: key, type: "Boolean", rawValue: bool)
        } else if let num = json as? NSNumber { // Check NSNumber, then if it's a boolean
            if CFBooleanGetTypeID() == CFGetTypeID(num) { // Check if it's actually a CFBoolean (true/false)
                return JSONNode(key: key, type: "Boolean", rawValue: num.boolValue)
            } else {
                return JSONNode(key: key, type: "Number", rawValue: num)
            }
        } else if let dict = json as? [String: Any] {
            return JSONNode(key: key, type: "Object", rawValue: dict, originalJsonStringSegment: jsonStringSegment, isExpanded: false)
        } else if let arr = json as? [Any] {
            return JSONNode(key: key, type: "Array", rawValue: arr, originalJsonStringSegment: jsonStringSegment, isExpanded: false)
        } else if let str = json as? String {
            return JSONNode(key: key, type: "String", rawValue: str)
        } else {
            return JSONNode(key: key, type: "Null", rawValue: NSNull())
        }
    }

    // Function to recursively set expansion state with performance optimization
    func setExpansion(to expanded: Bool) {
        self.isExpanded = expanded
        
        // Only compute children if we're expanding and they haven't been computed yet
        if expanded && !_childrenComputed {
            // Trigger children computation
            _ = children
        }
        
        // Recursively set expansion for already computed children
        if _childrenComputed, let computedChildren = _children {
            for child in computedChildren {
                child.setExpansion(to: expanded)
            }
        }
    }
    
    // Performance optimization: Only expand visible nodes initially
    func expandAllInitially(maxDepth: Int = 3) {
        expandToDepth(currentDepth: 0, maxDepth: maxDepth)
    }
    
    private func expandToDepth(currentDepth: Int, maxDepth: Int) {
        if isExpandable && currentDepth < maxDepth {
            self.isExpanded = true
            for child in children {
                child.expandToDepth(currentDepth: currentDepth + 1, maxDepth: maxDepth)
            }
        }
    }

    // MARK: - String Conversion for Prettified Output (Order Preserving)
    func toPrettifiedString(indentationLevel: Int = 0) -> String {
        let indent = String(repeating: "    ", count: indentationLevel)
        let nextIndent = String(repeating: "    ", count: indentationLevel + 1)

        switch type {
        case "Object":
            // Use children for ordered keys
            if childrenCount == 0 { return "{}" }

            var objectString = "{\n"
            let nodeChildren = children
            for (index, child) in nodeChildren.enumerated() {
                objectString += "\(nextIndent)\"\(child.key ?? "null")\": \(child.toPrettifiedString(indentationLevel: indentationLevel + 1))"
                if index < nodeChildren.count - 1 {
                    objectString += ","
                }
                objectString += "\n"
            }
            objectString += "\(indent)}"
            return objectString

        case "Array":
            if childrenCount == 0 { return "[]" }

            var arrayString = "[\n"
            let nodeChildren = children
            for (index, child) in nodeChildren.enumerated() {
                arrayString += "\(nextIndent)\(child.toPrettifiedString(indentationLevel: indentationLevel + 1))"
                if index < nodeChildren.count - 1 {
                    arrayString += ","
                }
                arrayString += "\n"
            }
            arrayString += "\(indent)]"
            return arrayString

        case "String":
            let stringValue = rawValue as? String ?? ""
            return JSONNode.escapeJSONString(stringValue)

        case "Number":
            return "\(rawValue as? NSNumber ?? 0)"

        case "Boolean":
            // Ensure boolean values are represented as "true" or "false" strings
            return "\(rawValue as? Bool ?? false)"

        case "Null":
            return "null"

        default:
            return "\(rawValue)"
        }
    }
    
    // Performance optimization: Extract string escaping to a static method
    private static func escapeJSONString(_ stringValue: String) -> String {
        var escapedString = ""
        escapedString.reserveCapacity(stringValue.count + 20) // Reserve capacity for performance
        
        for scalar in stringValue.unicodeScalars {
            switch scalar.value {
            case 0x08: escapedString += "\\b" // Backspace
            case 0x0C: escapedString += "\\f" // Form feed
            case 0x0A: escapedString += "\\n" // Newline
            case 0x0D: escapedString += "\\r" // Carriage return
            case 0x09: escapedString += "\\t" // Tab
            case 0x22: escapedString += "\\\"" // Double quote (")
            case 0x5C: escapedString += "\\\\" // Backslash (\)
            case 0x2F: escapedString += "\\/" // Solidus (/) - optional, but common
            case 0x00..<0x20, 0x7F: // Other control characters and DEL
                escapedString += String(format: "\\u%04x", scalar.value)
            default:
                if scalar.isASCII {
                    escapedString.append(Character(scalar))
                } else {
                    escapedString += String(format: "\\u%04x", scalar.value)
                }
            }
        }
        return "\"\(escapedString)\""
    }

    // MARK: - Private Order-Preserving Parsing Helpers (Optimized)

    private static func parseOrderedObjectChildren(from jsonString: String, parentRawValue: [String: Any]) -> [JSONNode] {
        var childrenNodes: [JSONNode] = []
        childrenNodes.reserveCapacity(parentRawValue.count) // Reserve capacity for performance
        
        // Performance optimization: Use a more efficient parsing approach
        guard jsonString.count > 2 else { return [] } // Must have at least "{}"
        
        let keyPattern = #""([^"\\]*(?:\\.[^"\\]*)*)"\s*:"#
        guard let keyRegex = try? NSRegularExpression(pattern: keyPattern, options: []) else {
            return fallbackToUnorderedChildren(from: parentRawValue)
        }
        
        let nsRange = NSRange(jsonString.startIndex..<jsonString.endIndex, in: jsonString)
        let matches = keyRegex.matches(in: jsonString, options: [], range: nsRange)
        
        var processedKeys = Set<String>() // Track processed keys to avoid duplicates
        
        for match in matches {
            guard match.numberOfRanges == 2 else { continue }
            
            let keyRange = match.range(at: 1)
            let colonEndRange = match.range(at: 0)
            
            guard let key = Range(keyRange, in: jsonString).map({ String(jsonString[$0]) }),
                  !processedKeys.contains(key),
                  let valueStartNSRange = Range(colonEndRange, in: jsonString).map({ NSRange($0.upperBound..<jsonString.endIndex, in: jsonString) }) else {
                continue
            }
            
            processedKeys.insert(key)
            let valueStartIndex = jsonString.index(jsonString.startIndex, offsetBy: valueStartNSRange.location)
            
            let extractedValue = extractJSONValueString(from: jsonString, startingAt: valueStartIndex)
            guard let valueStringSegment = extractedValue.valueString else {
                continue
            }
            
            if let parsedValue = parentRawValue[key] {
                let childNode = JSONNode.from(json: parsedValue, key: key, jsonStringSegment: valueStringSegment)
                childrenNodes.append(childNode)
            }
        }
        
        return childrenNodes
    }
    
    private static func fallbackToUnorderedChildren(from parentRawValue: [String: Any]) -> [JSONNode] {
        return parentRawValue.map { key, value in
            JSONNode.from(json: value, key: key)
        }
    }

    private static func parseOrderedArrayChildren(from jsonString: String, parentRawValue: [Any]) -> [JSONNode] {
        var childrenNodes: [JSONNode] = []
        childrenNodes.reserveCapacity(parentRawValue.count) // Reserve capacity for performance
        
        // Performance optimization: Handle small arrays efficiently
        guard jsonString.count > 2 else { return [] } // Must have at least "[]"
        
        // Find content between [ and ]
        guard let firstBracket = jsonString.firstIndex(of: "["),
              let lastBracket = jsonString.lastIndex(of: "]") else {
            return fallbackToUnorderedArrayChildren(from: parentRawValue)
        }
        
        let arrayContentRange = jsonString.index(after: firstBracket)..<lastBracket
        let arrayContent = String(jsonString[arrayContentRange])
        
        var currentIndex = arrayContent.startIndex
        var elementIndex = 0
        let maxElements = parentRawValue.count
        
        while currentIndex < arrayContent.endIndex && elementIndex < maxElements {
            // Skip leading whitespace and commas
            currentIndex = arrayContent[currentIndex...].firstIndex(where: { !$0.isWhitespace && $0 != "," }) ?? arrayContent.endIndex
            
            guard currentIndex < arrayContent.endIndex else { break }
            
            let extractedElement = extractJSONValueString(from: arrayContent, startingAt: currentIndex)
            guard let elementStringSegment = extractedElement.valueString,
                  let nextIndex = extractedElement.endIndex else {
                // Performance optimization: Skip malformed elements more efficiently
                currentIndex = arrayContent.index(currentIndex, offsetBy: 1, limitedBy: arrayContent.endIndex) ?? arrayContent.endIndex
                continue
            }
            
            if elementIndex < parentRawValue.count {
                let parsedValue = parentRawValue[elementIndex]
                let childNode = JSONNode.from(json: parsedValue, key: nil, jsonStringSegment: elementStringSegment)
                childrenNodes.append(childNode)
                elementIndex += 1
            }
            
            currentIndex = nextIndex
        }
        
        return childrenNodes
    }
    
    private static func fallbackToUnorderedArrayChildren(from parentRawValue: [Any]) -> [JSONNode] {
        return parentRawValue.enumerated().map { index, value in
            JSONNode.from(json: value, key: nil)
        }
    }

    // MARK: - Core JSON Value String Extraction (Optimized)

    private static func extractJSONValueString(from jsonString: String, startingAt startIndex: String.Index) -> (valueString: String?, endIndex: String.Index?) {
        var currentIndex = startIndex
        
        // Skip leading whitespace
        currentIndex = jsonString[currentIndex...].firstIndex(where: { !$0.isWhitespace }) ?? jsonString.endIndex
        guard currentIndex < jsonString.endIndex else { return (nil, nil) }
        
        let firstChar = jsonString[currentIndex]
        var balanceCount = 0 // For objects {} and arrays []
        var inQuote = false
        var valueEndIndex: String.Index? = nil
        
        switch firstChar {
        case "{":
            balanceCount = 1
            currentIndex = jsonString.index(after: currentIndex)
            while currentIndex < jsonString.endIndex {
                let char = jsonString[currentIndex]
                if inQuote {
                    if char == "\"" { 
                        inQuote = false 
                    } else if char == "\\" {
                        currentIndex = skipEscapeSequence(in: jsonString, from: currentIndex) ?? jsonString.endIndex
                    }
                } else {
                    if char == "{" { balanceCount += 1 }
                    else if char == "}" { balanceCount -= 1 }
                    else if char == "\"" { inQuote = true }
                }
                if balanceCount == 0 {
                    valueEndIndex = jsonString.index(after: currentIndex)
                    break
                }
                currentIndex = jsonString.index(after: currentIndex)
            }
        case "[":
            balanceCount = 1
            currentIndex = jsonString.index(after: currentIndex)
            while currentIndex < jsonString.endIndex {
                let char = jsonString[currentIndex]
                if inQuote {
                    if char == "\"" { 
                        inQuote = false 
                    } else if char == "\\" { 
                        currentIndex = skipEscapeSequence(in: jsonString, from: currentIndex) ?? jsonString.endIndex
                    }
                } else {
                    if char == "[" { balanceCount += 1 }
                    else if char == "]" { balanceCount -= 1 }
                    else if char == "\"" { inQuote = true }
                }
                if balanceCount == 0 {
                    valueEndIndex = jsonString.index(after: currentIndex)
                    break
                }
                currentIndex = jsonString.index(after: currentIndex)
            }
        case "\"": // String
            inQuote = true
            currentIndex = jsonString.index(after: currentIndex)
            while currentIndex < jsonString.endIndex {
                let char = jsonString[currentIndex]
                if char == "\"" {
                    // Check if this quote is unescaped by counting preceding backslashes
                    if !isEscapedQuote(in: jsonString, at: currentIndex, startingFrom: startIndex) {
                        valueEndIndex = jsonString.index(after: currentIndex)
                        break
                    }
                } else if char == "\\" {
                    currentIndex = skipEscapeSequence(in: jsonString, from: currentIndex) ?? jsonString.endIndex
                }
                currentIndex = jsonString.index(after: currentIndex)
            }
        default: // Number, Boolean, Null
            while currentIndex < jsonString.endIndex {
                let char = jsonString[currentIndex]
                if char.isWhitespace || char == "," || char == "}" || char == "]" {
                    valueEndIndex = currentIndex
                    break
                }
                currentIndex = jsonString.index(after: currentIndex)
            }
            if valueEndIndex == nil { // Reached end of string
                valueEndIndex = jsonString.endIndex
            }
        }
        
        guard let end = valueEndIndex else { return (nil, nil) }
        let valueString = String(jsonString[startIndex..<end])
        return (valueString, end)
    }
    
    // Performance optimization: Helper method to skip escape sequences
    private static func skipEscapeSequence(in jsonString: String, from currentIndex: String.Index) -> String.Index? {
        let nextIndex = jsonString.index(after: currentIndex)
        guard nextIndex < jsonString.endIndex else { return nil }
        
        if jsonString[nextIndex] == "u" {
            // Unicode escape \uXXXX, skip 5 characters total
            return jsonString.index(currentIndex, offsetBy: 5, limitedBy: jsonString.endIndex)
        } else {
            // Standard escape like \", \\, \n, etc., skip 1 character
            return jsonString.index(after: currentIndex)
        }
    }
    
    // Performance optimization: More efficient escaped quote detection
    private static func isEscapedQuote(in jsonString: String, at quoteIndex: String.Index, startingFrom startIndex: String.Index) -> Bool {
        guard quoteIndex > startIndex else { return false }
        
        var backslashCount = 0
        var tempIndex = jsonString.index(before: quoteIndex)
        
        while tempIndex >= startIndex && jsonString[tempIndex] == "\\" {
            backslashCount += 1
            if tempIndex == startIndex { break }
            tempIndex = jsonString.index(before: tempIndex)
        }
        
        return backslashCount % 2 == 1 // Odd number of backslashes means it's escaped
    }
}

// Helper extension for checking if a character is escaped
extension String.Index {
    func isBackslashEscaped(in string: String) -> Bool {
        guard self > string.startIndex else { return false }
        let prevIndex = string.index(before: self)
        return string[prevIndex] == "\\"
    }
}
