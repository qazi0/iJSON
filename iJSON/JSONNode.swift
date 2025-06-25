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

    var children: [JSONNode] {
        if type == "Object", let jsonString = originalJsonStringSegment,
           let dict = rawValue as? [String: Any] {
            return JSONNode.parseOrderedObjectChildren(from: jsonString, parentRawValue: dict)
        } else if type == "Array", let jsonString = originalJsonStringSegment,
                  let array = rawValue as? [Any] {
            return JSONNode.parseOrderedArrayChildren(from: jsonString, parentRawValue: array)
        }
        return []
    }

    var isExpandable: Bool {
        return type == "Object" || type == "Array"
    }

    init(key: String?, type: String, rawValue: Any, originalJsonStringSegment: String? = nil, isExpanded: Bool = false) {
        self.key = key
        self.type = type
        self.rawValue = rawValue
        self.originalJsonStringSegment = originalJsonStringSegment
        self.isExpanded = isExpanded
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

    // Function to recursively set expansion state
    func setExpansion(to expanded: Bool) {
        self.isExpanded = expanded
        for child in children {
            child.setExpansion(to: expanded)
        }
    }

    // MARK: - String Conversion for Prettified Output (Order Preserving)
    func toPrettifiedString(indentationLevel: Int = 0) -> String {
        let indent = String(repeating: "    ", count: indentationLevel)
        let nextIndent = String(repeating: "    ", count: indentationLevel + 1)

        switch type {
        case "Object":
            // Use children for ordered keys
            if children.isEmpty { return "{}" }

            var objectString = "{\n"
            for (index, child) in children.enumerated() {
                objectString += "\(nextIndent)\"\(child.key ?? "null")\": \(child.toPrettifiedString(indentationLevel: indentationLevel + 1))"
                if index < children.count - 1 {
                    objectString += ","
                }
                objectString += "\n"
            }
            objectString += "\(indent)}"
            return objectString

        case "Array":
            if children.isEmpty { return "[]" }

            var arrayString = "[\n"
            for (index, child) in children.enumerated() {
                arrayString += "\(nextIndent)\(child.toPrettifiedString(indentationLevel: indentationLevel + 1))"
                if index < children.count - 1 {
                    arrayString += ","
                }
                arrayString += "\n"
            }
            arrayString += "\(indent)]"
            return arrayString

        case "String":
            let stringValue = rawValue as? String ?? ""
            var escapedString = ""
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

    // MARK: - Private Order-Preserving Parsing Helpers

    private static func parseOrderedObjectChildren(from jsonString: String, parentRawValue: [String: Any]) -> [JSONNode] {
        var childrenNodes: [JSONNode] = []
        
        // Regex to find "key": part
        let keyPattern = #""([^"\\]*(?:\\.[^"\\]*)*)"\s*:"#
        guard let keyRegex = try? NSRegularExpression(pattern: keyPattern, options: []) else {
            return []
        }
        
        let nsRange = NSRange(jsonString.startIndex..<jsonString.endIndex, in: jsonString)
        var currentSearchRange = nsRange
        
        while currentSearchRange.location != NSNotFound {
            let keyMatch = keyRegex.firstMatch(in: jsonString, options: [], range: currentSearchRange)
            
            guard let match = keyMatch, match.numberOfRanges == 2 else {
                break // No more keys found or malformed
            }
            
            let keyRange = match.range(at: 1)
            let colonEndRange = match.range(at: 0) // Range of "key":
            
            guard let key = Range(keyRange, in: jsonString).map({ String(jsonString[$0]) }),
                  let valueStartNSRange = Range(colonEndRange, in: jsonString).map({ NSRange($0.upperBound..<jsonString.endIndex, in: jsonString) }) else {
                break
            }
            
            let valueStartIndex = jsonString.index(jsonString.startIndex, offsetBy: valueStartNSRange.location)
            
            let extractedValue = extractJSONValueString(from: jsonString, startingAt: valueStartIndex)
            guard let valueStringSegment = extractedValue.valueString,
                  let valueEndIndex = extractedValue.endIndex else {
                // If value extraction fails, try to advance past the key and colon to avoid infinite loop
                currentSearchRange = NSRange(location: colonEndRange.location + colonEndRange.length, length: jsonString.distance(from: jsonString.startIndex, to: jsonString.endIndex) - (colonEndRange.location + colonEndRange.length))
                continue // Skip to next key
            }
            
            if let parsedValue = parentRawValue[key] {
                let childNode = JSONNode.from(json: parsedValue, key: key, jsonStringSegment: valueStringSegment)
                childrenNodes.append(childNode)
            }
            
            // Update search range to continue after the current value
            let remainingLength = jsonString.distance(from: valueEndIndex, to: jsonString.endIndex)
            currentSearchRange = NSRange(location: jsonString.distance(from: jsonString.startIndex, to: valueEndIndex), length: remainingLength)
        }
        
        return childrenNodes
    }

    private static func parseOrderedArrayChildren(from jsonString: String, parentRawValue: [Any]) -> [JSONNode] {
        var childrenNodes: [JSONNode] = []
        
        // Find content between [ and ]
        guard let firstBracket = jsonString.firstIndex(of: "["),
              let lastBracket = jsonString.lastIndex(of: "]") else {
            return []
        }
        
        let arrayContentRange = jsonString.index(after: firstBracket)..<lastBracket
        let arrayContent = String(jsonString[arrayContentRange])
        
        var currentIndex = arrayContent.startIndex
        var elementIndex = 0
        
        while currentIndex < arrayContent.endIndex {
            // Skip leading whitespace and commas
            currentIndex = arrayContent[currentIndex...].firstIndex(where: { !$0.isWhitespace && $0 != "," }) ?? arrayContent.endIndex
            
            guard currentIndex < arrayContent.endIndex else { break }
            
            let extractedElement = extractJSONValueString(from: arrayContent, startingAt: currentIndex)
            guard let elementStringSegment = extractedElement.valueString,
                  let nextIndex = extractedElement.endIndex else {
                // If element extraction fails, try to advance past current index to avoid infinite loop
                currentIndex = arrayContent.index(after: currentIndex) // Advance by one character
                continue // Skip to next element
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

    // MARK: - Core JSON Value String Extraction

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
                    if char == "\"" { inQuote = false }
                    else if char == "\\" {
                        let nextIndex = jsonString.index(after: currentIndex)
                        if nextIndex < jsonString.endIndex && jsonString[nextIndex] == "u" {
                            // It's a unicode escape \uXXXX, skip 5 characters
                            if let targetIndex = jsonString.index(currentIndex, offsetBy: 5, limitedBy: jsonString.endIndex) {
                                currentIndex = targetIndex
                            } else {
                                // Malformed unicode escape, treat as end of string or error
                                valueEndIndex = nil // Indicate error
                                break
                            }
                        } else {
                            // Standard escape like \", \\, \n, etc., skip 1 character
                            currentIndex = jsonString.index(after: currentIndex)
                        }
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
                    if char == "\"" { inQuote = false }
                    else if char == "\\" { currentIndex = jsonString.index(after: currentIndex) } // Skip escaped char
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
                    var backslashCount = 0
                    var tempIndex = jsonString.index(before: currentIndex)
                    while tempIndex >= startIndex && jsonString[tempIndex] == "\\" {
                        backslashCount += 1
                        if tempIndex == startIndex { break } // Prevent going out of bounds
                        tempIndex = jsonString.index(before: tempIndex)
                    }
                    if backslashCount % 2 == 0 { // Even number of backslashes means it's an unescaped quote
                        valueEndIndex = jsonString.index(after: currentIndex)
                        break
                    }
                } else if char == "\\" {
                    // Handle escaped characters
                    let nextIndex = jsonString.index(after: currentIndex)
                    if nextIndex < jsonString.endIndex && jsonString[nextIndex] == "u" {
                        // It's a unicode escape \uXXXX, skip 5 characters
                        if let targetIndex = jsonString.index(currentIndex, offsetBy: 5, limitedBy: jsonString.endIndex) {
                            currentIndex = targetIndex
                        } else {
                            // Malformed unicode escape, treat as error
                            valueEndIndex = nil // Indicate error
                            break
                        }
                    } else {
                        // Standard escape like \", \\, \n, etc., skip 1 character
                        currentIndex = jsonString.index(after: currentIndex)
                    }
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
}

// Helper extension for checking if a character is escaped
extension String.Index {
    func isBackslashEscaped(in string: String) -> Bool {
        guard self > string.startIndex else { return false }
        let prevIndex = string.index(before: self)
        return string[prevIndex] == "\\"
    }
}
