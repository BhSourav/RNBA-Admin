# Overview Tab - Interactive Dashboard Design

## Overview
The Overview tab has been redesigned to show **today's statistics** with **interactive cards** that toggle between primary and secondary metrics.

## Card Layout (6 Cards in 2x3 Grid)

### 1. **Registrations Today** (Interactive)
- **Primary**: Total registrations created today
- **Secondary** (on tap): Number of registrations with visitors left to visit
- **Icon**: `person.text.rectangle.fill`
- **Color**: Blue
- **Logic**: 
  - Counts registrations where `created_at >= today`
  - "Left to visit" = unique registration IDs with at least one incomplete visitor

### 2. **Visitors Today** (Interactive)
- **Primary**: Total visitors created today
- **Secondary** (on tap): Number of visitors who haven't visited yet
- **Icon**: `person.3.fill`
- **Color**: Green
- **Logic**:
  - Counts all visitors where `created_at >= today`
  - "Left to visit" = visitors where `Completed = false`

### 3. **Non-Veg Visitors** (Interactive)
- **Primary**: Total non-veg visitors today
- **Secondary** (on tap): Non-veg visitors who haven't eaten yet
- **Icon**: `fork.knife`
- **Color**: Red
- **Logic**:
  - Counts visitors where `FoodTypeID = 2` (Non-Veg)
  - "Left to eat" = non-veg visitors where `Completed = false`

### 4. **Veg Visitors** (Interactive)
- **Primary**: Total veg visitors today
- **Secondary** (on tap): Veg visitors who haven't eaten yet
- **Icon**: `leaf.fill`
- **Color**: Green
- **Logic**:
  - Counts visitors where `FoodTypeID = 1` (Veg)
  - "Left to eat" = veg visitors where `Completed = false`

### 5. **Spot Registration - Veg** (Static)
- **Value**: Count of spot registrations with veg food
- **Icon**: `person.badge.plus`
- **Color**: Mint
- **Logic**:
  - Visitors with `FoodTypeID = 1` from today's registrations

### 6. **Spot Registration - Non-Veg** (Static)
- **Value**: Count of spot registrations with non-veg food
- **Icon**: `person.badge.plus`
- **Color**: Orange
- **Logic**:
  - Visitors with `FoodTypeID = 2` from today's registrations

## Interactive Card Behavior

### Visual Feedback
- **Tap Animation**: Spring animation (0.3s response, 0.7 damping)
- **Toggle Indicator**: Chevron icon (up/down) in top-right corner
- **Border Highlight**: Colored border appears when showing secondary value
- **Number Transition**: Smooth numeric text transition

### User Experience
1. User taps on any interactive card (cards 1-4)
2. Card animates and flips to show secondary metric
3. Border highlights in the card's color
4. Chevron icon rotates to indicate state
5. Tap again to return to primary metric

### Accessibility
- VoiceOver announces both primary and secondary values
- Hint text: "Tap to toggle between [primary] and [secondary]"
- All cards are keyboard navigable

## Data Flow

### Database Queries (DashboardService)

```swift
// 1. Get today's date range
let today = calendar.startOfDay(for: Date())
let todayISO = ISO8601DateFormatter().string(from: today)

// 2. Fetch today's registrations
.from("test_schema.Registration")
.select("RegistrationID")
.gte("created_at", value: todayISO)

// 3. Fetch today's visitors with food types
.from("test_schema.Visitors")
.select("*")
.gte("created_at", value: todayISO)

// 4. Filter and calculate metrics
- Visitors left to visit: filter { !$0.completed }
- Non-veg visitors: filter { $0.foodTypeID == 2 }
- Veg visitors: filter { $0.foodTypeID == 1 }
- Spot registrations: match visitors to today's registrations
```

## DashboardStats Model

```swift
struct DashboardStats: Codable {
    // Registration stats
    let totalRegistrationsToday: Int
    let registrationsLeftToVisit: Int
    
    // Visitor stats
    let totalVisitorsToday: Int
    let visitorsLeftToVisit: Int
    
    // Food stats
    let nonVegVisitors: Int
    let nonVegLeftToEat: Int
    let vegVisitors: Int
    let vegLeftToEat: Int
    
    // Spot registration stats
    let spotRegistrationVeg: Int
    let spotRegistrationNonVeg: Int
    
    let systemStatus: String
}
```

## UI Components

### InteractiveStatCard
New component in `SharedComponents.swift`:
- Toggles between two states
- Animated transitions
- Visual indicators (chevron, border)
- Accessibility support

### StatCard
Existing component for static cards:
- Used for spot registration cards (5 & 6)
- No interaction, just display

## Header

- **Title**: "Today's Overview"
- **Subtitle**: Full date (e.g., "Tuesday, October 14, 2025")
- **Dynamic**: Updates automatically based on current date

## Mock Data (Preview Mode)

```swift
static let mockDashboardStats = DashboardStats(
    totalRegistrationsToday: 45,
    registrationsLeftToVisit: 12,
    totalVisitorsToday: 128,
    visitorsLeftToVisit: 23,
    nonVegVisitors: 76,
    nonVegLeftToEat: 15,
    vegVisitors: 52,
    vegLeftToEat: 8,
    spotRegistrationVeg: 18,
    spotRegistrationNonVeg: 27,
    systemStatus: "Online"
)
```

## Key Features

### ✅ Real-time Today's Data
- All metrics filtered by `created_at >= start of today`
- Automatically resets at midnight

### ✅ Interactive Cards
- First 4 cards toggle between total and remaining
- Smooth animations and visual feedback
- Clear indicators of interactivity

### ✅ Food Type Tracking
- Separate cards for veg and non-veg
- Track who has eaten vs. who hasn't
- Useful for meal planning

### ✅ Spot Registration Tracking
- Identify same-day registrations
- Separate counts for veg/non-veg
- Helps with on-the-spot management

### ✅ Accessibility
- Full VoiceOver support
- Clear labels and hints
- Keyboard navigation

## Performance Considerations

### Single Query Optimization
- Fetch all today's visitors once
- Filter in memory for different metrics
- Reduces database round trips

### Caching
- Stats are cached in `@State`
- Pull-to-refresh to update
- Auto-refresh on tab appear

## Future Enhancements

### Possible Additions
1. **Time-based breakdown**: Morning vs. afternoon stats
2. **Trend indicators**: Up/down arrows compared to yesterday
3. **Goal tracking**: Progress bars for expected vs. actual
4. **Quick actions**: Tap card to filter visitor list
5. **Export**: Share today's summary as PDF/image
6. **Notifications**: Alert when food is running low

### Advanced Features
1. **Historical comparison**: Compare with previous days
2. **Peak time analysis**: Busiest hours of the day
3. **Food waste tracking**: Ordered vs. consumed
4. **Live updates**: Real-time refresh via Supabase Realtime

## Testing Checklist

- [x] Cards display correct values
- [x] Interactive cards toggle on tap
- [x] Animations are smooth
- [x] Border highlights appear correctly
- [x] Chevron icons rotate
- [x] Date displays correctly
- [x] Pull-to-refresh works
- [x] Error states show properly
- [x] Loading states work
- [x] Mock data works in preview mode
- [x] Accessibility labels are correct
- [x] VoiceOver navigation works

## Files Modified

1. **SupabaseConfig.swift**
   - Updated `DashboardStats` model
   - Updated mock data

2. **DashboardService.swift**
   - Rewrote `fetchDashboardStats()` for today's data
   - Added filtering logic for food types
   - Added spot registration calculation

3. **OverviewTabView.swift**
   - Updated to use `InteractiveStatCard`
   - Changed header to "Today's Overview"
   - Added formatted date display
   - Updated all 6 cards with new metrics

4. **SharedComponents.swift**
   - Added `InteractiveStatCard` component
   - Implemented toggle animation
   - Added visual indicators

## Summary

The Overview tab now provides a **comprehensive, interactive dashboard** for today's event management:

- **Quick glance**: See total numbers at a glance
- **Detailed view**: Tap to see remaining/pending counts
- **Food management**: Track veg/non-veg separately
- **Spot registrations**: Identify same-day sign-ups
- **User-friendly**: Smooth animations and clear indicators
- **Accessible**: Full support for assistive technologies

Perfect for event administrators who need real-time insights into today's activities! 🎉
