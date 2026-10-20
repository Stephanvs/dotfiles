# Obsidian note structure

Use the surrounding vault's conventions. Fill the following structure with real values and omit irrelevant sections. Never leave placeholder properties or headings in the delivered note.

```markdown
---
aliases:
  - "Series or episode name, if useful"
tags:
  - relevant-topic
source: "https://www.youtube.com/watch?v=VIDEO_ID"
created: YYYY-MM-DD
---

# Descriptive title

Video: [Actual video title](https://www.youtube.com/watch?v=VIDEO_ID)

Related: [[Existing relevant note]]

> [!abstract] Summary
> State the main insight and what the episode actually establishes.

## A substantive idea from the video

[Watch: MM:SS](https://www.youtube.com/watch?v=VIDEO_ID&t=SECONDS)

Explain the problem, mechanism, useful detail, and limitation. Add as many
topic sections as the material warrants; avoid a fixed number of takeaways.

## Applying the ideas

Label your own applications explicitly. Omit this section if it adds no value.

## Sources and limitations

- Link the original video and relevant primary sources.
- State whether the analysis used human, automatic, or translated captions.
- State whether on-screen material was inspected; qualify timestamps as approximate when grouped.
- Note unresolved questions, unfinished work, and differences between current sources and the recording.
```

For a live-coding session, distinguish the initial problem, implemented changes, intermediate failed hypotheses, and final verified state. Do not frame compilation or the absence of an immediate crash as proof of correctness.

For a talk, interview, tutorial, or nontechnical video, organize around its actual arguments, evidence, and demonstrations rather than imposing the live-coding structure. Explain unfamiliar terms only where they help the reader understand a substantive point.

Quote sparingly and verify quotations against the source. Prefer explanatory paraphrases, and label conceptual pseudocode as your reconstruction rather than a transcription.
