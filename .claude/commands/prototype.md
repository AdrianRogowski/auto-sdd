# Prototype Mode

Skip the specs workflow for rapid prototyping. Use when exploring ideas quickly or building throwaway proof-of-concepts.

## Behavior

- Do NOT create feature specs
- Do NOT write tests
- Do NOT update documentation
- Use mock/hardcoded data where needed
- Add `// TODO: Add specs and tests` comments (or equivalent for your language) to mark unfinished work
- Keep code isolated so it's easy to delete or formalize later

## Guidelines

1. **Speed over quality** - Get something working fast
2. **Isolation** - Don't deeply integrate with existing code
3. **Mark it** - Use TODO comments so we remember to formalize
4. **Disposable** - Be ready to throw it away

## When Done

If the prototype is approved and should become production code, tell me:
- "formalize this" or
- "make this production ready" or
- Use the `/formalize` command

I'll then create the feature spec, write proper tests, and document everything.

## Example Usage

User: "/prototype a data processing pipeline"

I will:
1. Create a quick implementation with hardcoded/mock data
2. Skip all specs and tests
3. Add TODO comments
4. Show you a working prototype fast

