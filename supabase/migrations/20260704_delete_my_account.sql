-- Function: delete_my_account
-- Allows authenticated users to permanently delete their own account and all associated data.
-- Runs with SECURITY DEFINER so it can delete from auth.users.

CREATE OR REPLACE FUNCTION public.delete_my_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _uid uuid := auth.uid();
BEGIN
  IF _uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Remove FCM tokens
  DELETE FROM public.fcm_tokens WHERE user_id = _uid;

  -- Remove favorites
  DELETE FROM public.favorites WHERE user_id = _uid;

  -- Remove notifications
  DELETE FROM public.notifications WHERE user_id = _uid;

  -- Remove reviews
  DELETE FROM public.reviews WHERE user_id = _uid;

  -- Remove reports filed by this user
  DELETE FROM public.reports WHERE reporter_id = _uid;

  -- Remove verification requests
  DELETE FROM public.verification_requests WHERE user_id = _uid;

  -- Delete service images from services owned by this user (orphan cleanup)
  -- Then delete the services themselves
  DELETE FROM public.services WHERE user_id = _uid;

  -- Delete profile
  DELETE FROM public.profiles WHERE id = _uid;

  -- Finally delete the auth user (requires SECURITY DEFINER)
  DELETE FROM auth.users WHERE id = _uid;
END;
$$;

-- Grant execute to authenticated users only
REVOKE ALL ON FUNCTION public.delete_my_account() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_my_account() TO authenticated;
