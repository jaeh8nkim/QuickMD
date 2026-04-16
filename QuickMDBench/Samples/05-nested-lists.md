# Lists, nested

## Bulleted, shallow

- Apples
- Oranges
- Pears

## Bulleted, nested three deep

- Top level
  - Second level
    - Third level
    - Third level with *emphasis*
  - Another second
- Sibling top level
  - Nested child

## Ordered, with a custom start

3. Third item
4. Fourth item
5. Fifth item
   1. Nested ordered
   2. Nested ordered
6. Sixth item

## Mixed ordered and unordered

1. First
   - Sub-bullet A
   - Sub-bullet B
     1. Deep ordered
     2. Deep ordered
2. Second
3. Third

## Task list

- [ ] Draft the report
- [x] Review pull requests
- [ ] Ship the release
  - [x] Bump version number
  - [x] Run the smoke tests
  - [ ] Update the changelog
- [ ] Close Q2 retrospective

## Task list with paragraphs inside

- [ ] Research the API.

  The vendor documentation is sparse; email them for details.

- [x] Write a proof of concept.

  The prototype lives in `tools/proto/` and is driven by a small CLI.

## Multi-paragraph list items

1. Gather requirements.

   Talk to stakeholders, write them down, circulate for review.

2. Draft a design.

   Capture the design in an RFC. Expect several revision rounds.

3. Implement.
