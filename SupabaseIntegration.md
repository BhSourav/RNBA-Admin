# Supabase Integration Guide for RNBA Admin

## Step 1: Add Supabase Swift SDK

### Option A: Swift Package Manager (Recommended)
1. Open your Xcode project
2. Go to File → Add Package Dependencies
3. Enter URL: `https://github.com/supabase/supabase-swift`
4. Select "Add Package"
5. Choose "supabase-swift" and click "Add Package"

### Option B: Manual Integration
1. Download the latest release from: https://github.com/supabase/supabase-swift/releases
2. Add the framework to your project

## Step 2: Configure Supabase Client

### Create SupabaseConfig.swift
```swift
import Foundation
import Supabase

struct SupabaseConfig {
    static let supabaseURL = "YOUR_SUPABASE_URL"
    static let supabaseKey = "YOUR_SUPABASE_ANON_KEY"
    
    static let client = SupabaseClient(
        supabaseURL: URL(string: supabaseURL)!,
        supabaseKey: supabaseKey
    )
}
```

## Step 3: Database Schema

### Create these tables in your Supabase dashboard:

#### 1. Registrations Table
```sql
CREATE TABLE registrations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    number_of_persons INTEGER NOT NULL,
    phone TEXT NOT NULL,
    email TEXT NOT NULL,
    mobile TEXT,
    address TEXT NOT NULL,
    payment_type TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 2. Person Details Table
```sql
CREATE TABLE person_details (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    registration_id UUID REFERENCES registrations(id) ON DELETE CASCADE,
    person_index INTEGER NOT NULL,
    visit_type TEXT NOT NULL,
    food_preference TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 3. Enable Row Level Security (RLS)
```sql
-- Enable RLS on both tables
ALTER TABLE registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE person_details ENABLE ROW LEVEL SECURITY;

-- Create policies (adjust based on your auth requirements)
CREATE POLICY "Allow all operations for authenticated users" ON registrations
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Allow all operations for authenticated users" ON person_details
    FOR ALL USING (auth.role() = 'authenticated');
```

## Step 4: Environment Variables

### Create a .env file (for development)
```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

### Or add to Info.plist
```xml
<key>SupabaseURL</key>
<string>your_supabase_url</string>
<key>SupabaseKey</key>
<string>your_supabase_anon_key</string>
```

## Step 5: Usage Examples

### Initialize Supabase Client
```swift
import Supabase

let supabase = SupabaseConfig.client
```

### Read Data
```swift
let response = try await supabase
    .from("registrations")
    .select()
    .execute()
```

### Write Data
```swift
let newRegistration = RegistrationData(...)
let response = try await supabase
    .from("registrations")
    .insert(newRegistration)
    .execute()
```

### Update Data
```swift
let response = try await supabase
    .from("registrations")
    .update(updatedData)
    .eq("id", value: registrationId)
    .execute()
```

### Delete Data
```swift
let response = try await supabase
    .from("registrations")
    .delete()
    .eq("id", value: registrationId)
    .execute()
```

## Step 6: Error Handling

```swift
do {
    let response = try await supabase
        .from("registrations")
        .select()
        .execute()
} catch {
    print("Error: \(error.localizedDescription)")
}
```

## Step 7: Real-time Subscriptions

```swift
let channel = supabase.realtimeV2.channel("registrations")
    .on(.postgres_changes, filter: ChannelFilter(event: .insert, schema: "public", table: "registrations")) { payload in
        print("New registration: \(payload)")
    }
    .subscribe()
```

## Security Considerations

1. **Row Level Security (RLS)**: Always enable RLS on your tables
2. **API Keys**: Never expose service role keys in client apps
3. **Authentication**: Implement proper user authentication
4. **Data Validation**: Validate data on both client and server side
5. **Rate Limiting**: Configure appropriate rate limits in Supabase

## Next Steps

1. Set up your Supabase project
2. Create the database schema
3. Configure authentication
4. Implement the data service layer
5. Test the integration
