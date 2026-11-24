---
name: Good first issue
about: A small, self-contained task ideal for first-time contributors
title: "[good_first_issue]"
labels: good first issue
assignees: ''

---

### Context
<!--
Explain in 2–3 sentences WHERE this fits in the project and WHY it is needed.
Point to the relevant file(s) or folder(s) (e.g. lib/src/export/, lib/src/ui/).
-->
Example:

The export command currently only supports CSV. We need to add JSON export support, following the same pattern used in lib/src/export/csv_exporter.dart.

#### Task
<!--
Describe what needs to be done, step by step if possible.
Avoid leaving architecture decisions open — if the contributor must decide
"how" to do something structural, it is no longer a good first issue.
-->

 Step 1: ...
 Step 2: ...
 Step 3: ...

#### Relevant files
<!-- Direct link to files/lines, if known -->

lib/src/export/csv_exporter.dart (pattern to follow)
lib/src/export/export.dart (barrel file; register the new exporter here)

#### Acceptance criteria
<!-- How to know it is done? -->

 Feature implemented and manually tested
 Unit tests added (if applicable)
 Documentation/README updated (if needed)
 Follows established project code patterns

#### Estimated difficulty
<!-- Helps the contributor set expectations -->
🟢 Easy (a few hours) / 🟡 Medium (a weekend) / 🔴 Needs more context
Need help?
Comment here or ask before you start — no problem at all; that is what this label is for.
