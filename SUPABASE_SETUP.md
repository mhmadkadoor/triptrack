# TripTrack - Supabase Setup Instructions

## 1. Create a Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Sign up for a free account
3. Click "New Project"
4. Fill in:
   - Project name: `triptrack`
   - Database password: (choose a strong password)
   - Region: (choose closest to you)
5. Click "Create new project" (takes ~2 minutes)

## 2. Get Your API Credentials

1. In your Supabase dashboard, go to **Project Settings** (gear icon)
2. Click **API** in the left sidebar
3. You'll see:
   - **Project URL** (looks like: `https://xxxxx.supabase.co`)
   - **anon/public key** (a long string starting with `eyJ...`)

## 3. Update Your Flutter App

1. Open `lib/config/supabase_config.dart`
2. Replace the placeholder values:
   ```dart
   static const String supabaseUrl = 'YOUR_PROJECT_URL_HERE';
   static const String supabaseAnonKey = 'YOUR_ANON_KEY_HERE';
   ```

## 4. Create the Database Table

1. In Supabase dashboard, go to **SQL Editor**
2. Click **New query**
3. Paste this SQL:

```sql
-- Create trips table
CREATE TABLE trips (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  destination TEXT,
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  end_date TIMESTAMP WITH TIME ZONE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security (RLS)
ALTER TABLE trips ENABLE ROW LEVEL SECURITY;

-- Create a policy that allows all operations for now
-- (In production, you'd want to add authentication and user-specific policies)
CREATE POLICY "Allow all for now" 
  ON trips 
  FOR ALL 
  USING (true) 
  WITH CHECK (true);

-- Create an index for faster queries
CREATE INDEX trips_created_at_idx ON trips (created_at DESC);
```

4. Click **Run** (or press Ctrl+Enter)
5. You should see "Success. No rows returned"

## 5. Install Dependencies

Run in your terminal:
```bash
flutter pub get
```

## 6. Run the App

### For web:
```bash
flutter run -d chrome
```

### For Android:
```bash
flutter run -d <your-device-id>
```

## 7. Test It Out

1. Click the + button to add a trip
2. Fill in the details
3. Click Save
4. The trip should appear in the list

## 8. Test Data Sync Between Web and Android

1. Add a trip on web
2. Open the Android app
3. The trip should appear there too!
4. Add/delete trips on either platform and watch them sync

## Security Notes

⚠️ **Important**: The current setup allows anyone to read/write trips. For production:

1. Enable Supabase Authentication
2. Update RLS policies to filter by `auth.uid()`
3. Add user login/signup screens

Example secure policy:
```sql
-- Only show trips created by the logged-in user
CREATE POLICY "Users can only see their own trips"
  ON trips
  FOR SELECT
  USING (auth.uid() = user_id);
```

## Troubleshooting

### "Failed to load trips" error
- Check that your Supabase URL and key are correct
- Make sure the table was created successfully
- Check the browser console for detailed errors

### Data not syncing
- Make sure both apps are using the same Supabase project
- Check that RLS policies are set correctly
- Verify internet connection

### Build errors
- Run `flutter clean` then `flutter pub get`
- Make sure you're on a recent Flutter version (3.0+)
