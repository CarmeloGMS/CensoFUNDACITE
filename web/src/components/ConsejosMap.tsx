import { useEffect, useRef, useState } from 'react'
import { GeoJSONSource, LngLatBounds, Map as MlMap, Marker, NavigationControl, Popup, ScaleControl, setWorkerUrl, type StyleSpecification } from 'maplibre-gl'
import workerUrl from 'maplibre-gl/dist/maplibre-gl-worker.mjs?worker&url'
import { Layers } from 'lucide-react'
import clsx from 'clsx'
import { ESTADO_META } from '../lib/format'
import type { ConsejoFC } from '../lib/types'

setWorkerUrl(workerUrl)

export const LA_GUAIRA: [number, number, number, number] = [-67.35, 10.47, -66.05, 10.68]

export type Base = 'mapa' | 'satelite'

export function baseStyle(base: Base): StyleSpecification {
  const raster = base === 'mapa'
    ? {
        tiles: ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'],
        attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
      }
    : {
        tiles: ['https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'],
        attribution: 'Imágenes © Esri, Maxar, Earthstar Geographics',
      }
  return {
    version: 8,
    glyphs: 'https://demotiles.maplibre.org/font/{fontstack}/{range}.pbf',
    sources: { base: { type: 'raster', tileSize: 256, ...raster } },
    layers: [{ id: 'base', type: 'raster', source: 'base' }],
  }
}

function addConsejoLayers(map: MlMap, data: ConsejoFC) {
  map.addSource('consejos', { type: 'geojson', data, cluster: true, clusterRadius: 46, clusterMaxZoom: 13 })
  map.addLayer({
    id: 'clusters', type: 'circle', source: 'consejos', filter: ['has', 'point_count'],
    paint: {
      'circle-color': '#065f46',
      'circle-opacity': 0.9,
      'circle-radius': ['step', ['get', 'point_count'], 16, 10, 21, 30, 27],
      'circle-stroke-width': 4,
      'circle-stroke-color': 'rgba(255,255,255,0.75)',
    },
  })
  map.addLayer({
    id: 'cluster-count', type: 'symbol', source: 'consejos', filter: ['has', 'point_count'],
    layout: { 'text-field': '{point_count_abbreviated}', 'text-font': ['Open Sans Semibold'], 'text-size': 13 },
    paint: { 'text-color': '#ffffff' },
  })
  map.addLayer({
    id: 'punto-halo', type: 'circle', source: 'consejos', filter: ['!', ['has', 'point_count']],
    paint: {
      'circle-radius': 13,
      'circle-color': ['match', ['get', 'estado'], 'validado', ESTADO_META.validado.color, 'rechazado', ESTADO_META.rechazado.color, ESTADO_META.enviado.color],
      'circle-opacity': 0.18,
    },
  })
  map.addLayer({
    id: 'punto', type: 'circle', source: 'consejos', filter: ['!', ['has', 'point_count']],
    paint: {
      'circle-radius': 7,
      'circle-color': ['match', ['get', 'estado'], 'validado', ESTADO_META.validado.color, 'rechazado', ESTADO_META.rechazado.color, ESTADO_META.enviado.color],
      'circle-stroke-width': 2.5,
      'circle-stroke-color': '#ffffff',
    },
  })
}

function popupHtml(p: Record<string, unknown>) {
  const estado = (p.estado as keyof typeof ESTADO_META) ?? 'enviado'
  const meta = ESTADO_META[estado] ?? ESTADO_META.enviado
  let rubros: string[] = []
  try { rubros = typeof p.rubros === 'string' ? JSON.parse(p.rubros) : (p.rubros as string[]) ?? [] } catch { rubros = [String(p.rubros)] }
  const esc = (s: unknown) => String(s ?? '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]!))
  return `
    <div style="min-width:220px;font-family:inherit">
      <div style="height:4px;background:${meta.color}"></div>
      <div style="padding:12px 14px">
        <div style="font-size:11px;color:#78716c;text-transform:uppercase;letter-spacing:.04em">${esc(p.parroquia)}</div>
        <div style="font-weight:600;color:#1c1917;font-size:14px;margin:2px 0 6px">${esc(p.nombre)}</div>
        <div style="display:flex;gap:10px;font-size:12px;color:#57534e;margin-bottom:8px">
          <span>👨‍👩‍👧 ${esc(p.num_familias)} familias</span><span style="color:${meta.color};font-weight:600">● ${meta.label}</span>
        </div>
        ${rubros.length ? `<div style="font-size:11px;color:#57534e;margin-bottom:10px">${rubros.slice(0, 4).map(esc).join(' · ')}</div>` : ''}
        <a href="/consejos/${esc(p.id)}" data-link style="display:inline-block;font-size:12px;font-weight:600;color:#047857;text-decoration:none">Ver ficha →</a>
      </div>
    </div>`
}

interface Props {
  data?: ConsejoFC
  className?: string
  onNavigate?: (path: string) => void
  single?: { lat: number; lng: number }
}

export function ConsejosMap({ data, className, onNavigate, single }: Props) {
  const ref = useRef<HTMLDivElement>(null)
  const mapRef = useRef<MlMap | null>(null)
  const dataRef = useRef<ConsejoFC | undefined>(data)
  const fitted = useRef(false)
  const [base, setBase] = useState<Base>('mapa')
  dataRef.current = data

  useEffect(() => {
    if (!ref.current) return
    const map = new MlMap({
      container: ref.current,
      style: baseStyle('mapa'),
      bounds: single ? undefined : LA_GUAIRA,
      center: single ? [single.lng, single.lat] : undefined,
      zoom: single ? 14 : undefined,
      attributionControl: { compact: true },
      cooperativeGestures: false,
    })
    map.addControl(new NavigationControl({ showCompass: false }), 'top-right')
    map.addControl(new ScaleControl({ unit: 'metric' }), 'bottom-left')
    mapRef.current = map

    if (single) {
      const el = document.createElement('div')
      el.innerHTML = `<div style="position:relative;width:22px;height:22px"><div style="position:absolute;inset:-10px;border-radius:9999px;background:rgba(5,150,105,.2)"></div><div style="position:absolute;inset:0;border-radius:9999px;background:#059669;border:3px solid white;box-shadow:0 2px 8px rgba(0,0,0,.3)"></div></div>`
      new Marker({ element: el }).setLngLat([single.lng, single.lat]).addTo(map)
    }

    const ensureLayers = () => {
      if (single || !dataRef.current || map.getSource('consejos')) return
      try { addConsejoLayers(map, dataRef.current) } catch { /* style not ready yet */ }
    }
    map.on('style.load', ensureLayers)
    map.on('styledata', ensureLayers)
    map.on('load', ensureLayers)

    if (!single) {
      map.on('click', 'clusters', async (e) => {
        const f = map.queryRenderedFeatures(e.point, { layers: ['clusters'] })[0]
        const src = map.getSource('consejos') as GeoJSONSource
        const zoom = await src.getClusterExpansionZoom(f.properties.cluster_id)
        map.easeTo({ center: (f.geometry as unknown as { coordinates: [number, number] }).coordinates, zoom })
      })
      map.on('click', 'punto', (e) => {
        const f = e.features?.[0]
        if (!f) return
        const popup = new Popup({ offset: 12, maxWidth: '280px' })
          .setLngLat((f.geometry as unknown as { coordinates: [number, number] }).coordinates)
          .setHTML(popupHtml(f.properties))
          .addTo(map)
        popup.getElement().querySelector('a[data-link]')?.addEventListener('click', (ev) => {
          if (!onNavigate) return
          ev.preventDefault()
          onNavigate(`/consejos/${f.properties.id}`)
        })
      })
      for (const l of ['clusters', 'punto']) {
        map.on('mouseenter', l, () => { map.getCanvas().style.cursor = 'pointer' })
        map.on('mouseleave', l, () => { map.getCanvas().style.cursor = '' })
      }
    }
    return () => map.remove()
  }, [])

  useEffect(() => {
    const map = mapRef.current
    if (!map || !data || single) return
    const src = map.getSource('consejos') as GeoJSONSource | undefined
    if (src) src.setData(data)
    else {
      try { addConsejoLayers(map, data) } catch { /* added on styledata */ }
    }
    if (!fitted.current && data.features.length) {
      const b = new LngLatBounds()
      data.features.forEach((f) => b.extend(f.geometry.coordinates))
      const fit = () => map.fitBounds(b, { padding: 60, maxZoom: 13, duration: 0 })
      if (map.loaded()) fit()
      else map.once('load', fit)
      fitted.current = true
    }
  }, [data, single])

  const switchBase = (b: Base) => {
    setBase(b)
    mapRef.current?.setStyle(baseStyle(b))
  }

  return (
    <div className={clsx(!/\babsolute\b/.test(className ?? '') && 'relative', 'overflow-hidden', className)}>
      <div ref={ref} style={{ position: 'absolute', inset: 0 }} />
      <div className="absolute top-3 left-3 flex overflow-hidden rounded-xl bg-white/95 p-1 text-xs font-medium shadow-md ring-1 ring-stone-200 backdrop-blur">
        <Layers className="mx-1.5 my-auto size-3.5 text-stone-400" />
        {(['mapa', 'satelite'] as const).map((b) => (
          <button key={b} onClick={() => switchBase(b)}
            className={clsx('rounded-lg px-2.5 py-1 transition-colors', base === b ? 'bg-brand-700 text-white' : 'text-stone-600 hover:bg-stone-100')}>
            {b === 'mapa' ? 'Mapa' : 'Satélite'}
          </button>
        ))}
      </div>
      {!single && (
        <div className="absolute bottom-8 right-3 flex flex-col gap-1 rounded-xl bg-white/95 px-3 py-2 text-[11px] text-stone-600 shadow-md ring-1 ring-stone-200 backdrop-blur">
          {(['validado', 'enviado', 'rechazado'] as const).map((e) => (
            <span key={e} className="flex items-center gap-2">
              <span className="size-2.5 rounded-full ring-2 ring-white" style={{ background: ESTADO_META[e].color }} />
              {ESTADO_META[e].label}
            </span>
          ))}
        </div>
      )}
    </div>
  )
}
