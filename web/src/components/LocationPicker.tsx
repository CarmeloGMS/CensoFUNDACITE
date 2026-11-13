import { useEffect, useRef, useState } from 'react'
import { Map as MlMap, Marker, NavigationControl } from 'maplibre-gl'
import { Layers } from 'lucide-react'
import clsx from 'clsx'
import { baseStyle, LA_GUAIRA, type Base } from './ConsejosMap'

interface Props {
  value: { lat: number; lng: number } | null
  onChange: (lat: number, lng: number) => void
  className?: string
}

function markerElement() {
  const el = document.createElement('div')
  el.innerHTML = `<div style="position:relative;width:26px;height:26px;cursor:grab"><div style="position:absolute;inset:-10px;border-radius:9999px;background:rgba(5,150,105,.22)"></div><div style="position:absolute;inset:0;border-radius:9999px;background:#059669;border:3px solid white;box-shadow:0 2px 10px rgba(0,0,0,.35)"></div></div>`
  return el
}

export function LocationPicker({ value, onChange, className }: Props) {
  const ref = useRef<HTMLDivElement>(null)
  const mapRef = useRef<MlMap | null>(null)
  const markerRef = useRef<Marker | null>(null)
  const changeRef = useRef(onChange)
  const [base, setBase] = useState<Base>('mapa')
  changeRef.current = onChange

  useEffect(() => {
    if (!ref.current) return
    const map = new MlMap({
      container: ref.current,
      style: baseStyle('mapa'),
      bounds: value ? undefined : LA_GUAIRA,
      center: value ? [value.lng, value.lat] : undefined,
      zoom: value ? 15 : undefined,
      attributionControl: { compact: true },
    })
    map.addControl(new NavigationControl({ showCompass: false }), 'top-right')
    map.getCanvas().style.cursor = 'crosshair'
    map.on('click', (e) => changeRef.current(e.lngLat.lat, e.lngLat.lng))
    mapRef.current = map
    return () => map.remove()
  }, [])

  useEffect(() => {
    const map = mapRef.current
    if (!map || !value) return
    if (!markerRef.current) {
      markerRef.current = new Marker({ element: markerElement(), draggable: true })
        .setLngLat([value.lng, value.lat])
        .addTo(map)
      markerRef.current.on('dragend', () => {
        const p = markerRef.current!.getLngLat()
        changeRef.current(p.lat, p.lng)
      })
    } else {
      markerRef.current.setLngLat([value.lng, value.lat])
    }
    if (!map.getBounds().contains([value.lng, value.lat])) {
      map.easeTo({ center: [value.lng, value.lat], zoom: Math.max(map.getZoom(), 15) })
    }
  }, [value?.lat, value?.lng])

  const switchBase = (b: Base) => {
    setBase(b)
    mapRef.current?.setStyle(baseStyle(b))
  }

  return (
    <div className={clsx('relative overflow-hidden', className)}>
      <div ref={ref} style={{ position: 'absolute', inset: 0 }} />
      <div className="absolute top-3 left-3 flex overflow-hidden rounded-xl bg-white/95 p-1 text-xs font-medium shadow-md ring-1 ring-stone-200 backdrop-blur">
        <Layers className="mx-1.5 my-auto size-3.5 text-stone-400" />
        {(['mapa', 'satelite'] as const).map((b) => (
          <button type="button" key={b} onClick={() => switchBase(b)}
            className={clsx('rounded-lg px-2.5 py-1 transition-colors', base === b ? 'bg-brand-700 text-white' : 'text-stone-600 hover:bg-stone-100')}>
            {b === 'mapa' ? 'Mapa' : 'Satélite'}
          </button>
        ))}
      </div>
      {!value && (
        <div className="pointer-events-none absolute inset-x-0 bottom-4 flex justify-center">
          <span className="rounded-full bg-stone-900/80 px-3 py-1.5 text-xs font-medium text-white shadow-lg">Haz clic en el mapa para marcar la ubicación</span>
        </div>
      )}
    </div>
  )
}
