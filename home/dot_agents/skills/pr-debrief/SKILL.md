---
name: pr-debrief
description: "Use when writing a PR body. Wraps the `pr` skill, and links the debrief page of the work where the reviewers can open it."
---

# pr-debrief

A PR body made by the `pr` skill, with a link to the **debrief** of the work:
the page that the `debrief` skill made and delivered through Lavish. The body
stays complete without the page. The link gives the reviewer the full page.

## Steps

1. **Write the body.** Load the `pr` skill and write the body by its template.
   Done when the body has each section of the template.
2. **Find the debrief.** Look in the Lavish folder of the current directory,
   `~/.local/share/lavish-axi/<dir-hash>/`, where `<dir-hash>` is
   `printf '%s' "$PWD" | shasum -a 256 | cut -c1-12`. The debrief is the page
   whose header starts with "Debrief" and that describes the work of this PR.
   When more than one page matches, use the newest. Done when you have the
   page, or you know there is none. With none, the body from step 1 is the
   result: stop here.
3. **Publish it.** From the repository, run `scripts/share-debrief <page>` from this skill's directory. It picks
   the host from the owner and visibility of the repository, publishes the
   page there, and prints one Markdown line. Exit status 3 means a private
   personal repository: give the user the command that the script printed,
   because the `lavish` skill keeps `share` for the user. Put their URL in the
   body when they send it. Done when you have the Markdown line, or the user
   has the command.
4. **Link it.** Put the Markdown line on the first line of the body, above
   `## Summary`. Done when the body starts with the line.
