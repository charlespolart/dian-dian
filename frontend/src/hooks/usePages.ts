import { useState, useEffect, useCallback } from 'react';
import { apiFetch } from '../lib/api';
import { addWsListener } from '../lib/ws';

export interface Page {
  id: string;
  title: string;
  position: number;
  createdAt: string;
}

export function usePages() {
  const [pages, setPages] = useState<Page[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchPages = useCallback(async () => {
    try {
      const res = await apiFetch('/pages');
      if (res.ok) {
        const data = await res.json();
        setPages(data);
      }
    } catch { /* ignore */ }
    setLoading(false);
  }, []);

  useEffect(() => {
    fetchPages();
  }, [fetchPages]);

  useEffect(() => {
    return addWsListener((event, data) => {
      switch (event) {
        case 'page:created':
          setPages(prev => [...prev, data].sort((a, b) => a.position - b.position));
          break;
        case 'page:updated':
          setPages(prev => prev.map(p => p.id === data.id ? data : p).sort((a, b) => a.position - b.position));
          break;
        case 'page:deleted':
          setPages(prev => prev.filter(p => p.id !== data.id));
          break;
      }
    });
  }, []);

  const createPage = useCallback(async (title?: string) => {
    const res = await apiFetch('/pages', {
      method: 'POST',
      body: JSON.stringify({ title, position: pages.length }),
    });
    if (!res.ok) throw new Error('Erreur lors de la création');
    return res.json();
  }, [pages.length]);

  const updatePage = useCallback(async (id: string, updates: { title?: string; position?: number }) => {
    const res = await apiFetch(`/pages/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(updates),
    });
    if (!res.ok) throw new Error('Erreur lors de la mise à jour');
    return res.json();
  }, []);

  const deletePage = useCallback(async (id: string) => {
    const res = await apiFetch(`/pages/${id}`, { method: 'DELETE' });
    if (!res.ok) throw new Error('Erreur lors de la suppression');
  }, []);

  return { pages, loading, createPage, updatePage, deletePage, refetch: fetchPages };
}
