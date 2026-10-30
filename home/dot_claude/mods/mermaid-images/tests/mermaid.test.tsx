import type { On } from 'claude-code'
import { expect, test } from 'claude-code/testing'

const REPLY = {
  plugin: 'mermaid-images',
  surface: 'terminal',
  component: 'AssistantMessage',
  viewport: { columns: 80, rows: 40 },
} as const

const WITH_DIAGRAM = 'Here is the flow:\n\n```mermaid\ngraph TD\n  A --> B\n```\n\nThat is all.'

// A blank 1800x900 PNG.
const PNG_1800_900 =
  'iVBORw0KGgoAAAANSUhEUgAABwgAAAOEAQAAAACd1VibAAAA3ElEQVR42u3BMQEAAADCoPVPbQo/oAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAvgYatQABGE7c0wAAAABJRU5ErkJggg=='

// Each find is a round trip to the engine, which lets the mod's render finish meanwhile.
async function eventually<T>(find: () => Promise<T | undefined>) {
  for (let attempt = 0; attempt < 50; attempt++) {
    const found = await find()
    if (found !== undefined) return found
  }

  return undefined
}

// Stands for Claude Code's own drawing of a reply, so a test sees what it drew.
function drawLikeTheEngine(on: On) {
  on('ui.render', { component: 'AssistantMessage' }, ($, e) => {
    const { Text } = $.ui.resolve(e)

    return <Text>engine: {e.props.text}</Text>
  })
}

test('a reply with no mermaid block is left to the engine', async ($, on) => {
  drawLikeTheEngine(on)

  const ui = await $.ui.mount({ ...REPLY, props: { text: 'No diagram here.', isFirstOfReply: true } })

  expect(await ui.find({ type: 'Text', text: 'engine: No diagram here.' })).toBeDefined()
  expect(await ui.find({ type: 'Image' })).toBeUndefined()
  await ui.unmount()
})

test('a rendered diagram is drawn as a picture, the engine drawing the opening prose', async ($, on) => {
  drawLikeTheEngine(on)
  on('env.get', () => ({ value: '/home/me' }))
  on('fs.exists', () => ({ value: true }))
  on('fs.read', () => ({ value: { base64: PNG_1800_900 } }))

  const ui = await $.ui.mount({ ...REPLY, props: { text: WITH_DIAGRAM, isFirstOfReply: true } })
  const image = await ui.find({ type: 'Image' })

  expect(image?.props.columns).toBe(76)
  expect(image?.props.rows).toBe(18)
  expect(String(image?.props.alt)).toContain('A --> B')
  const link = await ui.find({ type: 'Link' })
  expect(link?.props.href).toMatch(/^file:\/\/\/home\/me\/\.cache\/claude-mermaid-images\/[0-9a-f]{64}\.png$/)
  expect(await ui.find({ type: 'Text', text: 'engine: Here is the flow:' })).toBeDefined()
  expect(await ui.find({ type: 'Markdown', text: /That is all/ })).toBeDefined()
  await ui.unmount()
})

test('a diagram mmdc rejects is left to the engine, with the reason under it', async ($, on) => {
  drawLikeTheEngine(on)
  on('env.get', () => ({ value: '/home/me' }))
  on('fs.exists', () => ({ value: false }))
  on('fs.write', () => ({ value: undefined }))
  on('clock.after', () => ({ value: undefined }))
  on('process.run', () => ({
    value: {
      exitCode: 1,
      stdout: '',
      stderr: 'Parse error on line 2\nstack...',
      isStdoutTruncated: false,
      isStderrTruncated: false,
    },
  }))

  const ui = await $.ui.mount({ ...REPLY, props: { text: WITH_DIAGRAM, isFirstOfReply: true } })

  expect(
    await eventually(() => ui.find({ type: 'Text', text: /mermaid: Parse error on line 2/ })),
  ).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /engine: Here is the flow:\n\n```mermaid/ })).toBeDefined()
  expect(await ui.find({ type: 'Image' })).toBeUndefined()
  await ui.unmount()
})
