import { useEffect, useRef, useCallback } from 'react'
import type { Product } from '../types'

type Options = { onProductUpdate: (p: Product) => void; onQueueDetected?: (data: { product_id: number; url: string }) => void }

export function useWebSocket({ onProductUpdate, onQueueDetected }: Options) {
  const wsRef = useRef<WebSocket | null>(null)
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null)
  const mounted = useRef(true)

  const connect = useCallback(() => {
    if (!mounted.current) return
    const ws = new WebSocket('ws://localhost:8000/ws')
    wsRef.current = ws
    ws.onmessage = (e) => {
      try {
        const msg = JSON.parse(e.data)
        if (msg.type === 'product_update') onProductUpdate(msg.product)
        if (msg.type === 'queue_detected' && onQueueDetected) onQueueDetected(msg)
      } catch {}
    }
    ws.onclose = () => { if (mounted.current) timer.current = setTimeout(connect, 5000) }
    ws.onerror = () => ws.close()
    const ping = setInterval(() => { if (ws.readyState === WebSocket.OPEN) ws.send('ping') }, 30000)
    ws.addEventListener('close', () => clearInterval(ping))
  }, [onProductUpdate, onQueueDetected])

  useEffect(() => {
    mounted.current = true
    connect()
    return () => { mounted.current = false; if (timer.current) clearTimeout(timer.current); wsRef.current?.close() }
  }, [connect])
}
