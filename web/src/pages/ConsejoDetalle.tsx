import { Link, useNavigate, useParams } from 'react-router-dom'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import {
  ArrowLeft, Bug, CalendarDays, Fish, Pencil, ShoppingBasket, Check, Crosshair, Droplets, FileText, Home, ImageOff, LandPlot, MapPin, Mountain,
  Phone, Smartphone, Sprout, Star, User, Users, Wheat, X,
} from 'lucide-react'
import type { LucideIcon } from 'lucide-react'
import type { ReactNode } from 'react'
import { ConsejosMap } from '../components/ConsejosMap'
import { Avatar, Button, Card, CardHeader, Chip, Empty, EstadoBadge, Spinner } from '../components/ui'
import { api } from '../lib/api'
import { useAuth } from '../lib/auth'
import { useCatalogos, useConsejo, usePuedeEditar } from '../lib/queries'
import { fmtFecha, fmtNum } from '../lib/format'
import type { CampoMultiple, Consejo, Estado } from '../lib/types'

function Dato({ icon: Icon, label, children }: { icon: LucideIcon; label: string; children: ReactNode }) {
  return (
    <div className="flex gap-3">
      <div className="grid size-9 shrink-0 place-items-center rounded-xl bg-stone-100 text-stone-500"><Icon className="size-4" /></div>
      <div className="min-w-0">
        <p className="text-xs text-stone-500">{label}</p>
        <p className="text-sm font-medium text-stone-900">{children || '—'}</p>
      </div>
    </div>
  )
}

export default function ConsejoDetalle() {
  const { id } = useParams()
  const { puedeValidar } = useAuth()
  const { data: c, isLoading } = useConsejo(id)
  const { data: cat } = useCatalogos()
  const qc = useQueryClient()
  const navigate = useNavigate()
  const puedeEditar = usePuedeEditar()

  const cambiarEstado = useMutation({
    mutationFn: (estado: Estado) => api<Consejo>(`/api/consejos/${id}/estado/`, { method: 'POST', body: JSON.stringify({ estado }) }),
    onSuccess: (_d, estado) => {
      toast.success(estado === 'validado' ? 'Registro validado' : estado === 'rechazado' ? 'Registro rechazado' : 'Estado actualizado')
      qc.invalidateQueries()
    },
    onError: (e: Error) => toast.error(e.message),
  })

  if (isLoading || !c) return <div className="grid h-full place-items-center"><Spinner className="size-8" /></div>

  const label = (list: { value: string; label: string }[] | undefined, v: string) => list?.find((x) => x.value === v)?.label ?? v
  const miembros = c.num_hombres + c.num_mujeres

  return (
    <div className="mx-auto max-w-[1300px] p-4 sm:p-8">
      <Link to="/consejos" className="mb-4 inline-flex items-center gap-1.5 text-sm text-stone-500 hover:text-stone-800">
        <ArrowLeft className="size-4" /> Volver al listado
      </Link>

      <div className="relative mb-6 overflow-hidden rounded-3xl bg-brand-900 p-6 text-white sm:p-8">
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top_right,rgba(52,211,153,0.35),transparent_60%),radial-gradient(ellipse_at_bottom_left,rgba(251,191,36,0.15),transparent_50%)]" />
        <div className="relative flex flex-wrap items-start justify-between gap-6">
          <div className="flex items-start gap-4">
            <div className="grid size-14 shrink-0 place-items-center rounded-2xl bg-white/10 ring-1 ring-white/20"><Sprout className="size-7" /></div>
            <div>
              <div className="mb-2 flex flex-wrap items-center gap-2">
                <EstadoBadge estado={c.estado} className="ring-0" />
                {c.rif && <span className="rounded-full bg-white/10 px-2.5 py-0.5 text-xs">{c.rif}</span>}
                {c.codigo_registro && <span className="rounded-full bg-white/10 px-2.5 py-0.5 text-xs">Reg. {c.codigo_registro}</span>}
              </div>
              <h1 className="text-2xl font-semibold tracking-tight sm:text-3xl">{c.nombre}</h1>
              <p className="mt-1 flex items-center gap-1.5 text-sm text-brand-100/80">
                <MapPin className="size-4" /> {c.sector ? `${c.sector}, ` : ''}parroquia {c.parroquia.nombre} · Municipio Vargas
              </p>
            </div>
          </div>
          {(puedeValidar || puedeEditar(c)) && (
            <div className="flex gap-2">
              {puedeEditar(c) && (
                <Button variant="secondary" icon={Pencil} className="bg-white/10 text-white ring-white/20 hover:bg-white/20" onClick={() => navigate(`/consejos/${c.id}/editar`)}>
                  Editar
                </Button>
              )}
              {puedeValidar && c.estado !== 'rechazado' && (
                <Button variant="secondary" icon={X} className="bg-white/10 text-white ring-white/20 hover:bg-white/20"
                  loading={cambiarEstado.isPending && cambiarEstado.variables === 'rechazado'} onClick={() => cambiarEstado.mutate('rechazado')}>
                  Rechazar
                </Button>
              )}
              {puedeValidar && c.estado !== 'validado' && (
                <Button variant="success" icon={Check} className="bg-emerald-500 hover:bg-emerald-400"
                  loading={cambiarEstado.isPending && cambiarEstado.variables === 'validado'} onClick={() => cambiarEstado.mutate('validado')}>
                  Validar registro
                </Button>
              )}
            </div>
          )}
        </div>
        <div className="relative mt-8 grid grid-cols-2 gap-3 sm:grid-cols-4">
          {[
            { l: 'Familias', v: fmtNum(c.num_familias), i: Home },
            { l: 'Miembros', v: fmtNum(miembros), i: Users },
            { l: 'Jóvenes', v: fmtNum(c.num_jovenes), i: User },
            { l: 'Superficie', v: c.superficie_ha ? `${fmtNum(c.superficie_ha, 1)} ha` : '—', i: LandPlot },
          ].map(({ l, v, i: Icon }) => (
            <div key={l} className="rounded-2xl bg-white/10 px-4 py-3 ring-1 ring-white/10 backdrop-blur">
              <p className="flex items-center gap-1.5 text-xs text-brand-100/70"><Icon className="size-3.5" />{l}</p>
              <p className="mt-1 text-2xl font-semibold tabular-nums">{v}</p>
            </div>
          ))}
        </div>
      </div>

      <div className="grid gap-6 lg:grid-cols-3">
        <div className="space-y-6 lg:col-span-2">
          <Card>
            <CardHeader title="Producción y territorio" icon={Wheat} />
            <div className="px-5 pb-5">
              <div className="mb-5 flex flex-wrap gap-2">
                {c.rubros.length ? c.rubros.map((r) => <Chip key={r.id} className="bg-amber-50 px-2.5 py-1 text-amber-800">{r.nombre}</Chip>) : <span className="text-sm text-stone-500">Sin rubros registrados</span>}
              </div>
              <div className="grid gap-5 sm:grid-cols-2">
                <Dato icon={LandPlot} label="Tenencia de la tierra">{label(cat?.tenencia_tierra, c.tenencia_tierra)}</Dato>
                <Dato icon={Droplets} label="Fuente de agua">{label(cat?.fuente_agua, c.fuente_agua)}</Dato>
                <Dato icon={Droplets} label="Sistema de riego">{c.tiene_riego ? 'Sí cuenta con riego' : 'No cuenta con riego'}</Dato>
                <Dato icon={CalendarDays} label="Fecha de constitución">{fmtFecha(c.fecha_constitucion)}</Dato>
                <Dato icon={Users} label="Composición">{`${c.num_hombres} hombres · ${c.num_mujeres} mujeres`}</Dato>
                <Dato icon={MapPin} label="Dirección">{c.direccion}</Dato>
              </div>
            </div>
          </Card>

          <Card>
            <CardHeader title="Sanidad, destino y producción animal" icon={Bug} />
            <div className="grid gap-5 px-5 pb-5 sm:grid-cols-2">
              {([
                ['tipos_cultivo', 'Tipo de cultivo', Wheat, 'bg-brand-50 text-brand-800'],
                ['enfermedades', 'Enfermedades en la cosecha', Bug, 'bg-rose-50 text-rose-800'],
                ['plagas', 'Plagas', Bug, 'bg-rose-50 text-rose-800'],
                ['destino_produccion', 'Destino de la producción', ShoppingBasket, 'bg-sky-50 text-sky-800'],
                ['produccion_animal', 'Producción animal', Fish, 'bg-amber-50 text-amber-800'],
              ] as [CampoMultiple, string, LucideIcon, string][]).map(([k, titulo, Icon, tono]) => (
                <div key={k}>
                  <p className="mb-2 flex items-center gap-1.5 text-xs font-medium text-stone-500"><Icon className="size-3.5" />{titulo}</p>
                  <div className="flex flex-wrap gap-1.5">
                    {c[k]?.length ? c[k].map((v) => <Chip key={v} className={`px-2.5 py-1 ${tono}`}>{label(cat?.[k], v)}</Chip>)
                      : <span className="text-sm text-stone-400">Ninguno</span>}
                  </div>
                </div>
              ))}
              <div className="sm:col-span-2">
                <p className="mb-1 flex items-center gap-1.5 text-xs font-medium text-stone-500"><FileText className="size-3.5" />Requerimientos - otros</p>
                <p className="text-sm leading-relaxed whitespace-pre-line text-stone-700">{c.requerimientos || 'Sin requerimientos registrados.'}</p>
              </div>
            </div>
          </Card>

          <Card>
            <CardHeader title="Voceros y voceras" subtitle={`${c.voceros.length} registrados`} icon={Users} />
            {c.voceros.length === 0 ? <Empty icon={Users} title="Sin voceros registrados" /> : (
              <div className="grid gap-3 px-5 pb-5 sm:grid-cols-2">
                {c.voceros.map((v, i) => (
                  <div key={v.id ?? i} className="flex items-center gap-3 rounded-2xl bg-stone-50 p-3 ring-1 ring-stone-100">
                    <Avatar name={v.nombre} className="size-10" />
                    <div className="min-w-0 flex-1">
                      <p className="flex items-center gap-1.5 truncate text-sm font-medium text-stone-900">
                        {v.nombre} {v.es_principal && <Star className="size-3.5 fill-amber-400 text-amber-400" />}
                      </p>
                      <p className="text-xs text-stone-500">{v.cargo || 'Vocero'} · {v.cedula}</p>
                    </div>
                    {v.telefono && (
                      <a href={`tel:${v.telefono}`} className="flex items-center gap-1 rounded-lg px-2 py-1 text-xs font-medium text-brand-700 hover:bg-brand-50">
                        <Phone className="size-3.5" />{v.telefono}
                      </a>
                    )}
                  </div>
                ))}
              </div>
            )}
          </Card>

          <div className="grid gap-6 sm:grid-cols-2">
            <Card>
              <CardHeader title="Necesidades" icon={FileText} />
              <p className="px-5 pb-5 text-sm leading-relaxed whitespace-pre-line text-stone-700">{c.necesidades || 'No se registraron necesidades.'}</p>
            </Card>
            <Card>
              <CardHeader title="Observaciones" icon={FileText} />
              <p className="px-5 pb-5 text-sm leading-relaxed whitespace-pre-line text-stone-700">{c.observaciones || 'Sin observaciones.'}</p>
            </Card>
          </div>

          <Card>
            <CardHeader title="Registro fotográfico" subtitle={`${c.fotos.length} fotos`} icon={ImageOff} />
            {c.fotos.length === 0 ? <Empty icon={ImageOff} title="Sin fotografías" text="Las fotos tomadas desde la app móvil aparecerán aquí." /> : (
              <div className="grid grid-cols-2 gap-3 px-5 pb-5 sm:grid-cols-3">
                {c.fotos.map((f) => (
                  <a key={f.id} href={f.url} target="_blank" rel="noreferrer" className="group relative aspect-[4/3] overflow-hidden rounded-xl bg-stone-100">
                    <img src={f.url} alt={f.descripcion} className="size-full object-cover transition-transform group-hover:scale-105" />
                    {f.descripcion && <span className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-black/60 p-2 text-xs text-white">{f.descripcion}</span>}
                  </a>
                ))}
              </div>
            )}
          </Card>
        </div>

        <div className="space-y-6">
          <Card className="overflow-hidden">
            <CardHeader title="Georreferenciación" icon={Crosshair} />
            <ConsejosMap single={{ lat: c.lat, lng: c.lng }} className="h-64 border-y border-stone-100" />
            <div className="grid grid-cols-2 gap-4 p-5">
              <Dato icon={Crosshair} label="Latitud">{c.lat.toFixed(6)}</Dato>
              <Dato icon={Crosshair} label="Longitud">{c.lng.toFixed(6)}</Dato>
              <Dato icon={Crosshair} label="Precisión GPS">{c.precision_gps_m != null ? `± ${fmtNum(c.precision_gps_m, 1)} m` : '—'}</Dato>
              <Dato icon={Mountain} label="Altitud">{c.altitud_m != null ? `${fmtNum(c.altitud_m)} m s.n.m.` : '—'}</Dato>
            </div>
            <div className="px-5 pb-5">
              <a className="text-xs font-medium text-brand-700 hover:underline" target="_blank" rel="noreferrer"
                href={`https://www.openstreetmap.org/?mlat=${c.lat}&mlon=${c.lng}#map=16/${c.lat}/${c.lng}`}>Abrir en OpenStreetMap →</a>
            </div>
          </Card>

          <Card>
            <CardHeader title="Datos del registro" icon={Smartphone} />
            <div className="space-y-4 px-5 pb-5">
              <Dato icon={User} label="Encuestador">{c.registrado_por?.nombre || c.registrado_por?.username}</Dato>
              <Dato icon={CalendarDays} label="Captura en campo">{fmtFecha(c.fecha_captura, true)}</Dato>
              <Dato icon={CalendarDays} label="Última actualización">{fmtFecha(c.actualizado, true)}</Dato>
              <Dato icon={Smartphone} label="Dispositivo">{c.dispositivo_id}</Dato>
            </div>
          </Card>
        </div>
      </div>
    </div>
  )
}
