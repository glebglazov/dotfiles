export type Render = { status: 'ready' } | { status: 'failed'; error: string }

declare module 'claude-code' {
  interface PluginState {
    'mermaid-images': { renders: Shaped<Record<string, Render>> }
  }
}
