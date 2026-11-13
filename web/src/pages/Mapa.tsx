import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Filter } from 'lucide-react'
import { ConsejosMap } from '../components/ConsejosMap'
import { Select, Spinner } from '../components/ui'
import { useCatalogos, useGeojson } from '../lib/queries'
import { fmtNum } from '../lib/format'

export default function Mapa() {
  const navigate = useNavigate()
  const { data: cat } = useCatalogos()
  const [f, setF] = useState({ parroquia: '', rubro: '', estado: '' })
  const { data, isFetching } = useGeojson(f)
  const familias = data?.features.reduce((s, x) => s + (Number(x.properties.num_familias) || 0), 0) ?? 0

  return (
    <div className="relative h-full min-h-[600px]">
      <ConsejosMap data={data} onNavigate={navigate} className="absolute inset-0" />
      <div className="absolute top-16 left-3 w-72 rounded-2xl bg-white/95 p-4 shadow-xl ring-1 ring-stone-200 backdrop-blur">
        <div className="mb-3 flex items-center justify-between">
          <p className="flex items-center gap-2 text-sm font-semibold text-stone-900"><Filter className="size-4 text-brand-700" />Filtros</p>
          {isFetching && <Spinner className="size-4" />}
        </div>
        <div className="space-y-2">
          <Select value={f.parroquia} onChange={(e) => setF({ ...f, parroquia: e.target.value })}>
            <option value="">Todas las parroquias</option>
            {cat?.parroquias.map((p) => <option key={p.id} value={p.id}>{p.nombre}</option>)}
          </Select>
          <Select value={f.rubro} onChange={(e) => setF({ ...f, rubro: e.target.value })}>
            <option value="">Todos los rubros</option>
            {cat?.rubros.map((r) => <option key={r.id} value={r.id}>{r.nombre}</option>)}
          </Select>
          <Select value={f.estado} onChange={(e) => setF({ ...f, estado: e.target.value })}>
            <option value="">Todos los estados</option>
            {cat?.estados.map((e) => <option key={e.value} value={e.value}>{e.label}</option>)}
          </Select>
        </div>
        <div className="mt-4 grid grid-cols-2 gap-2">
          <div className="rounded-xl bg-brand-50 px-3 py-2">
            <p className="text-[11px] text-brand-700/80">Consejos</p>
            <p className="text-lg font-semibold text-brand-900 tabular-nums">{fmtNum(data?.features.length ?? 0)}</p>
          </div>
          <div className="rounded-xl bg-amber-50 px-3 py-2">
            <p className="text-[11px] text-amber-700/80">Familias</p>
            <p className="text-lg font-semibold text-amber-900 tabular-nums">{fmtNum(familias)}</p>
          </div>
        </div>
      </div>
    </div>
  )
}
