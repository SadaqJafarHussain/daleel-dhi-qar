import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL              = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

const cors = {
  'Access-Control-Allow-Origin':  '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { ...cors, 'Content-Type': 'application/json' },
  })

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })

  try {
    // ── Parse & validate body ───────────────────────────────────────────────
    const { request_id, new_password } = await req.json()

    if (!request_id || !new_password) {
      return json({ error: 'request_id and new_password are required' }, 400)
    }
    if (typeof new_password !== 'string' || new_password.length < 8) {
      return json({ error: 'Password must be at least 8 characters' }, 400)
    }

    // ── Verify caller is authenticated ──────────────────────────────────────
    const authHeader = req.headers.get('Authorization')
    if (!authHeader?.startsWith('Bearer ')) {
      return json({ error: 'Missing Authorization header' }, 401)
    }
    const callerJwt = authHeader.slice(7)

    const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    const { data: { user: caller }, error: authErr } =
      await adminClient.auth.getUser(callerJwt)

    if (authErr || !caller) return json({ error: 'Invalid or expired token' }, 401)

    // ── Verify caller has admin role ────────────────────────────────────────
    const { data: callerProfile } = await adminClient
      .from('profiles')
      .select('role')
      .eq('id', caller.id)
      .maybeSingle()

    if (callerProfile?.role !== 'admin') {
      return json({ error: 'Forbidden: admin role required' }, 403)
    }

    // ── Fetch the reset request ─────────────────────────────────────────────
    const { data: request } = await adminClient
      .from('password_reset_requests')
      .select('id, user_id, phone, name, status')
      .eq('id', request_id)
      .maybeSingle()

    if (!request)              return json({ error: 'Reset request not found' }, 404)
    if (request.status !== 'pending') return json({ error: 'Request is not pending' }, 400)

    // ── Reset the user's password via Admin API ─────────────────────────────
    const { error: resetErr } = await adminClient.auth.admin.updateUserById(
      request.user_id,
      { password: new_password }
    )

    if (resetErr) {
      console.error('Password reset failed:', resetErr)
      return json({ error: resetErr.message }, 500)
    }

    // ── Mark request resolved ───────────────────────────────────────────────
    await adminClient
      .from('password_reset_requests')
      .update({
        status:      'resolved',
        resolved_at: new Date().toISOString(),
        resolved_by: caller.id,
      })
      .eq('id', request_id)

    // ── Notify the user ─────────────────────────────────────────────────────
    await adminClient.from('notifications').insert({
      user_id:  request.user_id,
      type:     'system',
      title:    'تم إعادة تعيين كلمة المرور',
      body:     'تم إعادة تعيين كلمة مرورك من قِبل فريق الدعم الفني. يمكنك الآن تسجيل الدخول بكلمة المرور الجديدة. يُرجى تغييرها فوراً من إعدادات حسابك لضمان الأمان.',
      data:     { type: 'password_reset' },
      is_read:  false,
    })

    return json({ ok: true })
  } catch (e) {
    console.error('Unexpected error:', e)
    return json({ error: String(e) }, 500)
  }
})
