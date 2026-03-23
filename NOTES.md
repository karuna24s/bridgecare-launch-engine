# 📝 Project Notes & Architecture Decisions (ADR)

### Context
In the childcare sector (BridgeCare/Sittercity), "Launching" a provider involves navigating a web of state-specific licensing, background checks, and insurance verification. A rigid database schema fails here.

- **ADR 1: Inertia.js vs. GraphQL/REST**
  - **Decision**: Adopted **Inertia.js**.
  - **Reasoning**: For an internal "Onboarding Engine," the complexity of maintaining a separate API (GraphQL/REST) and client-side state (Pinia/Redux) slows down "Time to Market."
  - **Benefit**: We maintain a "Single Source of Truth" in Rails while giving the user a reactive, app-like experience in Vue.

- **ADR 2: PostgreSQL JSONB for Compliance**
  - **Decision**: Storing `compliance_data` in a JSONB column.
  - **Reasoning**: Childcare laws in NY differ from CA. Instead of a migration every time a state changes a rule, we use a flexible JSON schema validated by a Service Object.
  - **Benefit**: High agility for government-contracted launches.

- **ADR 3: Vite & ESM (.mts)**
  - **Decision**: Using `vite.config.mts`.
  - **Reasoning**: Moving to strict ECMAScript Modules (ESM) ensures the build pipeline is modern and avoids CommonJS "dependency hell."
  - **Benefit**: Faster CI/CD pipelines and better tree-shaking for frontend assets.

- **ADR 4: Service Object Pattern(`Launch::EligibilityService`)**
  - **Decision**: All eligibility logic lives in `app/services`.
  - **Reasoning**: Keeps models "Skinny" and focused on data persistence.
  - **Benefit**: Makes the core business logic 100% testable in isolation without hitting the database frequently.

---

### 🏗️ Technical Implementation Details

- **ADR 5: Vue 3 Composition API (<script setup>)**
  - **Decision**: Standardized on the `script setup` syntax for all Vue components.
  - **Reasoning**: Reduces boilerplate and improves TypeScript inference. It is the modern standard for 2026, signaling a forward-looking codebase.

- **ADR 6: Tailwind CSS for Design System**
  - **Decision**: Implemented Tailwind CSS for all UI styling.
  - **Reasoning**: Provides a "utility-first" approach that ensures the UI is responsive and consistent without maintaining massive, custom CSS files that create technical debt.

- **ADR 7: Props-Based Data Flow (Inertia)**
  - **Decision**: Passing data from Rails Controllers to Vue via Props instead of internal API fetches.
  - **Reasoning**: Eliminates the need for a complex client-side state manager (like Pinia) for initial page loads.
  - **Benefit**: Faster "First Contentful Paint" and simplified debugging.

- **ADR 8: Serialization Layer (as_json vs Blueprinter)**
  - **Decision**: Using controlled `.as_json` serialization in controllers for the MVP.
  - **Reasoning**: Prevents "Leaky Abstractions" by explicitly whitelisting attributes (e.g., `only: [:id, :status]`).
  - **Policy**: Avoids sending sensitive database timestamps or internal IDs to the client.

### 🛡️ Security & Quality Gates
- **ADR 9: Automated Security Scanning**:
  - **Decision**: Re-integrated `brakeman` and `rubocop` as pre-requisite jobs in CI.
  - **Reasoning**: For a platform handling provider PII and licensing data, automated static analysis is non-negotiable. PRs now fail if they introduce high-severity security vulnerabilities.

- **ADR 10: CI Pipeline Integrity**:
  - **Decision**: Restored actual test execution (`bin/rails test`) to replace a "no-op" echo string.
  - **Reasoning**: A "Green" build must represent verified code correctness. Executing the existing `test/` directory ensures foundations aren't broken during the Vite/Inertia transition.

### 11. CI Pipeline Hardening (Correction)
- **Observation**: The `--no-exit-on-warn` flag in Brakeman allowed security vulnerabilities to pass CI silently.
- **Decision**: Removed the flag to enforce a "Zero Warning" security policy.
- **Observation**: The command `bin/rails test test:system` was discarding the system test argument.
- **Decision**: Standardized on `bin/rails test:all` to ensure the full suite (including Capybara/System tests) is executed.
- **Reasoning**: A "Green" build must represent total system integrity, not just partial unit verification.

---

*Created by Karuna - Senior III Architect - Monday, March 23, 2026*
