-- 0. Add has_left column
ALTER TABLE trip_members ADD COLUMN IF NOT EXISTS has_left BOOLEAN DEFAULT FALSE;

-- 1. Create the function that will be executed by the trigger
CREATE OR REPLACE FUNCTION check_and_delete_empty_trip()
RETURNS TRIGGER AS $$
BEGIN
  -- Only trigger the check if the user is actively being marked as 'has_left = true'
  IF NEW.has_left = true AND (OLD.has_left IS NULL OR OLD.has_left = false) THEN
    
    -- Check if there are any members left in this trip where has_left is false
    IF NOT EXISTS (
      SELECT 1 
      FROM trip_members 
      WHERE trip_id = NEW.trip_id AND (has_left = false OR has_left IS NULL)
    ) THEN
      
      -- If no active members exist, delete the trip.
      -- (Assuming your tables are set up with ON DELETE CASCADE to clean up expenses/members)
      DELETE FROM trips WHERE id = NEW.trip_id;
      
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Create the trigger on the trip_members table
DROP TRIGGER IF EXISTS trigger_delete_empty_trip ON trip_members;
CREATE TRIGGER trigger_delete_empty_trip
AFTER UPDATE OF has_left ON trip_members
FOR EACH ROW
EXECUTE FUNCTION check_and_delete_empty_trip();
