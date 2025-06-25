# iJSON: Intuitive JSON Viewer and Editor for macOS

iJSON is a lightweight and powerful macOS application designed to simplify the process of viewing, prettifying, and inspecting JSON data. It provides a clean, three-pane interface that allows users to paste raw JSON, visualize it as an interactive tree, and inspect individual nodes with detailed information.

## Features

iJSON offers a comprehensive set of features to enhance your JSON workflow:

### 1. Interactive Three-Pane Layout
The application features a highly intuitive three-pane interface:
*   **JSON Input Pane (Left):** A `TextEditor` where you can paste or type your raw JSON data. Includes a "Clear" button for quick input reset.
*   **Pretty JSON Output Pane (Middle):** Displays the parsed JSON in a beautifully formatted, interactive tree view. If the JSON is invalid, it falls back to displaying the raw error message.
*   **Node Inspector Pane (Right):** Provides detailed information about the currently selected JSON node in the tree view, including its key, type, value, raw value, and children count.

### 2. Robust JSON Parsing and Prettification
*   **Order Preservation:** Unlike standard `JSONSerialization` which may reorder keys, iJSON's custom parsing logic (implemented in `JSONNode.swift`) strives to preserve the original key order from the input string, ensuring fidelity to the source.
*   **Error Handling:** Gracefully handles invalid JSON input, displaying clear error messages to the user.

### 3. File Operations
Seamlessly work with JSON files on your disk:
*   **Open JSON File:** Access via `File > Open JSON File...` in the macOS menu bar (or `⌘O`). Allows you to select and load a `.json` file into the input pane.
*   **Save JSON File:** Access via `File > Save JSON File...` in the macOS menu bar (or `⌘S`). Exports the currently prettified JSON output to a `.json` file of your choice.

### 4. View Customization
Tailor the display to your preferences:
*   **Zoom In/Out:** Adjust the font size of the JSON content in both input and output panes. Accessible via `View > Zoom In` (`⌘+`) and `View > Zoom Out` (`⌘-`) in the macOS menu bar.
*   **Expand/Collapse All:** Quickly expand or collapse all nodes in the JSON tree view. Accessible via `View > Expand All` and `View > Collapse All` in the macOS menu bar.

### 5. Copy Functionality
*   **Copy Formatted Output:** A dedicated "Copy Output" button located at the top right of the "Pretty JSON Output" pane allows for quick copying of the entire prettified JSON content to your clipboard.

### 6. About Section
*   Access detailed information about the application via `Help > About iJSON` in the macOS menu bar. This section includes:
    *   Application Version (1.0.0)
    *   A brief description of iJSON's purpose.
    *   Creator information.
    *   A link to the GitHub repository for the source code.

## Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

*   **macOS:** A Mac computer running macOS.
*   **Xcode:** Apple's integrated development environment (IDE). You can download it for free from the Mac App Store. Ensure you have a recent version installed (e.g., Xcode 15 or later for SwiftUI features used).

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/blakberrisigma/iJSON.git
    cd iJSON
    ```

2.  **Open the project in Xcode:**
    Navigate to the cloned directory and open the `.xcodeproj` file:
    ```bash
    open iJSON.xcodeproj
    ```
    Alternatively, you can open Xcode, then go to `File > Open...` and select the `iJSON.xcodeproj` file.

## Building and Running

Once the project is open in Xcode:

1.  **Select a Target:** In the Xcode toolbar, select `iJSON` as the target and choose `My Mac` as the run destination.
2.  **Build and Run:** Click the "Run" button (▶️) in the Xcode toolbar, or press `⌘R`. Xcode will compile the application and launch it on your Mac.

## Project Structure (Key Files)

*   `iJSONApp.swift`: The entry point of the SwiftUI application, defining the main `WindowGroup` and application-level commands (macOS menu bar).
*   `ContentView.swift`: The main view of the application, containing the three-pane layout, input/output logic, and handling of various UI actions via `NotificationCenter`.
*   `JSONNode.swift`: Defines the `JSONNode` class, which is the core data model for representing JSON as an observable tree structure. Includes custom parsing and prettification logic.
*   `JSONTreeView.swift`: A SwiftUI view responsible for rendering the interactive JSON tree from `JSONNode` objects.
*   `InspectionView.swift`: A SwiftUI view that displays detailed information about a selected `JSONNode`.
*   `Notifications.swift`: Contains extensions for `Notification.Name` to facilitate communication between `iJSONApp` (menu bar) and `ContentView`.
*   `RULES.md`: A document outlining software engineering best practices and common pitfalls encountered during the development of iJSON, serving as a guide for future contributions.

## Creator

*   **Siraj**

## Versioning

**Version:** 1.0.0

## License

[Consider adding a license here, e.g., MIT, Apache 2.0, if not already present in the repository.]
