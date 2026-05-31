# NutriLoad 🛡️

An offline-first, highly optimized iOS application designed for advanced workout tonnage tracking and dynamic macronutrient calculation. Built with clean architecture principles to ensure seamless data persistence even in environments with zero network connectivity.

---

## 🏗 Architecture & Engineering Decisions

NutriLoad is not just a tracking app; it is a demonstration of robust iOS engineering and architectural patterns:

*   **Offline-First Approach:** Utilizes **Core Data** with background context processing (`NSMergeByPropertyObjectTrumpMergePolicy`) to ensure the main thread never blocks during data operations.
*   **MVVM-C (Coordinator) Pattern:** Separates navigation logic from views, preventing tight coupling and ensuring a scalable UI flow.
*   **Repository Pattern:** Abstracts the data layer (Core Data / Network) from the view models, adhering strictly to the Dependency Inversion principle.
*   **Asynchronous Network Synchronization:** Employs `NWPathMonitor` to detect network restoration. Pending data is automatically flushed to a FastAPI backend using Swift Concurrency (`async/await`).
*   **Business Logic Isolation:** The `MacroOptimizationEngine` calculates total workout tonnage and dynamic protein requirements in a pure Swift environment, completely decoupled from UI and Data layers for maximum testability.

---

## ✨ Key Features

*   **Tonnage Analytics:** Calculates total workout volume ($$Weight \times Reps \times RPE$$) and visualizes the progression using academic-standard **Swift Charts**.
*   **Dynamic Protein Targeting:** Adjusts daily protein requirements dynamically based on the daily workout volume compared to the target volume.
*   **Seamless Sync:** Workouts and meals logged offline are queued and automatically synced to the server when the connection is restored.
*   **Thread-Safe Core Data:** Prevents UI lagging through dedicated `newBackgroundContext` implementations.

---

## 🛠 Tech Stack

**Client (iOS):**
*   **Language:** Swift 5.0+
*   **UI Framework:** SwiftUI, Swift Charts
*   **Architecture:** MVVM-C
*   **Local Storage:** Core Data
*   **Concurrency:** Async/Await, Task, DispatchQueue

**Backend (Python):**
*   **Framework:** FastAPI
*   **Server:** Uvicorn
*   **Data Models:** Pydantic

---

## 🚀 Getting Started

### Prerequisites
*   Xcode 15.0+
*   iOS 17.0+
*   Python 3.9+ (For backend server)

### Running the Backend
1. Navigate to the Backend folder: `cd Backend`
2. Create a virtual environment: `python3 -m venv venv`
3. Activate the environment: `source venv/bin/activate`
4. Install dependencies: `pip install fastapi uvicorn`
5. Run the server: `uvicorn main:app --reload`

### Running the iOS App
1. Open `NutriLoad.xcodeproj` in Xcode.
2. Select an iOS Simulator or Device.
3. Hit `Cmd + R` to build and run.

---

## 👨‍💻 Author

**Atakan Özcan**
Computer Engineering Student | iOS & AI Researcher
