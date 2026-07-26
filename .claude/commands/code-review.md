# Code Review Mode

Review code against senior engineering standards before submitting a PR.

## When to Use

- Before submitting a pull request
- During self-review of your changes
- When reviewing someone else's code
- After AI-assisted coding to verify quality
- Before starting implementation (internalize these standards)

## Behavior

1. **Analyze** the specified code or current changes
2. **Check** against each quality category below
3. **Report** violations with specific line numbers and fixes
4. **Score** overall code quality
5. **Block PR** if critical issues exist

---

## Quality Standards

### 🔷 JavaScript Fundamentals

#### Context & Scope
Check for:
- [ ] **Proper `this` binding** - Arrow functions for lexical `this`, regular functions when dynamic `this` needed
- [ ] **`.call()` vs `.apply()` vs `.bind()`** - Used correctly when manipulating context
- [ ] **Intentional closures** - Closures used deliberately, not accidentally capturing variables
- [ ] **No closure memory leaks** - References cleaned up on unmount

```typescript
// ❌ Accidental closure capturing stale value
useEffect(() => {
  const interval = setInterval(() => {
    console.log(count); // Stale closure!
  }, 1000);
}, []); // Missing count dependency

// ✅ Proper closure handling
useEffect(() => {
  const interval = setInterval(() => {
    setCount(c => c + 1); // Functional update
  }, 1000);
  return () => clearInterval(interval);
}, []);
```

#### Type Checks & Coercion
- [ ] **Strict equality (`===`)** - No loose equality except intentional null checks
- [ ] **`typeof` quirks handled** - Remember `typeof []` returns `'object'`
- [ ] **`Array.isArray()`** for array checks
- [ ] **Optional chaining (`?.`)** and nullish coalescing (`??`)

```typescript
// ❌ Wrong type checks
if (typeof items === 'array') // WRONG
if (value == null) // Intentional? Add comment

// ✅ Correct type checks
if (Array.isArray(items))
if (value === null || value === undefined) // Explicit
if (value == null) // OK if intentional, add comment: // checks null OR undefined
```

#### Iteration Methods
- [ ] **Correct method for use case:**
  - `for` loop: Need `break`, `return`, or `await` inside
  - `for...of`: Cleaner iteration with break/continue support
  - `forEach`: Simple sync iteration (no await!)
  - `map/filter/reduce`: Functional transformations
- [ ] **No mutation during iteration**
- [ ] **Can implement `array.map` and `array.reduce`** - Understands fundamentals

```typescript
// ❌ await in forEach - DOES NOT WORK AS EXPECTED
items.forEach(async (item) => {
  await processItem(item); // Fires all at once, doesn't wait!
});

// ✅ Sequential async processing
for (const item of items) {
  await processItem(item);
}

// ✅ Parallel async processing
await Promise.all(items.map(item => processItem(item)));
```

#### Object Handling
- [ ] **Shallow vs deep copy awareness:**
  - Shallow: `{...obj}`, `Object.assign()`, `[...arr]`
  - Deep: `structuredClone()`, or `JSON.parse(JSON.stringify())` (loses functions, dates, undefined)
- [ ] **Pass by reference understood** - Objects/arrays are references, primitives are values
- [ ] **Immutable updates** - Never mutate props or state

```typescript
// ❌ Shallow copy pitfall
const copy = {...original};
copy.nested.value = 'changed'; // MUTATES original.nested!

// ✅ Deep copy when needed
const copy = structuredClone(original);
copy.nested.value = 'changed'; // Safe

// ❌ Direct mutation
state.items.push(newItem);
user.name = 'New Name';

// ✅ Immutable updates
setState(prev => ({ ...prev, items: [...prev.items, newItem] }));
const updatedUser = { ...user, name: 'New Name' };
```

#### Prototype & Inheritance
- [ ] **Prototype chain understood** - Knows how property lookup works
- [ ] **`instanceof` vs `typeof`** - Used appropriately
- [ ] **Class vs function constructors** - Consistent pattern

#### Async Programming
- [ ] **Promise patterns correct:**
  - `async/await` for sequential
  - `Promise.all()` for parallel independent operations
  - `Promise.allSettled()` when all results needed regardless of failures
  - `Promise.race()` for timeouts
- [ ] **Event loop understood** - Knows when `setTimeout(fn, 0)` executes (after current call stack)
- [ ] **Microtasks vs macrotasks** - Promises resolve before setTimeout
- [ ] **Error handling on all async operations**

```typescript
// ❌ No error handling
const data = await fetch(url);

// ✅ Proper error handling
try {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`HTTP ${response.status}`);
  const data = await response.json();
} catch (error) {
  // Handle appropriately
}

// ❌ Sequential when could be parallel
const user = await fetchUser(id);
const posts = await fetchPosts(id);

// ✅ Parallel fetching
const [user, posts] = await Promise.all([
  fetchUser(id),
  fetchPosts(id)
]);
```

#### Design Patterns
- [ ] **Appropriate pattern usage:**
  - Factory: Complex object creation
  - Singleton: Shared instance (use sparingly)
  - Observer/Subscriber: Event-driven communication
  - Strategy: Interchangeable algorithms
- [ ] **No over-engineering** - Simple solutions preferred

---

### 🔷 TypeScript Standards

#### Type Safety
- [ ] **NO `any` in production code** - Use `unknown` with type guards if truly unknown
- [ ] **Strict mode enabled** - `"strict": true` in tsconfig
- [ ] **Explicit return types** on public/exported functions
- [ ] **No type assertions (`as`)** without explanatory comment

```typescript
// ❌ Using any
const data: any = fetchData();
const result = (response as any).data;

// ✅ Proper typing
const data: UserResponse = await fetchData();
// When assertion needed, explain why:
const element = event.target as HTMLInputElement; // Form input event
```

#### Utility Types
- [ ] **Using appropriate utility types:**

```typescript
// Partial - make all optional
type UpdateUser = Partial<User>;

// Required - make all required  
type CompleteUser = Required<User>;

// Pick - select properties
type UserName = Pick<User, 'firstName' | 'lastName'>;

// Omit - exclude properties
type UserWithoutId = Omit<User, 'id'>;

// ReturnType - extract return type
type ApiResult = ReturnType<typeof fetchData>;

// keyof - property names as union
type UserKeys = keyof User; // 'id' | 'name' | 'email'

// Record - typed object
type UserMap = Record<string, User>;
```

#### Advanced Types
- [ ] **Discriminated unions for state** - Literal type discriminators

```typescript
// ✅ Discriminated union for API state
type AsyncState<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: Error };

// TypeScript narrows type based on status check
if (state.status === 'success') {
  console.log(state.data); // TypeScript knows data exists
}
```

- [ ] **Mapped types when transforming types**
- [ ] **Conditional types** kept readable
- [ ] **Type inference preferred** when obvious

---

### 🔷 React Best Practices

#### Virtual DOM & Reconciliation
- [ ] **Key prop usage** - Stable, unique keys on lists (not index unless static)
- [ ] **Understands reconciliation** - Why keys matter for performance

#### Re-render Optimization
- [ ] **Understands what triggers re-render:**
  1. State changes
  2. Props changes  
  3. Parent re-renders
  4. Context changes

- [ ] **Knows the difference:**
  - `useMemo`: Memoize expensive computed values
  - `useCallback`: Memoize function references (for child prop stability)
  - `React.memo`: Memoize entire component (skip re-render if props unchanged)

```typescript
// ❌ useCallback without purpose
const handleClick = useCallback(() => {
  doSomething();
}, []); // Unnecessary if not passed to memoized child

// ✅ useCallback when needed
const MemoizedChild = React.memo(Child);
const handleClick = useCallback(() => {
  doSomething(id);
}, [id]); // Needed because passed to memoized component
<MemoizedChild onClick={handleClick} />

// ❌ useMemo for simple values
const doubled = useMemo(() => count * 2, [count]);

// ✅ useMemo for expensive computations
const sortedItems = useMemo(() => 
  items.slice().sort((a, b) => a.name.localeCompare(b.name)),
  [items]
);
```

#### Hooks
- [ ] **useEffect dependencies complete** - All referenced values in deps array
- [ ] **useEffect cleanup** - Return cleanup function for subscriptions/timers
- [ ] **Custom hooks for reusable logic** - Extract shared stateful logic
- [ ] **Rules of Hooks followed** - Only at top level, only in React functions

```typescript
// ❌ Missing dependency
useEffect(() => {
  fetchUser(userId);
}, []); // Missing userId!

// ✅ Complete dependencies
useEffect(() => {
  fetchUser(userId);
}, [userId]);

// ❌ Missing cleanup
useEffect(() => {
  const subscription = api.subscribe(handler);
}, []);

// ✅ Proper cleanup
useEffect(() => {
  const subscription = api.subscribe(handler);
  return () => subscription.unsubscribe();
}, [handler]);
```

#### State Management
- [ ] **State collocated** - Lives at lowest common ancestor
- [ ] **Server vs client state separated:**
  - Server state: TanStack Query, SWR (handles caching, refetching)
  - Client state: useState, Zustand, Context
- [ ] **State lifting done correctly** - Bidirectional data flow handled

```typescript
// Temperature calculator pattern - bidirectional state
// ✅ Single source of truth, derived values
const [celsius, setCelsius] = useState(0);
const fahrenheit = (celsius * 9/5) + 32; // Derived, not separate state

const handleCelsiusChange = (c: number) => setCelsius(c);
const handleFahrenheitChange = (f: number) => setCelsius((f - 32) * 5/9);
```

#### Component Patterns
- [ ] **Composition over inheritance**
- [ ] **Single responsibility** - Components do one thing
- [ ] **Props interface defined** - All props typed
- [ ] **Subcomponents organized** - Logical file/folder structure

---

### 🔷 Architecture & Scalability

#### Abstraction
- [ ] **UI kit abstraction** - Could you swap Material-UI for AntDesign?
  - Wrap library components in your own interfaces
  - Don't leak library-specific props throughout codebase

```typescript
// ❌ Library props scattered everywhere
<MuiButton variant="contained" color="primary">Save</MuiButton>

// ✅ Abstracted
// components/ui/Button.tsx
export const Button = ({ variant, ...props }) => (
  <MuiButton variant={variantMap[variant]} {...props} />
);
// Usage
<Button variant="primary">Save</Button>
```

- [ ] **API abstraction** - Backend changes shouldn't require frontend rewrites
- [ ] **Feature flag support** - Code supports gradual rollouts

#### Scalability Thinking
- [ ] **Would adding a third option be easy?** - If you have 2 of something, can you add a 3rd?
- [ ] **Configuration over hardcoding** - Use constants and config
- [ ] **DRY within reason** - Don't prematurely abstract

#### Route Protection
- [ ] **Auth checks centralized** - Route guards or protected route components
- [ ] **Redirect logic consistent** - Unauthenticated users handled uniformly

---

### 🔷 Git Practices

- [ ] **Merge vs rebase understood:**
  - Merge: Preserves history, creates merge commit
  - Rebase: Linear history, rewrites commits (don't rebase shared branches)
- [ ] **Atomic commits** - One logical change per commit
- [ ] **Meaningful messages** - Explain why, not just what
- [ ] **Conventional commits** - `feat:`, `fix:`, `refactor:`, etc.

---

### 🔷 CSS & Layout

- [ ] **Centering techniques known:**
  - Flexbox: `display: flex; justify-content: center; align-items: center;`
  - Grid: `display: grid; place-items: center;`
  - Absolute + transform for overlays
- [ ] **Layout patterns** - 3-column, responsive grids
- [ ] **Mobile-first** - Start with mobile, add breakpoints up
- [ ] **CSS variables for theming** - Enable dark mode, customization

---

### 🔷 Testing & Quality

- [ ] **Behavior tested, not implementation** - Tests shouldn't break on refactor
- [ ] **Error states covered** - Not just happy path
- [ ] **Accessibility** - Semantic HTML, ARIA where needed

---

### 🔷 Security

- [ ] **Input validation** - Zod/Yup on forms and API
- [ ] **XSS prevention** - User content sanitized
- [ ] **Secure token storage** - HttpOnly cookies preferred

---

## Output Format

```markdown
## Code Review: [File/Feature Name]

**Reviewed against**: CompStak Senior Engineering Standards
**Files analyzed**: [list]

### Critical Issues 🚩
Must fix before merge:

| Issue | Location | Category | Fix |
|-------|----------|----------|-----|
| Using `any` type | line 45 | TypeScript | Use proper interface |
| await in forEach | line 78 | Async | Use for...of loop |

### Warnings ⚠️
Should fix:

| Issue | Location | Category | Suggestion |
|-------|----------|----------|------------|
| Missing useEffect cleanup | line 23 | React | Add return cleanup |

### Suggestions 💡
Nice to have:
- Consider extracting X into custom hook
- Could use discriminated union for state

### Standards Checklist

#### JavaScript Fundamentals
- [x] Proper `this` binding
- [x] Correct iteration methods
- [ ] ⚠️ Missing error handling on fetch (line 56)

#### TypeScript
- [ ] 🚩 `any` type used (line 45)
- [x] Utility types appropriate
- [x] Return types on exports

#### React
- [x] Hook dependencies complete
- [ ] ⚠️ Missing cleanup (line 23)
- [x] No direct state mutation

#### Architecture
- [x] UI components abstracted
- [x] Feature flag ready

### Quality Score
- **Critical**: 2 issues (must fix)
- **Warnings**: 1 item
- **Ready for PR**: ❌ No - fix critical issues first

### Next Steps
1. Replace `any` with `UserResponse` interface (line 45)
2. Convert forEach to for...of for async (line 78)
3. Add useEffect cleanup (line 23)
```

## Example Usage

- `/code-review this file` → Review current file
- `/code-review the changes` → Review current changes/diff
- `/code-review DealCard component` → Review specific component
- `/code-review for TypeScript issues` → Focus on TS problems only
- `/code-review before I commit` → Full review of staged changes
