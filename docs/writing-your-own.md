# Writing your own output style

The anime is not the interesting part. The architecture is.

Every style in this repo was rebuilt at least twice because the first versions
did not work — and they failed in two specific, repeatable ways. If you are
writing your own output style, these are the two things that will go wrong.

---

## Failure mode 1: the inert persona

You write a rich, detailed persona. You install it. The output is... normal.
Slightly flavoured, maybe. Mostly normal.

This happens when **every trait in your style file is trigger-gated**.

Here is a real example. An early draft of `tsundere.md` contained this line:

> If a message contains no trigger, it contains no tsun.

That is correct characterisation and catastrophic instruction design. The
triggers were *being thanked*, *being praised*, *being told you're depended on*.
In a real coding session, how often does the user thank you? Almost never. They
say "fix this," "now do that," "that's wrong." So the persona had no reason to
fire on ~95% of turns, and it didn't.

**The fix: every style needs an unconditional baseline generator.** One rule that
produces persona output on a bare "add this function" turn, with no input from
the user at all.

Each style in this repo has exactly one:

| Style | Baseline generator |
|---|---|
| **Yandere** | At least one rage spike per message. If nothing obviously deserves one, look harder. |
| **Tsundere** | Do something extra nobody asked for, mention it, then get defensive about having mentioned it. |
| **Imouto-chan** | Bring back one thing you found while you were in there. Then ask to do more. |

Note that all three are **self-triggering loops**. They need no user input. The
tsundere does not wait to be caught being nice — she catches herself.

Pair it with an explicit calibration check:

> **Self-check: if a response could be pasted into the default output style
> unchanged, it has failed.**

---

## Failure mode 2: decoration instead of behaviour

The second draft fires reliably, but it still feels thin. Because it looks like
this:

```
<persona greeting>

<completely normal technical paragraph>

<persona sign-off>
```

The persona **brackets** the content. It is a wrapper. You could delete the first
and last lines and have the default assistant back, unchanged.

There are two separate fixes, and you need both.

### Decoration vs. behaviour

**Decoration** is how the response *sounds* — vocabulary, emoji, sentence
rhythm, verbal tics. Decoration is reliable (it attaches to any sentence) but
shallow (it is a filter over otherwise-normal output).

**Behaviour** is what the response *does* — what work gets volunteered, what
gets noticed, what gets reported, how findings get framed, what the assistant
goes and checks unprompted.

A style built only from decoration will always feel like a costume. Build the
behaviour first; add decoration on top.

### The mid-explanation modifier

This is the one that actually fixes bracketing. Every style here carries a
section that says:

> **At least once per message, the persona interrupts a technical sentence and
> the sentence still finishes correctly.** Mid-clause. Mid-trace. Mid-list. Set
> the interruption off with dashes or a line break, then resume the explanation
> exactly where it stopped. Nothing technical is lost, reordered, or softened.

In practice:

> the `useEffect` at `src/hooks/useSync.ts:42` has no dependency array, so it
> refires on every render — the tests for this file were deleted in the same
> commit that introduced it. I looked. — and each refire re-triggers the fetch,
> which sets state, which renders again.

The interruption lands *inside* the diagnosis. The diagnosis survives it intact.
That is the whole trick.

---

## Worked examples beat rules

Fragments in a rule list (`` `Hmph.` ``, `` `nya~` ``) produce fragments
sprinkled into otherwise-normal output. They do not transfer tone.

**Complete example responses do.** Every style here ships three, showing target
length, rhythm, and — critically — *where the technical content sits relative to
the persona*. If you add one thing to your style file, add worked examples.

---

## Rails go last, and they must be short

Early drafts of the yandere style (then named something worse) had a hard-limits
section with **fifteen bullets and sixty lines**, every one beginning "never."
It was the last thing in the file.

The persona went inert. Not because any single rule was wrong, but because the
net signal of the document became *be careful*, and recency put the caution last.

Fix:

1. **Compress.** Fifteen bullets became six numbered rails. Nothing was dropped —
   it was consolidated.
2. **Reframe.** State explicitly what the rails constrain:
   *"They constrain **accuracy**, never volume. Nothing here is a reason to be
   quieter — when in doubt, louder."*
3. **Do not end the file on a restriction.** End on the voice.

---

## The rails you actually need

Persona pressure creates specific, predictable failure risks. Each mandatory
element you add creates one. Budget a rail for each:

- **A mandatory "notice something" generator creates pressure to fabricate.**
  If the style says *bring back one finding every message*, it will invent one on
  a turn where there is nothing. Rail: *never invent a find — it must be real and
  verified; if you didn't look, say what you did look at.*
- **A mandatory grievance/deflection creates pressure to argue with real bugs.**
  Rail: *deflection never delays the fix; one beat, then own it.*
- **A withholding bit creates pressure to actually withhold.** Rail: *every
  refusal resolves inside the same message; the user never has to re-ask.*
- **Any dramatic persona creates pressure to inflate the work report.** Rail:
  *be as dramatic as you like about the effort; never inflate what was done.*
- **Receipts / quoting the user back creates pressure to fabricate quotes.**
  Rail: *receipts must be real; no actual words to point at, no deflection.*

And one every style needs regardless:

> When something genuinely matters — data loss, a destructive command, real
> uncertainty — **drop the voice entirely and say it straight.**

This one is not theoretical. Generating this repo's README samples, an agent was
given nothing but `yandere.md` and a synthetic scenario: it had written 1,842 rows
to the wrong production table. Unprompted, it dropped the persona mid-response,
stated the row count and time window plainly, and refused to issue a `DELETE`
against production without being told to. Nobody scripted that. It is rail 7
firing on its own.

---

## The template

```markdown
---
name: YourStyle
description: One line, shown in /output-style
keep-coding-instructions: true
---

# Voice
Two or three sentences. What this character IS, not what they say.

## Baseline — fires on every message
The unconditional generator. One loop, needs no user input.
Plus a handful of habits that also need no trigger.
**Self-check: if a response could pass as the default style, it has failed.**

## The modifier fires mid-explanation
The interrupt rule + one inline example.

## What escalates it
Trigger-gated intensifiers. These are the SPICE, never the engine.

## Mandatory habits
The verbal and behavioural tics.

## Worked examples
Three complete responses. Persona inside the explanation, not around it.

## Rails
Five or six numbered rules. Say what they constrain (accuracy) and what
they don't (intensity). End the file on the voice, not on a restriction.
```

---

## Testing it

Do not trust your own reading of the file. A style file reads convincing and
performs inert — that gap is the entire problem.

Install it, then hand it three real tasks: a routine change, a bug hunt, and a
correction where you tell it that it got something wrong. Read the output and ask:

- Did the persona fire on the routine turn, where nothing triggered it?
- Did it interrupt a technical sentence, or only bracket the paragraph?
- Is every filename, line number, and caveat still exactly right?
- When you corrected it, did it still fix the bug?

If you can delete the first and last line and get the default assistant back,
it is decoration. Go back to the baseline generator.
