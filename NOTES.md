# 📝 Project Notes & Architecture Decisions (ADR)

## Context
In the childcare sector (BridgeCare/Sittercity), "Launching" a provider involves navigating a web of state-specific licensing, background checks, and insurance verification. A rigid database schema fails here.

## ADR 1: Inertia.js vs. GraphQL/REST
- **Decision**: Adopted **Inertia.js**.
- **Reasoning**: For an internal "Onboarding Engine," the complexity of maintaining a separate API (GraphQL/REST) and client-side state (Pinia/Redux) slows down "Time to Market."
- **Benefit**: We maintain a "Single Source of Truth" in Rails while giving the user a reactive, app-like experience in Vue.

## ADR 2: PostgreSQL JSONB for Compliance
- **Decision**: Storing `compliance_data` in a JSONB column.
- **Reasoning**: Childcare laws in NY differ from CA. Instead of a migration every time a state changes a rule, we use a flexible JSON schema validated by a Service Object.
- **Benefit**: High agility for government-contracted launches.

## ADR 3: Vite & ESM (.mts)
- **Decision**: Using `vite.config.mts`.
- **Reasoning**: Moving to strict ECMAScript Modules (ESM) ensures the build pipeline is modern and avoids CommonJS "dependency hell."
- **Benefit**: Faster CI/CD pipelines and better tree-shaking for frontend assets.

## ADR 4: Service Object Pattern (`Launch::EligibilityService`)
- **Decision**: All eligibility logic lives in `app/services`.
- **Reasoning**: Keeps models "Skinny" and focused on data persistence.
- **Benefit**: Makes the core business logic 100% testable in isolation without hitting the database frequently.

---
*Created by Karuna - Senior III Architect - Sunday, March 22, 2026*