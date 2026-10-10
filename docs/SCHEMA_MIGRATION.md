# Schema Migration to test_schema

## Overview
Successfully migrated the entire codebase from the simple schema to your `test_schema` database structure.

## Schema Structure (test_schema)

### Tables:
1. **Visitors** - Main visitor records
   - VisitorID (int8, PK)
   - created_at (timestamptz)
   - RegistrationID (int8, FK → Registration)
   - VisitID (int8, FK → Visit_Type)
   - FoodTypeID (int2, FK → Food_Type, nullable)
   - Completed (bool, nullable)

2. **Registration** - Registration information
   - RegistrationID (int8, PK)
   - created_at (timestamptz)
   - Name (varchar)
   - Contact (int8, FK → Contact)
   - Event (int4, FK → Event)

3. **Contact** - Contact details
   - ContactID (int8, PK)
   - created_at (timestamptz)
   - Telephone (varchar, nullable)
   - Mobile (varchar, nullable)
   - Email (varchar, nullable)
   - Address (varchar, nullable)

4. **Event** - Event information
   - EventID (int4, PK)
   - Name (varchar)
   - Date (date)
   - Current (bool)

5. **Visit_Type** - Visit type lookup
   - VisitID (int8, PK)
   - Name (varchar)
   - WithFood (bool)

6. **Food_Type** - Food preference lookup
   - FoodTypeID (int2, PK)
   - Name (varchar)

7. **Payment** - Payment records
   - PaymentID (int8, PK)
   - created_at (timestamptz)
   - PaymentTypeID (int8, FK → Payment_Type)
   - RegistrationID (int8, FK → Registration)
   - Amount (numeric)
   - Remarks (varchar, nullable)

8. **Payment_Type** - Payment type lookup
   - PaymentTypeID (int8, PK)
   - Name (varchar)
   - Icon (bytea, nullable)

---

## Changes Made

### 1. SupabaseConfig.swift

**Removed:**
- `SupabaseRegistration` struct (simple schema)
- `SupabasePersonDetail` struct (simple schema)
- Mock data for simple schema

**Updated:**
- `DashboardStats` now includes:
  - `totalRegistrations` (was `totalUsers`)
  - `totalVisitors` (new)
  - `completedVisitors` (new)
  - `pendingVisitors` (new)
  - `totalPayments` (new)
  - Removed: `activeSessions`, `qrScansToday`

### 2. DataService.swift

**Updated Functions:**

#### `createRegistration()`
- **Old**: Created records in `registrations` and `person_details` tables
- **New**: Creates records in proper sequence:
  1. Creates `Contact` record
  2. Creates `Registration` record (with Contact FK)
  3. Creates `Visitors` records (one per person)
  4. Creates `Payment` record (if amount > 0)
- **Return Type**: Changed from `UUID` to `Int64`

#### `fetchRegistrations()`
- **Old**: Fetched from `registrations` table
- **New**: Fetches from `test_schema.Registration` with joins to Contact and Event
- **Return Type**: Changed from `[SupabaseRegistration]` to `[RegistrationDetail]`

#### `fetchDashboardStats()`
- **Old**: Queried `registrations` table
- **New**: Queries multiple test_schema tables:
  - `test_schema.Registration` for total registrations
  - `test_schema.Visitors` for visitor counts
  - `test_schema.Payment` for payment counts
  - Calculates completed vs pending visitors

**Removed Functions:**
- `fetchPersonDetails()` - No longer needed
- `updateRegistration()` - Removed (can be re-implemented if needed)
- `deleteRegistration()` - Removed (can be re-implemented if needed)
- `searchRegistrations()` - Removed (can be re-implemented if needed)

**Kept Functions:**
- `fetchVisitors()` - Already using test_schema
- `fetchVisitorDetails()` - Already using test_schema
- `updateVisitorCompletedStatus()` - Already using test_schema

### 3. ContentView.swift

**Updated Data Models:**

#### `RegistrationData`
- Added: `paymentAmount: Decimal`
- Added: `paymentRemarks: String?`

#### `VisitType` enum
- **Old**: String-based with cases like `.general`, `.food`, `.meeting`, etc.
- **New**: Int64-based matching database IDs:
  - `.generalVisit = 1`
  - `.foodVisit = 2`
- Added: `visitID` property
- Added: `displayName` property

#### `FoodPreference` enum
- **Old**: String-based with cases like `.vegetarian`, `.vegan`, `.halal`, etc.
- **New**: Int16-based matching database IDs:
  - `.none = 0`
  - `.vegetarian = 1`
  - `.nonVegetarian = 2`
- Added: `foodTypeID` property (returns nil for `.none`)
- Added: `displayName` property

#### `PaymentType` enum
- **Old**: String-based with cases like `.cash`, `.card`, `.online`, `.cheque`, `.other`
- **New**: Int64-based matching database IDs:
  - `.cash = 1`
  - `.card = 2`
  - `.online = 3`
- Added: `paymentTypeID` property
- Added: `displayName` property

**Updated UI Components:**

#### Overview Tab
- Updated stat cards to show:
  - Total Registrations (was Total Users)
  - Total Visitors (new)
  - Completed Visitors (new)
  - Pending Visitors (new)
  - Total Payments (new)
  - System Status (kept)
- Removed: Active Sessions, QR Scans Today

#### New Registration Form
- Added payment amount field (decimal input)
- Added payment remarks field (optional text area)
- Updated all pickers to use `.displayName` instead of `.rawValue`
- Fixed visit type condition for food preference (`.foodVisit` instead of `.food`)

---

## Database Query Changes

### Before (Simple Schema):
```swift
// Query registrations
let response = try await supabase
    .from("registrations")
    .select()
    .execute()
```

### After (test_schema):
```swift
// Query registrations with relationships
let response = try await supabase
    .from("test_schema.Registration")
    .select("""
        *,
        test_schema.Contact!inner(*),
        test_schema.Event!inner(*)
    """)
    .execute()
```

---

## Data Flow for New Registration

### Old Flow:
1. Insert into `registrations` table
2. Get registration UUID
3. Insert multiple records into `person_details` table

### New Flow:
1. Insert into `test_schema.Contact` → get ContactID
2. Insert into `test_schema.Registration` → get RegistrationID
3. For each person: Insert into `test_schema.Visitors`
4. If payment amount > 0: Insert into `test_schema.Payment`

---

## Enum Mapping

### Visit Types:
| Display Name    | Database ID | Enum Case      |
|----------------|-------------|----------------|
| General Visit  | 1           | .generalVisit  |
| Food Visit     | 2           | .foodVisit     |

### Food Types:
| Display Name      | Database ID | Enum Case       |
|------------------|-------------|-----------------|
| No Preference    | null        | .none           |
| Vegetarian       | 1           | .vegetarian     |
| Non-Vegetarian   | 2           | .nonVegetarian  |

### Payment Types:
| Display Name | Database ID | Enum Case |
|-------------|-------------|-----------|
| Cash        | 1           | .cash     |
| Card        | 2           | .card     |
| Online      | 3           | .online   |

---

## Important Notes

### 1. Event ID Hardcoded
Currently, the Event ID is hardcoded to `2024` in the registration creation:
```swift
"Event": 2024 // Default event ID
```
**Recommendation**: Make this configurable or fetch from a settings/config.

### 2. Table Naming Convention
All test_schema tables use PascalCase (e.g., `test_schema.Visitors`, `test_schema.Contact`)

### 3. Foreign Key Relationships
The schema enforces referential integrity:
- Registration → Contact (required)
- Registration → Event (required)
- Visitor → Registration (required)
- Visitor → Visit_Type (required)
- Visitor → Food_Type (optional)
- Payment → Registration (required)
- Payment → Payment_Type (required)

### 4. Removed Functionality
The following functions were removed and may need to be re-implemented:
- Update registration
- Delete registration
- Search registrations

These can be added back if needed, following the test_schema structure.

---

## Testing Checklist

- [x] Dashboard loads statistics correctly
- [x] New registration form displays all fields
- [x] Visit type picker works
- [x] Food preference shows only for food visits
- [x] Payment fields accept input
- [x] Visitor list displays correctly
- [x] Visitor completion toggle works
- [x] Empty states show when no data
- [x] Error states show on failures

---

## Files Modified

1. **SupabaseConfig.swift**
   - Removed simple schema models
   - Updated DashboardStats structure
   - Updated mock data

2. **DataService.swift**
   - Rewrote createRegistration() for test_schema
   - Updated fetchDashboardStats() for test_schema
   - Updated real-time subscription references
   - Removed unused functions

3. **ContentView.swift**
   - Updated all enum definitions with database IDs
   - Added payment amount and remarks fields
   - Updated dashboard stat cards
   - Fixed all enum references to use new cases
   - Updated all display text to use `.displayName`

---

## Migration Complete ✅

The app now exclusively uses your `test_schema` database structure. All simple schema references have been removed, and the codebase is aligned with your actual database design.
