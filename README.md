# 🚀 BridgeCare Launch Engine

A high-performance **Provider Onboarding & Eligibility System** built with **Rails 7**, **Vue 3**, and **Inertia.js**.

This repository serves as a technical showcase for building mission-critical childcare infrastructure with a "Senior III" architecture: scalable, auditable, and developer-friendly.

## 🏗️ Architecture at a Glance
- **Backend**: Rails 7 (Ruby 3.3+) using Service Objects for complex compliance logic.
- **Frontend**: Vue 3 (Composition API) powered by **Inertia.js** for a modern SPA experience without the API overhead.
- **Build Tool**: **Vite (ESM)** for sub-second Hot Module Replacement (HMR).
- **Database**: PostgreSQL with **JSONB** for flexible, state-level childcare licensing requirements.

## 🛠️ Key Features
- **Eligibility Engine**: A decoupled service layer that calculates provider readiness.
- **Trust-O-Meter**: A reactive UI component providing real-time feedback to providers.
- **Sittercity Legacy Integration**: Designed with the scalability lessons learned from high-volume childcare marketplaces.

---

## 📐 Architecture Decision Records (ADRs)

To ensure this engine is scalable and auditable for a high-stakes GovTech environment like **BridgeCare**, the following patterns were implemented:

### **1. Service Object Pattern (`Launch::EligibilityService`)**
* **The Decision:** Extracted business logic from the `Provider` model into a dedicated Service Object.
* **The "Why":** Eligibility rules are volatile and state-dependent. Isolation allows for testing complex logic without the "Fat Model" anti-pattern, ensuring the codebase remains maintainable as more states are onboarded.

### **2. JSONB for Compliance Data**
* **The Decision:** Utilized a PostgreSQL `jsonb` column for `compliance_data`.
* **The "Why":** Childcare requirements vary wildly by jurisdiction (e.g., CA requires specific health certifications that TX does not). A schema-less approach allows the engine to handle new regulations without frequent, disruptive database migrations.

### **3. Polymorphic Audit Logging (`ActivityLog`)**
* **The Decision:** Implemented a polymorphic `ActivityLog` to track every eligibility check.
* **The "Why":** In **Program Assurance**, "how" a decision was reached is as important as the decision itself. This provides a tamper-proof digital audit trail for state-level compliance reviews.

### **4. Defensive Logic: The "Zero-Rule" Guard**
* **The Decision:** Configured the engine to return a `100%` readiness score if no regulatory rules are defined for a specific region.
* **The "Why":** Prevents a logical contradiction where a provider is "Eligible" but displays a "0% Readiness" score, ensuring data integrity and a clear UX for newly added regions.

---

## 🚦 Getting Started
1. **Prerequisites**: Ruby 3.3, Node.js 20+, PostgreSQL.
2. **Install Dependencies**:
   ```bash
   bundle install
   yarn install
3. **Setup Database**:
   ```bash
   bin/rails db:prepare
4. **Launch Dev Server**:
   ```bash
   bin/dev

## 🧪 Testing Strategy
- **RSpec**: Business logic and Service Object verification.
- **Vitest**: Frontend component and state isolation testing.