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
