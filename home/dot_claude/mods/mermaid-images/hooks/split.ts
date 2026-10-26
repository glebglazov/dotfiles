export type Part =
  | { kind: 'prose'; text: string }
  | { kind: 'diagram'; source: string }

const OPENING_FENCE = /^ {0,3}```mermaid\s*$/
const CLOSING_FENCE = /^ {0,3}```\s*$/

// A fence with no closing line stays prose, so a reply that is still
// streaming shows its code until the fence closes.
export function split(markdown: string): Part[] {
  const lines = markdown.split('\n')
  const parts: Part[] = []
  let prose: string[] = []

  const flushProse = () => {
    const text = prose.join('\n')
    if (text.trim() !== '') parts.push({ kind: 'prose', text })
    prose = []
  }

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i]!
    const close = OPENING_FENCE.test(line)
      ? lines.findIndex((next, j) => j > i && CLOSING_FENCE.test(next))
      : -1

    if (close === -1) {
      prose.push(line)
      continue
    }

    flushProse()
    parts.push({ kind: 'diagram', source: lines.slice(i + 1, close).join('\n') })
    i = close
  }
  flushProse()

  return parts
}
