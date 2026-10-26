import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { Render } from '../types'
import { split } from './split'

// mermaid-cli ships puppeteer-core without a browser, so mmdc needs Chrome's path.
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
const SCALE = 2
const MMDC_OPTIONS = ['--scale', String(SCALE), '--theme', 'dark', '--backgroundColor', 'transparent']
// What one terminal cell measures in CSS pixels, near enough to size a picture.
const CELL_WIDTH_PX = 9
const CELL_HEIGHT_PER_WIDTH = 2.1
const MAX_ROWS = 40

const renders = atom({ plugin: 'mermaid-images', key: 'renders' } as const, {}, {
  shape: 'renders-1',
})

// Hashes whose mmdc run is on its way. A reload forgets them, and the next draw starts the run again.
const inFlight = new Set<string>()

export const register: Register = on => {
  on('ui.render', { component: 'AssistantMessage' }, async ($, e, next) => {
    if (e.surface !== 'terminal') return next(e)

    const parts = split(e.props.text)
    if (!parts.some(part => part.kind === 'diagram')) return next(e)

    const { Box, Image, Markdown, Text } = $.ui.resolve(e)
    const known = await read($, renders)
    const dir = await cacheDir($)
    const maxColumns = Math.max(10, (e.viewport?.columns ?? 80) - 4)

    const drawn = await Promise.all(
      parts.map(async part => {
        if (part.kind === 'prose') return <Markdown text={part.text} />

        const code = fenced(part.source)
        const hash = await sha256(MMDC_OPTIONS.join(' ') + '\n' + part.source)
        const png = `${dir}/${hash}.png`

        if (await $.fs.exists(png)) {
          const { base64 } = await $.fs.read(png, { as: 'bytes' })
          const { columns, rows } = fit(pngSize(base64), maxColumns)

          return <Image source={{ png: base64 }} columns={columns} rows={rows} alt={code} />
        }

        const render = known[hash]
        if (render?.status === 'failed') {
          return (
            <Box flexDirection="column">
              <Markdown text={code} />
              <Text dimColor>mermaid: {render.error}</Text>
            </Box>
          )
        }

        if (!inFlight.has(hash)) {
          inFlight.add(hash)
          // A hook's own calls end with its dispatch; a timer's callback outlives it.
          $.clock.after(0, () => void renderDiagram($, part.source, dir, hash))
        }

        return <Markdown text={code} />
      }),
    )

    return <Box flexDirection="column">{drawn}</Box>
  })
}

async function renderDiagram($: EngineInterface, source: string, dir: string, hash: string) {
  let render: Render
  try {
    const input = `${dir}/${hash}.mmd`
    await $.fs.write(input, source)
    const env = (await $.fs.exists(CHROME)) ? { PUPPETEER_EXECUTABLE_PATH: CHROME } : undefined
    const run = await $.process.run(
      ['mmdc', '--quiet', '--input', input, '--output', `${dir}/${hash}.png`, ...MMDC_OPTIONS],
      { env, timeoutMs: 120_000 },
    )
    render = run.exitCode === 0
      ? { status: 'ready' }
      : { status: 'failed', error: firstLine(run.stderr) || `mmdc exited ${run.exitCode}` }
  } catch (error) {
    render = { status: 'failed', error: firstLine(String(error)) }
  }

  inFlight.delete(hash)
  // The draw read this atom, so the write makes Claude Code draw the reply again.
  await update($, renders, all => ({ ...all, [hash]: render }))
}

async function cacheDir($: EngineInterface) {
  const home = (await $.env.get('HOME')) ?? '/tmp'

  return `${home}/.cache/claude-mermaid-images`
}

async function sha256(text: string) {
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text))

  return [...new Uint8Array(digest)].map(byte => byte.toString(16).padStart(2, '0')).join('')
}

// A PNG's IHDR chunk keeps width and height as big-endian words at bytes 16 and 20.
function pngSize(base64: string) {
  const head = atob(base64.slice(0, 32))
  const word = (at: number) =>
    ((head.charCodeAt(at) << 24) | (head.charCodeAt(at + 1) << 16) |
      (head.charCodeAt(at + 2) << 8) | head.charCodeAt(at + 3)) >>> 0

  return { width: word(16), height: word(20) }
}

function fit({ width, height }: { width: number; height: number }, maxColumns: number) {
  const ratio = height / Math.max(1, width) / CELL_HEIGHT_PER_WIDTH
  let columns = Math.min(maxColumns, Math.ceil(width / SCALE / CELL_WIDTH_PX))
  let rows = Math.round(columns * ratio)
  if (rows > MAX_ROWS) {
    rows = MAX_ROWS
    columns = Math.round(rows / ratio)
  }

  return { columns: Math.max(1, columns), rows: Math.max(1, rows) }
}

function fenced(source: string) {
  return '```mermaid\n' + source + '\n```'
}

function firstLine(text: string) {
  return text.trim().split('\n')[0]?.trim() ?? ''
}
