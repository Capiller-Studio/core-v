# Deskbolic Core

This is the shared Rails Engine that powers the entire Deskbolic ecosystem. It contains the core business logic, models, shared services, and seeding utilities used by all applications.

## 🛠 Development Setup

We use the latest high-performance stack. Since Ruby 4.0.3 is not yet available in RVM, we have transitioned to **rbenv** as our primary manager for this project, while keeping RVM available for legacy work.

### 1. Ruby Setup (rbenv)
1. **Disable RVM by default**: Comment out RVM initialization in your terminal profiles (`~/.zshrc`, `~/.bash_profile`, etc.).
2. **Configure Shell**: Add the following to your `~/.zshrc` (or equivalent):
   ```bash
   # Rbenv Initialization
   export PATH="$HOME/.rbenv/bin:$PATH"
   eval "$(rbenv init - zsh)"
   typeset -U path

   # Legacy RVM access (for older projects)
   alias use_rvm='source "$HOME/.rvm/scripts/rvm"'
   ```
3. **Install & Use Ruby 4.0.3**:
   ```bash
   rbenv install 4.0.3
   rbenv local 4.0.3
   ```

### 2. Node.js Setup (nvm)
We require **Node v25.9.0**.
```bash
nvm install 25.9.0
nvm alias default 25.9.0
nvm use default
```

### 3. Shared Engine Installation
To use this engine in a Deskbolic application, ensure it's linked in your `Gemfile`:

```ruby
gem "core", path: "../core"
```

## 📂 Responsibilities
- **Models**: Unified data structures (Accounts, Conversations, Users, etc.)
- **Seeding**: Shared seeders for development environments.
- **Services**: Cross-app business logic (Integrations, Automation Engine).
- **Concerns**: Shared behaviors like `Addressable` and `Billable`.

---
© 2026 Techbolic Solutions (Private) Limited.
