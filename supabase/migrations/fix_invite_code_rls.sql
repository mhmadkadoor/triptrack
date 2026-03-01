-- Robust 'Join Trip' function that handles everything in one go.

CREATE OR REPLACE FUNCTION join_trip_by_invite_code(invite_code_input text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  target_trip_id uuid;
  target_trip_name text;
  existing_member_id uuid;
  current_user_id uuid;
BEGIN
  -- Get current user ID
  current_user_id := auth.uid();
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- 1. Find the trip by invite code
  SELECT id, name INTO target_trip_id, target_trip_name
  FROM trips
  WHERE invite_code = invite_code_input
  LIMIT 1;

  IF target_trip_id IS NULL THEN
    RETURN json_build_object('success', false, 'message', 'Invalid invite code');
  END IF;

  -- 2. Check if already a member
  SELECT trip_id INTO existing_member_id
  FROM trip_members
  WHERE trip_id = target_trip_id AND user_id = current_user_id
  LIMIT 1;

  IF existing_member_id IS NOT NULL THEN
     RETURN json_build_object('success', false, 'message', 'Already a member');
  END IF;

  -- 3. Insert new member
  INSERT INTO trip_members (trip_id, user_id, role, exit_status)
  VALUES (target_trip_id, current_user_id, 'contributor', 'none');

  RETURN json_build_object('success', true, 'message', 'Joined ' || target_trip_name);
END;
$$;
