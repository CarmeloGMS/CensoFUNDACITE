import { useEffect, useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { ChevronLeft, ChevronRight, ClipboardPlus, Download, MapPin, Search, SearchX, Sprout, X } from 'lucide-react'
import { PageHeader } from '../components/Layout'
import { Button, Card, Chip, Empty, EstadoBadge, Input, Select, Spinner } from '../components/ui'
import { useCatalogos, useConsejos } from '../lib/queries'
import { downloadFile, qs } from '../lib/api'
import { fmtFecha, fmtNum } from '../lib/format'
import type { Filtros } from '../lib/types'

const PAGE_SIZE = 15

export default function Consejos() {
  const [sp, setSp] = useSearchParams()
  const navigate = useNavigate()
  const { data: cat } = useCatalogos()
  const [q, setQ] = useState(sp.get('search') ?? '')
  const [exporting, setExporting] = useState(false)

  const f: Filtros = {
    search: sp.get('search') ?? '',
    parroquia: sp.get('parroquia') ?? '',
    rubro: sp.get('rubro') ?? '',
    estado: sp.get('estado') ?? '',
  }
  const page = Number(sp.get('page') ?? 1)
  const { data, isLoading, isFetching } = useConsejos({ ...f, page, page_size: PAGE_SIZE, ordering: '-fecha_captura' })

  const set = (k: string, v: string) => {
    const n = new URLSearchParams(sp)
    if (v) n.set(k, v); else n.delete(k)
    if (k !== 'page') n.delete('page')
    setSp(n, { replace: true })
  }

  useEffect(() => {
    const t = setTimeout(() => { if (q !== (sp.get('search') ?? '')) set('search', q) }, 350)
    return () => clearTimeout(t)
  }, [q])

  const total = data?.count ?? 0
  const pages = Math.max(1, Math.ceil(total / PAGE_SIZE))
  const activos = [f.parroquia, f.rubro, f.estado, f.search].filter(Boolean).length

  const exportar = async () => {
    setExporting(true)
    try { await downloadFile(`/api/consejos/export.csv${qs(f)}`, `consejos-campesinos-${new Date().toISOString().slice(0, 10)}.csv`) }
    finally { setExporting(false) }
  }

  return (
    <div className="mx-auto max-w-[1400px] p-4 sm:p-8">
      <PageHeader title="Consejos campesinos" subtitle={`${fmtNum(total)} organizaciones registradas`}
        actions={<>
          <Button variant="secondary" icon={Download} loading={exporting} onClick={exportar}>Exportar CSV</Button>
          <Button icon={ClipboardPlus} onClick={() => navigate('/consejos/nuevo')}>Nuevo registro</Button>
        </>} />

      <Card className="mb-4 p-3">
        <div className="grid gap-3 md:grid-cols-[1fr_200px_200px_180px_auto]">
          <div className="relative">
            <Search className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-stone-400" />
            <Input className="pl-9" placeholder="Buscar por nombre, RIF o sector…" value={q} onChange={(e) => setQ(e.target.value)} />
          </div>
          <Select value={f.parroquia} onChange={(e) => set('parroquia', e.target.value)}>
            <option value="">Todas las parroquias</option>
            {cat?.parroquias.map((p) => <option key={p.id} value={p.id}>{p.nombre}</option>)}
          </Select>
          <Select value={f.rubro} onChange={(e) => set('rubro', e.target.value)}>
            <option value="">Todos los rubros</option>
            {cat?.rubros.map((r) => <option key={r.id} value={r.id}>{r.nombre}</option>)}
          </Select>
          <Select value={f.estado} onChange={(e) => set('estado', e.target.value)}>
            <option value="">Todos los estados</option>
            {cat?.estados.map((e) => <option key={e.value} value={e.value}>{e.label}</option>)}
          </Select>
          {activos > 0 && (
            <Button variant="ghost" icon={X} onClick={() => { setQ(''); setSp({}, { replace: true }) }}>Limpiar</Button>
          )}
        </div>
      </Card>

      <Card className="overflow-hidden">
        {isLoading ? (
          <div className="grid h-64 place-items-center"><Spinner className="size-7" /></div>
        ) : !data?.results.length ? (
          <Empty icon={SearchX} title="No hay consejos que coincidan" text="Prueba ajustando los filtros o la búsqueda." />
        ) : (
          <div className={isFetching ? 'opacity-60 transition-opacity' : 'transition-opacity'}>
            <div className="overflow-x-auto scrollbar-thin">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-stone-100 bg-stone-50/70 text-left text-xs font-medium tracking-wide text-stone-500 uppercase">
                    <th className="px-5 py-3">Consejo</th>
                    <th className="px-4 py-3">Ubicación</th>
                    <th className="px-4 py-3">Rubros</th>
                    <th className="px-4 py-3 text-right">Familias</th>
                    <th className="px-4 py-3 text-right">Superficie</th>
                    <th className="px-4 py-3">Registrado</th>
                    <th className="px-5 py-3">Estado</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-stone-100">
                  {data.results.map((c) => (
                    <tr key={c.id} className="group transition-colors hover:bg-brand-50/40">
                      <td className="px-5 py-3.5">
                        <Link to={`/consejos/${c.id}`} className="flex items-center gap-3">
                          <div className="grid size-9 shrink-0 place-items-center rounded-xl bg-brand-50 text-brand-700 transition-colors group-hover:bg-brand-100"><Sprout className="size-4.5" /></div>
                          <div className="min-w-0">
                            <p className="truncate font-medium text-stone-900 group-hover:text-brand-800">{c.nombre}</p>
                            <p className="text-xs text-stone-500">{c.rif || c.codigo_registro || 'Sin RIF'}</p>
                          </div>
                        </Link>
                      </td>
                      <td className="px-4 py-3.5">
                        <p className="text-stone-800">{c.parroquia.nombre}</p>
                        <p className="flex items-center gap-1 whitespace-nowrap text-xs text-stone-500"><MapPin className="size-3" />{c.sector || '—'}</p>
                      </td>
                      <td className="px-4 py-3.5">
                        <div className="flex max-w-[260px] flex-wrap gap-1">
                          {c.rubros.slice(0, 3).map((r) => <Chip key={r.id}>{r.nombre}</Chip>)}
                          {c.rubros.length > 3 && <Chip className="bg-stone-50 text-stone-500">+{c.rubros.length - 3}</Chip>}
                        </div>
                      </td>
                      <td className="px-4 py-3.5 text-right font-medium tabular-nums">{fmtNum(c.num_familias)}</td>
                      <td className="px-4 py-3.5 text-right text-stone-600 tabular-nums">{c.superficie_ha ? `${fmtNum(c.superficie_ha, 1)} ha` : '—'}</td>
                      <td className="px-4 py-3.5">
                        <p className="whitespace-nowrap text-stone-700">{fmtFecha(c.fecha_captura ?? c.creado)}</p>
                        <p className="whitespace-nowrap text-xs text-stone-500">{c.registrado_por?.nombre || c.registrado_por?.username || '—'}</p>
                      </td>
                      <td className="px-5 py-3.5"><EstadoBadge estado={c.estado} /></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <div className="flex items-center justify-between border-t border-stone-100 px-5 py-3 text-sm text-stone-500">
              <span>Mostrando {(page - 1) * PAGE_SIZE + 1}–{Math.min(page * PAGE_SIZE, total)} de {fmtNum(total)}</span>
              <div className="flex items-center gap-1">
                <Button variant="secondary" className="px-2" disabled={page <= 1} onClick={() => set('page', String(page - 1))}><ChevronLeft className="size-4" /></Button>
                <span className="px-3 tabular-nums">{page} / {pages}</span>
                <Button variant="secondary" className="px-2" disabled={page >= pages} onClick={() => set('page', String(page + 1))}><ChevronRight className="size-4" /></Button>
              </div>
            </div>
          </div>
        )}
      </Card>
    </div>
  )
}
