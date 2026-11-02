# Realtime Data Synchronisation Rules (Supabase Realtime)

Shared, mutable data MUST be **pushed** from the server to every running app instance
(phone, laptop, web) via **Supabase Realtime**. Do not rely on one-time fetches
(`initState` / `checkAuth`) as the only source of updates.

## 1. When Realtime is mandatory
Use a Realtime subscription for any data that another user, admin, or device can change
while the app is open, including:
- **Signed-in user's own profile & privileges** (`user_profiles`: `is_admin`, `is_moderator`,
  `is_practitioner`, `is_supplier`, `is_active`, `primary_role`). Role/permission changes
  MUST reach the affected user's open sessions without restart or re-login.
- Admin/moderation lists (user management, pending herbs/remedies/conditions, supplier &
  practitioner applications).
- Repository catalog data (herbs, conditions, remedies, research) and marketplace data
  (products, orders, payments status), telemedicine consultations, chatbot conversations.

One-time fetch is acceptable only for static/reference data that never changes at runtime.

## 2. Where subscriptions live (architecture)
- Subscriptions belong in the **data layer** (repository / remote datasource) of the owning
  feature, never inside widgets. Expose changes as a `Stream` to the BLoC/Cubit.
- One subscription per data source, shared via the domain repository/BLoC (Single Source of
  Truth — see `AGENTS.md`). Screens must not open duplicate channels for the same table.
- Prefer `.stream(primaryKey: ['id'])` for simple row/list sync; use
  `channel().onPostgresChanges(...)` when filters or event types (insert/update/delete) matter.
- Always filter to the minimum scope (e.g. `eq('id', currentUserId)` for own profile).

## 3. Lifecycle requirements
- Subscribe after sign-in; **unsubscribe/remove channel on sign-out** and in `dispose()` /
  `close()`. Re-subscribe when the authenticated user changes.
- Handle reconnects: after a channel (re)joins, refetch once to close any gap.
- Handle errors gracefully via `ErrorHandler`; never crash the UI on a dropped channel.
- If the signed-in user's privileges are revoked or `is_active` becomes false, the AuthCubit
  must emit the updated user immediately so guarded routes/consoles close or redirect.

## 4. Writes must be verified
- Mutations whose result other clients depend on must use `.select()` (or check affected
  rows) so a silent RLS rejection (0 rows updated, no error) is surfaced as a failure instead
  of a false "success" snackbar. Do not apply optimistic local state without confirmation.

## 5. Database prerequisites (requires approval — see project_engineering_rules.md)
- A table only emits Realtime events if it is in the `supabase_realtime` publication:
  `alter publication supabase_realtime add table public.<table>;`
- RLS `SELECT` policies apply to Realtime: subscribers only receive rows they may read.
- Any such migration must be added under the project's migrations/docs, explained, and
  approved before being applied.

## 6. Testing
- Unit-test repositories/Cubits with a fake stream to verify state updates on remote change,
  and that subscriptions are cancelled on sign-out/dispose.
