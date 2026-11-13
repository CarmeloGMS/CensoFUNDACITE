import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { api, qs } from './api'
import { useAuth } from './auth'
import type { Catalogos, Consejo, ConsejoFC, Estadisticas, Filtros, Paginated } from './types'

export const useCatalogos = () =>
  useQuery({ queryKey: ['catalogos'], queryFn: () => api<Catalogos>('/api/catalogos/'), staleTime: Infinity })

export const useEstadisticas = (f: Filtros = {}) =>
  useQuery({ queryKey: ['estadisticas', f], queryFn: () => api<Estadisticas>(`/api/estadisticas/${qs(f)}`), placeholderData: keepPreviousData })

export const useGeojson = (f: Filtros = {}) =>
  useQuery({ queryKey: ['geojson', f], queryFn: () => api<ConsejoFC>(`/api/consejos/geojson/${qs(f)}`), placeholderData: keepPreviousData })

export const useConsejos = (f: Filtros & { page?: number; page_size?: number; ordering?: string }) =>
  useQuery({ queryKey: ['consejos', f], queryFn: () => api<Paginated<Consejo>>(`/api/consejos/${qs(f)}`), placeholderData: keepPreviousData })

export const useConsejo = (id: string | undefined) =>
  useQuery({ queryKey: ['consejo', id], queryFn: () => api<Consejo>(`/api/consejos/${id}/`), enabled: !!id })

export const usePuedeEditar = () => {
  const { user, puedeValidar } = useAuth()
  return (c: Consejo | undefined) => !!c && (puedeValidar || c.registrado_por?.id === user?.id)
}
