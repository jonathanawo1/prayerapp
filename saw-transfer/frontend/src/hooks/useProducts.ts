import { useState, useCallback, useEffect } from 'react'
import { productsApi } from '../api/client'
import type { Product } from '../types'

export function useProducts() {
  const [products, setProducts] = useState<Product[]>([])
  const [loading, setLoading] = useState(true)

  const fetchProducts = useCallback(async () => {
    try { setProducts(await productsApi.list()) }
    catch (e) { console.error(e) }
    finally { setLoading(false) }
  }, [])

  useEffect(() => { fetchProducts() }, [fetchProducts])

  const addProduct = useCallback(async (url: string, interval: number) => {
    const p = await productsApi.add(url, interval)
    setProducts(prev => [p, ...prev])
    return p
  }, [])

  const removeProduct = useCallback(async (id: number) => {
    await productsApi.remove(id)
    setProducts(prev => prev.filter(p => p.id !== id))
  }, [])

  const updateProduct = useCallback(async (id: number, patch: { is_active?: boolean; check_interval_seconds?: number }) => {
    const updated = await productsApi.update(id, patch)
    setProducts(prev => prev.map(p => p.id === id ? updated : p))
    return updated
  }, [])

  const handleWsUpdate = useCallback((updated: Product) => {
    setProducts(prev => prev.map(p => p.id === updated.id ? updated : p))
  }, [])

  return { products, loading, fetchProducts, addProduct, removeProduct, updateProduct, handleWsUpdate }
}
