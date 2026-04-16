# The Unreasonable Effectiveness of Boring Tools

There is a curious tension in software. We worship novelty — new frameworks,
new paradigms, new languages — while the systems that carry the most freight
tend to be built from boring, decades-old components. Relational databases.
UNIX pipes. Plain-text configuration. Cron. A make file. These are the
workhorses that quietly underpin a staggering amount of what we use daily.

The tension is worth thinking about, because we rarely talk about what makes a
tool truly boring in a useful way. I want to propose that *boring* is less
about age and more about three related properties: predictability,
composability, and an honest relationship with complexity.

## Predictability

A predictable tool does what it says, and nothing else. You can read its
manual in an afternoon and know, more or less, what will happen when you
invoke it. It is not going to phone home. It is not going to reformat your
data for reasons it considers helpful. It is not going to wait six months and
then quietly deprecate the flag your scripts depend on. Its authors value
your ability to reason about its behavior more than they value their own
desire to improve it.

Predictability is not the absence of change. Even the most boring tool
evolves. What marks it as boring is that changes are telegraphed, versioned,
and respectful of the people who rely on the tool in its current form. If
you show up tomorrow, what you built yesterday will still work. If it
doesn't, someone owes you an explanation.

This turns out to be a rare property. A lot of modern software prioritizes
improvement over predictability, in the form of automatic updates, implicit
behaviors, and surprise features. Each individual such choice is defensible.
In aggregate they destroy the quiet confidence that lets engineers build on
top of things.

## Composability

Composability is the property that a tool can be wired together with other
tools to do something larger. UNIX popularized this idea: a program should do
one thing, do it well, and talk to other programs through streams of bytes.
It's a humbler philosophy than it sounds. It concedes that the authors of
any single tool cannot anticipate every use case. It assumes its users will
need to combine it with other things.

Most interesting computing happens in those combinations. A good tool knows
this and stays out of the way. It writes plain text to stdout, reads plain
text from stdin, returns meaningful exit codes, and never assumes it is the
center of your world. It does not demand to own your workflow. You bring it
in, you use it, you leave.

The opposite is the walled garden: a tool that insists you adopt its
ecosystem, its conventions, its preferred forms of input and output. Walled
gardens can be lovely places to visit. They are terrible places to live,
because the moment you want something the owner didn't anticipate, you're
stuck negotiating with a party that has very different incentives than you.

## Honest complexity

The third property is hardest to articulate. Every tool encapsulates some
amount of complexity — that is, after all, why it exists. A boring tool is
honest about the complexity it owns. It doesn't pretend to solve problems it
only papers over. Its abstractions are thin where thin is appropriate and
thick where the underlying truth is irreducibly thick.

Honest complexity is what separates a good library from a good framework. A
library lets you dip in and out; you learn what you need when you need it. A
framework demands you learn its mental model up front and live within it
indefinitely. Frameworks aren't inherently bad — sometimes you want the
opinionated path. But a framework that pretends to be a library, or a
library that pretends to be a framework, will eventually break your heart.

A boring tool is usually closer to the library end of the spectrum. It
offers primitives, and trusts you to combine them. It does not try to know
what you're trying to accomplish. It lets you make mistakes, and gives you
the tools to recover from them.

## Why boring tools win

Taken together, these three properties explain why boring tools tend to
outlast flashier competitors. Predictability means you can build on them
without worrying about the ground shifting. Composability means they plug
into the rest of your system without negotiation. Honest complexity means
their abstractions bend in ways you can understand.

Flashy tools sometimes have these properties too. But they aren't selected
for. A project that chases novelty tends to drift toward cleverness at the
expense of predictability, toward ecosystems at the expense of composability,
toward marketing at the expense of honest complexity. Over the span of a
career you learn to be wary of any tool that sells itself as transformative.

The boring tools that survive aren't necessarily the most elegant. Few of
them would win a design competition. But they survive because they let
thousands of users build real things on top of them without asking for
gratitude in return.

## An aside on taste

None of this is to say you should never use a new tool. New tools are
sometimes genuinely better. Git was new once. So was SQLite. So was
JavaScript. The question is less about age and more about disposition. Is
the tool oriented toward its users, or toward its own narrative? Does it
reward people who use it in unanticipated ways, or punish them? Does it
degrade gracefully, or loudly, when pushed past its design envelope?

Over time you develop a sixth sense for this. You can feel the difference
between a tool that will be around in ten years and one that won't. The
difference has nothing to do with features, and everything to do with
stance. Boring tools have a particular stance toward their users: we will
help you do your work, we will get out of your way, and we will be here
tomorrow.

## Practical implications

If you're making decisions about what to build with, a few heuristics
follow. Prefer text over binary, because text is composable. Prefer small
over big, because small things compose more predictably. Prefer tools with a
decade of mileage over tools with a decade of roadmap. Prefer primitives
over frameworks until you find yourself building the same framework three
times, and then grudgingly accept a framework.

If you're building a tool, the advice is the opposite of flashy. Write a
clear manual. Version your behavior. Make it easy to turn off your
cleverness. Assume the user is smarter than you and knows their situation
better. Don't try to solve problems you don't have. Don't demand an
ecosystem. Do one thing, do it well, and leave the rest to other people who
are paid to do those other things.

## Closing

I find this line of thinking calming, which is I suppose why I return to it.
Software is a noisy industry, full of urgency and excitement. It's easy to
feel that you need to keep up, that every new release matters, that you are
one framework behind the future. You probably aren't. The future, as it
turns out, is largely built out of the past: a few very boring, very
composable, very predictable primitives arranged in new ways by people who
understood them well enough to leave most of them alone.

That's a heartening thought. Most of the work of progress, it seems, is not
in inventing new things, but in understanding the old ones deeply enough to
use them without flinching.
