# Code Refactoring Guide - Modular Architecture

## Overview
The codebase has been refactored into a modular architecture for better maintainability, testability, and scalability.

## New Directory Structure

```
RNBA Admin/
├── Models/
│   └── RegistrationModels.swift          # Data models and enums
├── Services/
│   ├── RegistrationService.swift         # Registration CRUD operations
│   ├── DashboardService.swift            # Dashboard statistics
│   └── DataServiceError.swift            # Error definitions
├── Views/
│   ├── OverviewTabView.swift             # Dashboard/Overview tab
│   ├── SearchableListTabView.swift       # Visitor list tab
│   ├── SettingsTabView.swift             # Settings tab
│   ├── NewRegistrationView.swift         # Registration form
│   └── Components/
│       └── SharedComponents.swift        # Reusable UI components
├── ContentView.swift                     # Main tab coordinator
├── AuthenticationManager.swift           # Authentication logic
├── AuthenticationView.swift              # Auth UI
├── MainAppView.swift                     # App entry point
├── SupabaseConfig.swift                  # Supabase configuration
└── TestSchemaModels.swift                # Database models
```

## Architecture Principles

### 1. **Separation of Concerns**
- **Models**: Pure data structures
- **Services**: Business logic and data operations
- **Views**: UI presentation only

### 2. **Single Responsibility**
- Each file has one clear purpose
- Services handle specific domains (Registration, Visitor, Dashboard)
- Views represent single screens or components

### 3. **Dependency Injection**
- Services are instantiated in views
- No global state (except SupabaseConfig)
- Easy to test and mock

## File Descriptions

### Models Directory

#### `RegistrationModels.swift`
Contains all registration-related data structures:
- `RegistrationData` - Form data model
- `PersonData` - Individual person information
- `ContactDetails` - Contact information
- `VisitType` - Visit type enum (maps to database IDs)
- `FoodPreference` - Food preference enum (maps to database IDs)
- `PaymentType` - Payment type enum (maps to database IDs)

**Usage:**
```swift
import Foundation

var registrationData = RegistrationData()
registrationData.name = "John Doe"
registrationData.persons[0].visitType = .foodVisit
```

### Services Directory

#### `RegistrationService.swift`
Handles all registration-related database operations:
- `createRegistration()` - Creates new registration with contact, visitors, and payment
- `fetchRegistrations()` - Retrieves all registrations
- Helper methods for creating visitors and payments

**Usage:**
```swift
let service = RegistrationService()
let registrationId = try await service.createRegistration(registrationData)
```

#### `DashboardService.swift`
Handles dashboard statistics:
- `fetchDashboardStats()` - Aggregates statistics from multiple tables

**Usage:**
```swift
let service = DashboardService()
let stats = try await service.fetchDashboardStats()
```

#### `DataServiceError.swift`
Centralized error definitions:
- `registrationCreationFailed`
- `invalidData`
- `networkError`
- `unknownError`

### Views Directory

#### `OverviewTabView.swift`
Dashboard screen showing:
- Statistics cards (registrations, visitors, payments)
- Recent activity feed
- New registration button
- Error handling and retry

**Dependencies:**
- `DashboardService`
- `SharedComponents`

#### `SearchableListTabView.swift`
Visitor list screen with:
- Search functionality
- Completion toggle
- Empty states
- Error handling

**Dependencies:**
- `VisitorService`
- `SharedComponents`

#### `SettingsTabView.swift`
Settings screen with:
- App information
- Database status
- Authentication status
- Sign out functionality

**Dependencies:**
- `AuthenticationManager`

#### `NewRegistrationView.swift`
Registration form with:
- Basic information
- Person details (dynamic based on count)
- Contact details
- Payment information
- Form validation

**Dependencies:**
- `RegistrationService`
- `RegistrationModels`

#### `Components/SharedComponents.swift`
Reusable UI components:
- `StatCard` - Statistics display card
- `ActivityCard` - Activity feed item
- `SearchBar` - Search input field
- `ErrorStateView` - Error display with retry
- `EmptyStateView` - Empty state placeholder

**Usage:**
```swift
StatCard(
    title: "Total Visitors",
    value: "342",
    icon: "person.3.fill",
    color: .green
)
```

## Migration from Old Structure

### Before (Monolithic)
```
ContentView.swift (1300+ lines)
├── ContentView
├── OverviewTabView
├── QRScannerTabView
├── SearchableListTabView
├── SettingsTabView
├── NewRegistrationView
├── StatCard
├── ActivityCard
├── SearchBar
├── ErrorStateView
├── EmptyStateView
├── RegistrationData
├── PersonData
├── ContactDetails
├── VisitType
├── FoodPreference
└── PaymentType

DataService.swift (400+ lines)
├── createRegistration()
├── fetchRegistrations()
├── fetchVisitors()
├── fetchVisitorDetails()
├── updateVisitorCompletedStatus()
├── fetchDashboardStats()
└── Mock data generators
```

### After (Modular)
```
Models/
└── RegistrationModels.swift (90 lines)

Services/
├── RegistrationService.swift (180 lines)
├── DashboardService.swift (70 lines)
└── DataServiceError.swift (30 lines)

Views/
├── OverviewTabView.swift (170 lines)
├── SearchableListTabView.swift (170 lines)
├── SettingsTabView.swift (100 lines)
├── NewRegistrationView.swift (240 lines)
└── Components/
    └── SharedComponents.swift (250 lines)

ContentView.swift (120 lines)
```

## Benefits of New Structure

### 1. **Maintainability**
- Easy to locate specific functionality
- Changes are isolated to relevant files
- Clear file naming conventions

### 2. **Testability**
- Services can be tested independently
- Easy to mock dependencies
- Clear separation of business logic and UI

### 3. **Scalability**
- New features can be added without touching existing code
- Easy to add new services or views
- Consistent patterns across the codebase

### 4. **Collaboration**
- Multiple developers can work on different files simultaneously
- Reduced merge conflicts
- Clear ownership of components

### 5. **Code Reusability**
- Shared components can be used across views
- Services can be reused in different contexts
- Models are centralized

## Best Practices

### Adding a New Feature

1. **Create Model** (if needed)
   ```swift
   // Models/EventModels.swift
   struct EventData {
       var name: String
       var year: Int
   }
   ```

2. **Create Service**
   ```swift
   // Services/EventService.swift
   class EventService {
       func fetchEvents() async throws -> [Event] {
           // Implementation
       }
   }
   ```

3. **Create View**
   ```swift
   // Views/EventListView.swift
   struct EventListView: View {
       private let eventService = EventService()
       // Implementation
   }
   ```

4. **Add to Navigation**
   ```swift
   // ContentView.swift
   EventListView()
       .tabItem {
           Image(systemName: "calendar")
           Text("Events")
       }
   ```

### Naming Conventions

- **Models**: `<Domain>Models.swift` (e.g., `RegistrationModels.swift`)
- **Services**: `<Domain>Service.swift` (e.g., `DashboardService.swift`)
- **Views**: `<Screen>View.swift` (e.g., `OverviewTabView.swift`)
- **Components**: `<Purpose>Components.swift` (e.g., `SharedComponents.swift`)

### Service Patterns

All services should:
1. Be stateless (no @Published properties)
2. Use async/await for asynchronous operations
3. Throw errors instead of returning optionals
4. Support preview mode with mock data
5. Have clear, descriptive method names

Example:
```swift
class MyService {
    private let supabase = SupabaseConfig.client
    
    func fetchData() async throws -> [MyModel] {
        if SupabaseConfig.isPreviewMode {
            return mockData()
        }
        
        let response = try await supabase
            .from("table")
            .select()
            .execute()
        
        return try SupabaseConfig.decode(response.data, as: [MyModel].self)
    }
    
    private func mockData() -> [MyModel] {
        // Mock implementation
    }
}
```

### View Patterns

All views should:
1. Use `@State` for local state
2. Instantiate services as properties
3. Handle loading and error states
4. Support pull-to-refresh
5. Use shared components when possible

Example:
```swift
struct MyView: View {
    @State private var data: [MyModel] = []
    @State private var isLoading = false
    @State private var loadError: Error?
    
    private let myService = MyService()
    
    var body: some View {
        NavigationView {
            // UI implementation
        }
        .onAppear {
            loadData()
        }
        .refreshable {
            await loadData()
        }
    }
    
    private func loadData() {
        Task {
            isLoading = true
            loadError = nil
            
            do {
                data = try await myService.fetchData()
            } catch {
                loadError = error
            }
            
            isLoading = false
        }
    }
}
```

## Testing Strategy

### Unit Tests
- Test services independently
- Mock Supabase responses
- Test error handling

### Integration Tests
- Test service + database interactions
- Use test database

### UI Tests
- Test view rendering
- Test user interactions
- Use preview mode

## Future Improvements

1. **Dependency Injection Container**
   - Centralize service creation
   - Easier testing and mocking

2. **Repository Pattern**
   - Abstract database operations
   - Support multiple data sources

3. **View Models**
   - Separate business logic from views
   - Better testability

4. **Coordinator Pattern**
   - Handle navigation logic
   - Decouple views

5. **Feature Modules**
   - Group related files by feature
   - Better organization for large apps

## Conclusion

This modular architecture provides a solid foundation for building and maintaining the RNBA Admin app. Follow the established patterns and conventions to ensure consistency and quality across the codebase.
