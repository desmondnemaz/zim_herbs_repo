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
