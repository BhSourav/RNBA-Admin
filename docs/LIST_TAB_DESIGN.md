# List Tab - Registration & Visitor Management

## Overview
The List tab displays all registrations for a specific event. Tapping a registration opens a popup showing all visitors with food preferences and their completion status.

## Features

### 1. **Registration List View**
- Shows all registrations for the defined event (default: Event ID 2024)
- Each row displays:
  - **Registration ID**: Displayed as a badge (e.g., "#123")
  - **Name**: Registration holder's name
  - **Created Date**: Formatted date and time
  - **Chevron**: Indicates the row is tappable
- **Searchable**: Filter by registration ID or name
- **Pull-to-refresh**: Update the list

### 2. **Visitor Popup (Sheet)**
Opens when you tap a registration row. Shows:
- **Header**: Registration ID and name
- **Table**: All visitors with food (where `Visit_Type.withFood = true`)
  - **Visitor ID**: Unique identifier
  - **Food Preference**: Name from `Food_Type` table
  - **Completed**: Interactive checkbox

### 3. **Interactive Checkboxes**
- Tap to toggle visitor completion status
- Updates database immediately
- Visual feedback:
  - Checked: Green filled square
  - Unchecked: Gray empty square
  - Row background: Light green tint when completed

## Data Flow

### Registration List Query
```swift
// Fetch registrations for specific event
.from("test_schema.Registration")
.select("RegistrationID, Name, created_at")
.eq("Event", value: eventID)
.order("created_at", ascending: false)
```

### Visitor with Food Query
```swift
// 1. Get all visitors for registration
.from("test_schema.Visitors")
.select("*")
.eq("RegistrationID", value: registrationID)

// 2. Get visit types
.from("test_schema.Visit_Type")
.select("*")

// 3. Get food types
.from("test_schema.Food_Type")
.select("*")

// 4. Filter: Only visitors where Visit_Type.withFood = true
// 5. Map to VisitorWithFood model
```

### Update Completion Status
```swift
.from("test_schema.Visitors")
.update(["Completed": newStatus])
.eq("VisitorID", value: visitorID)
```

## Models

### RegistrationSummary
```swift
struct RegistrationSummary: Codable, Identifiable {
    let registrationID: Int64
    let name: String
    let createdAt: String
    
    var id: Int64 { registrationID }
}
```

### VisitorWithFood
```swift
struct VisitorWithFood: Identifiable {
    let visitorID: Int64
    let foodTypeName: String
    var completed: Bool
    
    var id: Int64 { visitorID }
}
```

## UI Components

### RegistrationListTabView
Main view showing the list of registrations:
- Search bar at top
- List of tappable registration rows
- Error and empty states
- Pull-to-refresh

### VisitorPopupView
Sheet/popup showing visitors for a registration:
- Header with registration info
- Table-style layout with headers
- Scrollable list of visitor rows
- Loading and error states
- "Done" button to dismiss

### VisitorRow
Individual row in the visitor table:
- Visitor ID (monospaced font)
- Food preference with icon
- Interactive checkbox

## Visual Design

### Registration Row
```
┌─────────────────────────────────────────────┐
│  #123  John Doe                          >  │
│        Oct 15, 2024, 10:30 AM               │
└─────────────────────────────────────────────┘
```

### Visitor Popup Table
```
┌─────────────────────────────────────────────┐
│  Registration #123                          │
│  John Doe                                   │
├─────────────────────────────────────────────┤
│  Visitor ID  │  Food Preference  │ Complete │
├─────────────────────────────────────────────┤
│  #1          │  🌿 Vegetarian    │    ☑️    │
│  #2          │  🍖 Non-Veg       │    ☐     │
│  #3          │  🌿 Vegetarian    │    ☐     │
└─────────────────────────────────────────────┘
```

## Key Logic

### Filtering Visitors with Food
Only shows visitors where their `Visit_Type` has `withFood = true`:

```swift
let visitorsWithFood = visitors.compactMap { visitor -> VisitorWithFood? in
    guard let visitType = visitTypes.first(where: { $0.visitID == visitor.visitID }),
          visitType.withFood else {
        return nil
    }
    
    let foodType = visitor.foodTypeID != nil ? 
        foodTypes.first(where: { $0.foodTypeID == visitor.foodTypeID }) : nil
    
    return VisitorWithFood(
        visitorID: visitor.visitorID,
        foodTypeName: foodType?.name ?? "Not specified",
        completed: visitor.completed
    )
}
```

### Real-time Updates
When checkbox is toggled:
1. Update database via `VisitorService.updateVisitorCompletedStatus()`
2. Update local state immediately for instant UI feedback
3. No need to reload entire list

## States Handled

### Registration List
- ✅ **Loading**: Shows spinner
- ✅ **Empty**: "No Registrations Yet"
- ✅ **Error**: Error view with retry button
- ✅ **Search Empty**: "No Results Found" with clear button
- ✅ **Success**: List of registrations

### Visitor Popup
- ✅ **Loading**: Shows spinner
- ✅ **Empty**: "No Visitors with Food"
- ✅ **Error**: Error message with retry
- ✅ **Success**: Table of visitors

## User Flow

1. **View Registrations**
   - Open List tab
   - See all registrations for the event
   - Use search to filter

2. **View Visitors**
   - Tap a registration row
   - Popup opens with visitor table
   - See all visitors with food preferences

3. **Mark Completion**
   - Tap checkbox for a visitor
   - Status updates immediately
   - Row highlights in green when completed

4. **Close Popup**
   - Tap "Done" button
   - Returns to registration list

## Search Functionality

Searches across:
- Registration ID (exact or partial match)
- Registration name (case-insensitive)

Example searches:
- "123" → Finds registration #123
- "john" → Finds "John Doe"
- "doe" → Finds "John Doe"

## Mock Data (Preview Mode)

### Sample Registrations
```swift
[
    RegistrationSummary(registrationID: 1, name: "John Doe", ...),
    RegistrationSummary(registrationID: 2, name: "Jane Smith", ...),
    RegistrationSummary(registrationID: 3, name: "Bob Johnson", ...),
    ...
]
```

### Sample Visitors
```swift
// For Registration #1
[
    VisitorWithFood(visitorID: 1, foodTypeName: "Vegetarian", completed: true),
    VisitorWithFood(visitorID: 2, foodTypeName: "Non-Vegetarian", completed: false)
]
```

## Database Schema Reference

### Tables Used
1. **Registration** - Main registration records
2. **Visitors** - Individual visitors
3. **Visit_Type** - Visit type definitions (has `withFood` flag)
4. **Food_Type** - Food preference options

### Key Relationships
- `Visitors.RegistrationID` → `Registration.RegistrationID`
- `Visitors.VisitID` → `Visit_Type.VisitID`
- `Visitors.FoodTypeID` → `Food_Type.FoodTypeID`

### Important Fields
- `Visit_Type.withFood` (bool) - Determines if visitor should appear in popup
- `Visitors.Completed` (bool) - Tracks completion status
- `Registration.Event` (int4) - Filters registrations by event

## Performance Considerations

### Optimizations
1. **Lazy Loading**: Visitors loaded only when popup opens
2. **Local State**: Checkbox updates don't require full reload
3. **Filtered Queries**: Only fetch registrations for specific event
4. **Efficient Filtering**: `compactMap` removes non-food visitors in one pass

### Caching
- Registration list cached in `@State`
- Visitor list cached per popup instance
- Pull-to-refresh to update

## Accessibility

- ✅ VoiceOver support for all interactive elements
- ✅ Clear labels for checkboxes
- ✅ Semantic headers for table columns
- ✅ Keyboard navigation support

## Error Handling

### Network Errors
- Shows error view with message
- Retry button to reload
- Doesn't crash on failure

### Empty States
- Clear messaging
- Helpful actions (e.g., clear search)
- Appropriate icons

## Files Created/Modified

### New Files
1. **RegistrationListTabView.swift** - Main list view and popup
   - `RegistrationListTabView` - List of registrations
   - `VisitorPopupView` - Popup with visitor table
   - `VisitorRow` - Individual visitor row component

### Modified Files
2. **RegistrationModels.swift** - Added new models
   - `RegistrationSummary` - Registration list item
   - `VisitorWithFood` - Visitor with food info

3. **RegistrationService.swift** - Added new methods
   - `fetchRegistrationsForEvent()` - Get registrations
   - `fetchVisitorsWithFood()` - Get visitors with food
   - Mock data generators

4. **ContentView.swift** - Updated tab
   - Changed from `SearchableListTabView` to `RegistrationListTabView`

## Future Enhancements

### Possible Additions
1. **Bulk Actions**: Mark all visitors as completed
2. **Filtering**: Filter by food type or completion status
3. **Sorting**: Sort by visitor ID, food type, or status
4. **Export**: Export visitor list as CSV/PDF
5. **Statistics**: Show count of completed vs. pending
6. **Swipe Actions**: Swipe to mark complete/incomplete
7. **Detail View**: Tap visitor for more details
8. **Batch Update**: Select multiple visitors to update

### Advanced Features
1. **Real-time Updates**: Live updates via Supabase Realtime
2. **Offline Support**: Cache data for offline viewing
3. **Push Notifications**: Alert when all visitors completed
4. **Analytics**: Track completion rates over time

## Testing Checklist

- [x] Registration list loads correctly
- [x] Search filters registrations
- [x] Tapping row opens popup
- [x] Popup shows correct visitors
- [x] Only visitors with food appear
- [x] Checkboxes toggle correctly
- [x] Database updates on toggle
- [x] Local state updates immediately
- [x] Empty states show correctly
- [x] Error states show correctly
- [x] Loading states work
- [x] Pull-to-refresh works
- [x] Mock data works in preview
- [x] Date formatting is correct
- [x] Food icons display correctly

## Summary

The List tab provides a **comprehensive registration and visitor management interface**:

- **Quick access**: See all registrations at a glance
- **Detailed view**: Tap to see visitors with food
- **Easy management**: Toggle completion with checkboxes
- **Filtered data**: Only shows visitors with food preferences
- **Real-time updates**: Changes reflect immediately
- **User-friendly**: Clear table layout with icons
- **Searchable**: Find registrations quickly
- **Robust**: Handles errors and empty states gracefully

Perfect for event staff managing food distribution and tracking visitor completion! 🍽️
