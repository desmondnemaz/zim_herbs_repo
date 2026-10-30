# User Actions CRUD & Audit Attribution Specification

## 1. Executive Overview
In healthcare, herbal research, and community-contributed repositories, accountability and traceability are critical. Every persistent entity in Zim Herbs must document:
- **Authorship**: Who originally authored or created the record (`created_by`, `created_at`).
- **Modification**: Who last updated or amended the record (`updated_by`, `updated_at`).
- **Verification / Governance**: Who reviewed, verified, or approved the content (`approved_by`/`verified_by`, `approved_at`/`verified_at`), as well as any rejection reasons (`rejected_by`, `rejected_at`, `moderation_comments`).

---

## 2. Current vs. Target Audit Matrix

| Domain Entity | Table Name | `created_at` | `created_by` | `updated_at` | `updated_by` | `is_approved` | `approved_by` / `verified_by` | `approved_at` / `verified_at` | Rejection Metadata |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Remedies** | `remedies` | ✅ Supported | ⚠️ Pending DB field | ✅ Supported | ⚠️ Pending DB field | ✅ Supported | ✅ Supported (`approved_by`) | ✅ Supported (`approved_at`) | ✅ Supported (`rejected_by`, `rejected_at`, `moderation_comments`) |
| **Herbs** | `herbs` | ✅ Supported | ⚠️ Pending DB field | ✅ Supported | ⚠️ Pending DB field | ✅ Supported | ⚠️ Pending DB field | ⚠️ Pending DB field | ⚠️ Not yet tracked |
| **Conditions** | `conditions` | ✅ Supported | ⚠️ Pending DB field | ⚠️ Pending DB field | ⚠️ Pending DB field | N/A | N/A | N/A | N/A |
| **Practitioners** | `herbalist_profiles`| ✅ Supported | ✅ Implicit (`id` = `user_profiles.id`) | ✅ Supported | ⚠️ Pending DB field | ✅ Via `verification_status` | ⚠️ Pending reviewer ID | ⚠️ Pending timestamp | ⚠️ Pending rejection notes |
| **User Profiles** | `user_profiles` | ✅ Supported | ✅ Implicit (`id` = `auth.users.id`) | ✅ Supported | ⚠️ Pending modifier ID | N/A | N/A | N/A | N/A |

---

## 3. Entity Lifecycle & User Attribution Flows

### A. Herb Lifecycle
1. **Creation (Create)**:
   - Contributor or Admin fills out [add_edit_herb_page.dart](file:///d:/software_projects/flutterApps/zim_herbs_repo/lib/features/admin/herb_management/presentation/add_edit_herb_page.dart).
   - Ingests `created_by = currentUserId` and `created_at = DateTime.now()`.
   - Default `is_approved = false` for community contributions; defaults to true only if created by an Admin.
2. **Review & Verification (Update / Moderate)**:
   - Moderator opens [unverified_herbs_screen.dart](file:///d:/software_projects/flutterApps/zim_herbs_repo/lib/features/admin/moderation/presentation/screens/unverified_herbs_screen.dart) or [moderation_hub_screen.dart](file:///d:/software_projects/flutterApps/zim_herbs_repo/lib/features/admin/moderation/presentation/screens/moderation_hub_screen.dart).
   - Approving the herb sets `is_approved = true`, `verified_by = moderatorUserId`, and `verified_at = DateTime.now()`.
3. **Editing (Update)**:
   - When an existing herb is edited, sets `updated_at = DateTime.now()` and `updated_by = currentUserId`.
4. **Deletion (Delete)**:
   - Single or batch deletion executed by an Admin or Moderator via [HerbRemoteDataSource.deleteHerbsBatch](file:///d:/software_projects/flutterApps/zim_herbs_repo/lib/features/repository/herbs/data/datasources/herb_remote_datasource.dart#L332-L375).

### B. Remedy Lifecycle
1. **Creation (Create)**:
   - User submits remedy via [add_edit_remedy_page.dart](file:///d:/software_projects/flutterApps/zim_herbs_repo/lib/features/admin/remedy_management/presentation/add_edit_remedy_page.dart).
   - Ingests `created_by = currentUserId`, `created_at = DateTime.now()`, `is_approved = false`.
2. **Review & Moderation**:
   - Ingests `approved_by = moderatorUserId`, `approved_at = DateTime.now()`, `moderation_comments` on approval.
   - If rejected, sets `rejected_by = moderatorUserId`, `rejected_at = DateTime.now()`, `moderation_comments` via [ModerationRemoteDataSource.updateRemedyApproval](file:///d:/software_projects/flutterApps/zim_herbs_repo/lib/features/admin/moderation/data/datasources/moderation_remote_datasource.dart#L79-L106).
3. **Editing (Update)**:
   - Updates `updated_at = DateTime.now()` and `updated_by = currentUserId`.

---

## 4. Proposed Database Migration (Schema Additions)

> [!IMPORTANT]
> In compliance with project engineering rules, database schema modifications must be reviewed and approved prior to execution on Supabase.

```sql
-- 1. Add audit attribution columns to 'herbs'
ALTER TABLE public.herbs
  ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS verified_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS moderation_notes TEXT;

-- 2. Add creator and modifier attribution to 'remedies'
ALTER TABLE public.remedies
  ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL;

-- 3. Add reviewer attribution to 'herbalist_profiles'
ALTER TABLE public.herbalist_profiles
  ADD COLUMN IF NOT EXISTS verified_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS moderation_notes TEXT;

-- 4. Create foreign key relationship indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_herbs_created_by ON public.herbs(created_by);
CREATE INDEX IF NOT EXISTS idx_herbs_verified_by ON public.herbs(verified_by);
CREATE INDEX IF NOT EXISTS idx_remedies_created_by ON public.remedies(created_by);
CREATE INDEX IF NOT EXISTS idx_remedies_approved_by ON public.remedies(approved_by);
```

---

## 5. Architectural Implementation Plan in Dart Layer

1. **Domain Layer**:
   - Extend `Herb` in `lib/features/repository/herbs/domain/entities/herb.dart`:
     - Add `String? createdBy`, `String? updatedBy`, `String? verifiedBy`, `DateTime? verifiedAt`, `String? moderationNotes`.
   - Extend `Remedy` in `lib/features/repository/remedies/domain/entities/remedy.dart`:
     - Add `String? createdBy`, `String? updatedBy`.
2. **Data Layer**:
   - Update `HerbModel` and `RemedyModel` `fromJson` / `toJson` methods to parse and persist these attribution fields.
   - Update `HerbRemoteDataSource` and `RemedyRemoteDataSource` to include `created_by: currentUserId` on insert and `updated_by: currentUserId` on update.
   - Update `ModerationRemoteDataSource.updateHerbApproval` and `updateHerbVerification` to pass `verified_by: moderatorId` and `verified_at: DateTime.now()`.
3. **Presentation Layer**:
   - In `add_edit_herb_page.dart` and `add_edit_remedy_page.dart`, retrieve `currentUserId` from `context.read<AuthCubit>().state.user.id` and pass into the create/update payloads.
   - In moderation screens, show who submitted the item ("Submitted by [Name]") and who verified it ("Verified by [Name] on [Date]").
