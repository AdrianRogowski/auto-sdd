# Security Learnings

Security patterns for this codebase.

---

## Authentication

### [Starter] Server-side session verification required
All authenticated routes must verify the session server-side. Never trust client-provided auth state (cookies, localStorage tokens) without server validation. Framework middleware should handle this — don't implement per-route.
Category: Auth | CWE-287

### [Starter] Passwords and tokens never in plaintext
Passwords must be hashed (bcrypt, argon2) before storage. API tokens must be stored encrypted or hashed. Never log passwords, tokens, or session IDs — even at debug level.
Category: Auth | CWE-256

---

## Cookies & Tokens

### [Starter] Session cookies: httpOnly + Secure + SameSite
Session tokens must use `httpOnly` (no JavaScript access), `Secure` (HTTPS only), and `SameSite=Strict` or `SameSite=Lax` (CSRF mitigation). Don't roll your own session management when the framework provides it.
Category: Session | CWE-614

---

## Input Validation

### [Starter] Parameterized queries only — no string interpolation
All database queries must use parameterized/prepared statements. Never interpolate user input into SQL strings. ORMs (Prisma, Drizzle, etc.) handle this by default — don't bypass them with raw queries unless parameterized.
Category: Input Validation | CWE-89

### [Starter] Validate file uploads before processing
File uploads must be validated for type (MIME + extension), size (enforce max), and content before processing. Don't trust the client-provided Content-Type header.
Category: Input Validation | CWE-434

---

## API Security

### [Starter] Credentials in environment variables only
API keys, database URLs, and secrets must come from environment variables. Never hardcode credentials in source files, even for development. Use `.env.local` (gitignored) for local dev.
Category: Secrets | CWE-798

### [Starter] Error responses must not leak internals
API error responses must never include stack traces, internal file paths, database schema details, or raw error messages from dependencies. Return user-friendly error messages with appropriate HTTP status codes.
Category: Error Handling | CWE-209

### [Starter] CSRF protection on state-changing endpoints
All POST/PUT/DELETE/PATCH endpoints that modify state need CSRF protection. Use the framework's built-in CSRF middleware, not a custom implementation.
Category: API Security | CWE-352

---

## Secrets Management

### [Starter] No secrets in git history
If a secret is accidentally committed, it must be rotated immediately — removing it from git history alone is not sufficient. Use pre-commit hooks (e.g., `detect-secrets`, `gitleaks`) to prevent this.
Category: Secrets | CWE-540
