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