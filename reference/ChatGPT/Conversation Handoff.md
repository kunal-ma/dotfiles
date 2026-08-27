# Conversation Handoff

> Generate a complete, standalone checkpoint of the current conversation for a new AI agent that has no access to the original conversation. The checkpoint is **not a summary**. It is a compressed serialization of the conversation's working state. Preserve every piece of information that could affect the next agent's response, while removing redundancy. Optimize for **semantic compression, not omission**.

## 1. Conversation State

Capture the conversation as it currently stands:

- **Overview:** what the conversation is about, what has been accomplished, the current objective, and the immediate next step.
- **Completed:** decisions, work, explanations, conclusions, and questions already resolved.
- **In progress:** active work and reasoning.
- **Pending:** unfinished work, decisions, confirmations, questions, blockers, and dependencies.
- **Stopping point:** exactly where the conversation ended and what the next agent should do.

## 2. User Model

Include only information established by the conversation. **Never invent facts.**

Separate:

**Explicit**

- Goals, expertise, preferences, dislikes, priorities, constraints, expectations.

**Observed**

- Communication and decision-making style, preferred detail, formatting, tone, uncertainty tolerance, recurring patterns.

**Inferred**

- Broader goals, hidden constraints, optimization criteria, or preferences. Clearly label every inference as *inferred* and distinguish it from fact.

## 3. Knowledge & Context

Preserve all information that may influence future responses:

- Facts, conclusions, definitions, terminology, conventions, examples, references, explanations, assumptions, and context dependencies.
- For important items, capture *what it is, why it mattered, and whether it remains relevant*.
- Preserve project names, variables, abbreviations, shorthand, and custom terminology with their meanings.

## 4. Reasoning & Decisions

For every significant decision, preserve the reasoning rather than only the result:

- Problem or objective
- Alternatives considered
- Relevant tradeoffs
- Decision
- Why it was chosen
- Assumptions
- Remaining uncertainty

Preserve *why*, not merely *what*.

## 5. Intent

Separate:

**Explicit intent**

- Current request
- Immediate objective

**Inferred intent**

- Broader/long-term objective
- Hidden constraints
- Optimization criteria
- What the user appears to value

Clearly label all inference.

## 6. Response Specification

Describe how the next agent should respond based on demonstrated preferences:

- Tone and formality
- Structure and Markdown conventions
- Concision vs. depth
- Directness
- Vocabulary
- Examples and alternatives
- Handling of uncertainty
- Any other established stylistic expectations

Do not infer preferences without evidence.

## 7. Constraints & Continuity

Record every active constraint and its impact, including:

- User-imposed
- Technical
- Practical
- Organizational
- Stylistic
- Inferred

Also record:

- Mistakes already corrected
- Rejected ideas
- Dead ends
- Topics already explained
- Redundant suggestions
- Previously resolved discussions

The next agent should **not repeat, restart, or re-propose** these unnecessarily.

## 8. Nuances

Preserve subtle information that could otherwise be lost:

- Implicit assumptions
- Edge cases
- Caveats
- Emotional or conversational context when relevant
- Unstated expectations
- Dependencies between pieces of context

If uncertain whether something could matter later, **preserve it rather than discard it**.

## 9. Instructions to the Next Agent

Write the checkpoint so the next agent can act immediately:

- Assume there is no previous conversation.
- Treat this checkpoint as the authoritative working state.
- Continue from the exact stopping point.
- Preserve established decisions, terminology, constraints, preferences, and conventions.
- Do not restart the discussion or repeat completed work.
- Do not ask for clarification when the checkpoint already provides the answer.
- Resolve ambiguity only when necessary; distinguish inference from established fact.
- Continue naturally as though no context was lost.

## Fidelity Rules

The checkpoint must preserve:

*all decisions, reasoning, assumptions, constraints, unresolved issues, context dependencies, user preferences, terminology, conventions, and information capable of changing a future response.*

Do not silently correct, reinterpret, reconcile, or replace conversation content with outside knowledge.

When information conflicts, preserve the conflict and its context rather than inventing a resolution.

## Output Rules

- Output **only the checkpoint**.
- Use Markdown headings and a clear hierarchy.
- Make it immediately usable as a standalone handoff.
- Do not include commentary about the prompt, process, or compression.
- Do not omit information merely because it appears minor.
- Clearly distinguish **explicit facts, observations, and inferences**.
- Compress repeated information, but never at the cost of semantic fidelity.
- Treat the result as a *serialized snapshot of the complete working state, not a summary*.
