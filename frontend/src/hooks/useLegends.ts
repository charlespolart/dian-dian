import { useState, useEffect, useCallback } from 'react';
import { apiFetch } from '../lib/api';
import { addWsListener } from '../lib/ws';

export interface Legend {
  id: string;
  pageId: string;
  color: string;
  label: string;
  position: number;
}

export function useLegends(pageId: string | null) {
  const [legends, setLegends] = useState<Legend[]>([]);
  const [loading, setLoading] = useState(false);

  const fetchLegends = useCallback(async () => {
    if (!pageId) return;
    setLoading(true);
    try {
      const res = await apiFetch(`/legends/${pageId}`);
      if (res.ok) setLegends(await res.json());
    } catch { /* ignore */ }
    setLoading(false);
  }, [pageId]);

  useEffect(() => {
    setLegends([]);
    fetchLegends();
  }, [fetchLegends]);

  useEffect(() => {
    return addWsListener((event, data) => {
      if (!pageId) return;
      switch (event) {
        case 'legend:created':
          if (data.pageId === pageId) {
            setLegends(prev => [...prev, data].sort((a, b) => a.position - b.position));
          }
          break;
        case 'legends:reordered':
          if (data.pageId === pageId) {
            setLegends(prev => {
              const ordered: Legend[] = [];
              for (const id of data.ids) {
                const item = prev.find(l => l.id === id);
                if (item) ordered.push({ ...item, position: ordered.length });
              }
              return ordered;
            });
          }
          break;
        case 'legend:deleted':
          if (data.pageId === pageId) {
            setLegends(prev => prev.filter(l => l.id !== data.id));
          }
          break;
      }
    });
  }, [pageId]);

  const createLegend = useCallback(async (color: string, label: string) => {
    if (!pageId) return;
    const res = await apiFetch(`/legends/${pageId}`, {
      method: 'POST',
      body: JSON.stringify({ color, label, position: legends.length }),
    });
    if (!res.ok) throw new Error('Erreur');
    if (!res.ok) throw new Error('Erreur');
    return res.json();
  }, [pageId, legends.length]);

  const deleteLegend = useCallback(async (id: string) => {
    const res = await apiFetch(`/legends/${id}`, { method: 'DELETE' });
    if (!res.ok) throw new Error('Erreur');
  }, []);

  return { legends, loading, createLegend, deleteLegend, refetch: fetchLegends };
}
