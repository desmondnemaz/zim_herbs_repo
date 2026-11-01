# Zim Herbs Architecture Rules

## Domain Architecture Principles
The application is structured into 5 core domain features under `lib/features/`:

1. **Repository Domain (`features/repository/`)**:
   - Owns herbs, conditions, treatments, and research.
   - Contains domain models, data repositories, BLoCs, and UI components for repository features.

2. **Marketplace Domain (`features/marketplace/`)**:
   - Owns products, store items, orders, and payments.

3. **Telemedicine Domain (`features/telemedicine/`)**:
   - Owns consultations and practitioners.

4. **AI Chatbot Domain (`features/chatbot/`)**:
   - Owns conversations, prompts, and AI interactions.

5. **Administration Domain (`features/admin/`)**:
   - Owns management features (dashboard, herb_management, user_management, reports, analytics).

## Feature Independence & Logic Sharing
- **Feature Independence**: Each feature owns its models, repository, BLoC, and UI.
- **Single Source of Truth**: Do not duplicate business logic. If two screens (e.g. User Herbs list and Admin Herb Management) share the same underlying data, they MUST share the same domain repository and BLoC/Cubit whenever possible.

## CRUD Actions & Audit Attribution Rules
All mutable repository records (herbs, remedies, conditions, profiles) must maintain strict user traceability:
- **`created_by` & `created_at`**: Set when the entity is first inserted; must record the contributing user's ID.
- **`updated_by` & `updated_at`**: Set on every update action; records who last altered the record.
- **`verified_by` / `approved_by` & `verified_at` / `approved_at`**: Set when a moderator or administrator validates or rejects unverified user submissions.
- For complete schema specifications, lifecycle flows, and database migration SQL, refer to [audit_crud_traceability.md](file:///d:/software_projects/flutterApps/zim_herbs_repo/docs/audit_crud_traceability.md).

## Responsive Navigation & Header Architecture Rules (Public App & Admin Console)
To preserve visual consistency, responsive design tokens, and smooth back-stack handling across both the Public App and Admin Console:

1. **Top Navigation AppBar (`AppPageAppBar`)**:
   - All mobile screens, pushed routes, and standalone pages MUST use [AppPageAppBar](file:///d:/software_projects/flutterApps/zim_herbs_repo/lib/core/components/app_page_app_bar.dart) instead of raw `AppBar`.
   - On responsive screens where the top bar is only needed on mobile/tablet viewports, suppress the bar on desktop (`appBar: Responsive.isDesktop(context) ? null : AppPageAppBar(...)`) or pass the contextual `onBack` callback.
   - Pushed detail and form routes must maintain primary theme branding, high-contrast actions, and contextual pop handling via `AppPageAppBar`.

2. **Body Surface Header (`AppPageHeader`)**:
   - Every primary domain screen (e.g. catalog lists, feature dashboards, management screens) across both the Public App and Admin Console MUST use [AppPageHeader](file:///d:/software_projects/flutterApps/zim_herbs_repo/lib/core/components/app_page_header.dart) at the top of the body.
   - Must supply:
     - `icon`: Domain-specific icon (e.g. `Icons.local_florist_rounded` for Herbs, `Icons.monitor_heart_outlined` for Conditions, `Icons.healing_rounded` for Remedies, `Icons.storefront_rounded` for Store).
     - `title`: Primary domain title.
     - `subtitle`: Concise explanatory text describing the purpose of the screen.
     - `onBack`: Desktop back navigation callback (enables the inline desktop back button when a parent route or overview is available).
     - `trailing`: Place view switchers, filter/export menus, or action buttons inside `trailing` to maintain an organized header row.

3. **No Ad-Hoc Header Reimplementation**:
   - Do NOT create bespoke `Container` or `Row` title headers. Always reuse [AppPageHeader](file:///d:/software_projects/flutterApps/zim_herbs_repo/lib/core/components/app_page_header.dart) and [AppPageAppBar](file:///d:/software_projects/flutterApps/zim_herbs_repo/lib/core/components/app_page_app_bar.dart) to ensure identical typography, icon sizing, colors, and accessibility.

