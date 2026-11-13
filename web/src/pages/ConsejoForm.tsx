import { useEffect, useState, type FormEvent, type ReactNode } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import {
  ArrowLeft, Bug, Camera, Check, ClipboardList, Crosshair, FileText, Fish, LandPlot, LocateFixed, MapPin, Plus,
  Save, ShoppingBasket, Sprout, Star, Trash2, Users, Wheat, X,
} from 'lucide-react'
import type { LucideIcon } from 'lucide-react'
import clsx from 'clsx'
import { PageHeader } from '../components/Layout'
import { LocationPicker } from '../components/LocationPicker'
import { Button, Card, CardHeader, Input, Label, Select, Spinner } from '../components/ui'
import { api } from '../lib/api'
import { useCatalogos, useConsejo, usePuedeEditar } from '../lib/queries'
import type { CampoMultiple, Consejo, Opcion, Vocero } from '../lib/types'

interface FormState {
  nombre: string
  rif: string
  codigo_registro: string
  parroquia_id: string
  sector: string
  direccion: string
  lat: number | null
  lng: number | null
  precision_gps_m: number | null
  altitud_m: string
  fecha_constitucion: string
  num_familias: string
  num_hombres: string
  num_mujeres: string
  num_jovenes: string
  superficie_ha: string
  tenencia_tierra: string
  fuente_agua: string
  tiene_riego: boolean
  rubro_ids: number[]
  enfermedades: string[]
  plagas: string[]
  destino_produccion: string[]
  tipos_cultivo: string[]
  produccion_animal: string[]
  requerimientos: string
  necesidades: string
  observaciones: string
  voceros: Vocero[]
}

const VACIO: FormState = {
  nombre: '', rif: '', codigo_registro: '', parroquia_id: '', sector: '', direccion: '',
  lat: null, lng: null, precision_gps_m: null, altitud_m: '', fecha_constitucion: '',
  num_familias: '', num_hombres: '', num_mujeres: '', num_jovenes: '', superficie_ha: '',
  tenencia_tierra: '', fuente_agua: '', tiene_riego: false, rubro_ids: [],
  enfermedades: [], plagas: [], destino_produccion: [], tipos_cultivo: [], produccion_animal: [],
  requerimientos: '', necesidades: '', observaciones: '', voceros: [],
}

const VOCERO_VACIO: Vocero = { nombre: '', cedula: '', telefono: '', cargo: '', es_principal: false }

const str = (v: number | string | null | undefined) => (v == null ? '' : String(v))

function desdeConsejo(c: Consejo): FormState {
  return {
    nombre: c.nombre, rif: c.rif, codigo_registro: c.codigo_registro, parroquia_id: String(c.parroquia.id),
    sector: c.sector, direccion: c.direccion, lat: c.lat, lng: c.lng, precision_gps_m: c.precision_gps_m,
    altitud_m: str(c.altitud_m), fecha_constitucion: c.fecha_constitucion ?? '',
    num_familias: str(c.num_familias), num_hombres: str(c.num_hombres), num_mujeres: str(c.num_mujeres),
    num_jovenes: str(c.num_jovenes), superficie_ha: str(c.superficie_ha),
    tenencia_tierra: c.tenencia_tierra, fuente_agua: c.fuente_agua, tiene_riego: c.tiene_riego,
    rubro_ids: c.rubros.map((r) => r.id),
    enfermedades: c.enfermedades ?? [], plagas: c.plagas ?? [], destino_produccion: c.destino_produccion ?? [],
    tipos_cultivo: c.tipos_cultivo ?? [], produccion_animal: c.produccion_animal ?? [],
    requerimientos: c.requerimientos ?? '', necesidades: c.necesidades, observaciones: c.observaciones,
    voceros: c.voceros.map(({ nombre, cedula, telefono, cargo, es_principal }) => ({ nombre, cedula, telefono, cargo, es_principal })),
  }
}

function aPayload(f: FormState) {
  const int = (v: string) => (v === '' ? 0 : Math.max(0, Math.trunc(Number(v))))
  return {
    ...f,
    parroquia_id: Number(f.parroquia_id),
    altitud_m: f.altitud_m === '' ? null : Number(f.altitud_m),
    fecha_constitucion: f.fecha_constitucion || null,
    num_familias: int(f.num_familias), num_hombres: int(f.num_hombres),
    num_mujeres: int(f.num_mujeres), num_jovenes: int(f.num_jovenes),
    superficie_ha: f.superficie_ha === '' ? null : f.superficie_ha,
    voceros: f.voceros.filter((v) => v.nombre.trim()),
  }
}

function nuevoUuid() {
  const b = crypto.getRandomValues(new Uint8Array(16))
  b[6] = (b[6] & 0x0f) | 0x40
  b[8] = (b[8] & 0x3f) | 0x80
  const h = [...b].map((x) => x.toString(16).padStart(2, '0')).join('')
  return `${h.slice(0, 8)}-${h.slice(8, 12)}-${h.slice(12, 16)}-${h.slice(16, 20)}-${h.slice(20)}`
}

function Seccion({ n, title, subtitle, icon, children }: { n: number; title: string; subtitle?: string; icon: LucideIcon; children: ReactNode }) {
  return (
    <Card>
      <CardHeader title={`${n}. ${title}`} subtitle={subtitle} icon={icon} />
      <div className="px-5 pb-5">{children}</div>
    </Card>
  )
}

function Opciones({ opciones, value, onChange, tono = 'brand' }: { opciones: Opcion[]; value: string[]; onChange: (v: string[]) => void; tono?: 'brand' | 'amber' | 'rose' | 'sky' }) {
  const activo = {
    brand: 'bg-brand-50 text-brand-800 ring-brand-300',
    amber: 'bg-amber-50 text-amber-800 ring-amber-300',
    rose: 'bg-rose-50 text-rose-800 ring-rose-300',
    sky: 'bg-sky-50 text-sky-800 ring-sky-300',
  }[tono]
  return (
    <div className="flex flex-wrap gap-2">
      {opciones.map((o) => {
        const on = value.includes(o.value)
        return (
          <button type="button" key={o.value} aria-pressed={on}
            onClick={() => onChange(on ? value.filter((v) => v !== o.value) : [...value, o.value])}
            className={clsx('inline-flex items-center gap-1.5 rounded-xl px-3 py-2 text-sm font-medium ring-1 transition-all',
              on ? `${activo} shadow-sm` : 'bg-white text-stone-600 ring-stone-200 hover:bg-stone-50')}>
            <span className={clsx('grid size-4 place-items-center rounded-md ring-1', on ? 'bg-current ring-transparent' : 'ring-stone-300')}>
              {on && <Check className="size-3 text-white" strokeWidth={3} />}
            </span>
            {o.label}
          </button>
        )
      })}
    </div>
  )
}

function Campo({ label, children, className }: { label: string; children: ReactNode; className?: string }) {
  return <div className={className}><Label>{label}</Label>{children}</div>
}

const textarea = 'w-full rounded-xl border-0 bg-white px-3 py-2 text-sm text-stone-800 shadow-sm ring-1 ring-stone-200 placeholder:text-stone-400 focus:ring-2 focus:ring-brand-600 focus:outline-none'

export default function ConsejoForm() {
  const { id } = useParams()
  const editando = !!id
  const navigate = useNavigate()
  const qc = useQueryClient()
  const { data: cat } = useCatalogos()
  const { data: existente, isLoading } = useConsejo(id)
  const puedeEditar = usePuedeEditar()
  const [f, setF] = useState<FormState>(VACIO)
  const [fotos, setFotos] = useState<File[]>([])
  const [ubicando, setUbicando] = useState(false)

  useEffect(() => { if (existente) setF(desdeConsejo(existente)) }, [existente])

  const set = <K extends keyof FormState>(k: K, v: FormState[K]) => setF((p) => ({ ...p, [k]: v }))
  const setMulti = (k: CampoMultiple) => (v: string[]) => set(k, v)

  const guardar = useMutation({
    mutationFn: async () => {
      const body = JSON.stringify(aPayload(f))
      const c = editando
        ? await api<Consejo>(`/api/consejos/${id}/`, { method: 'PATCH', body })
        : await api<Consejo>('/api/consejos/', { method: 'POST', body })
      for (const file of fotos) {
        const fd = new FormData()
        fd.append('uuid', nuevoUuid())
        fd.append('imagen', file)
        fd.append('descripcion', file.name.replace(/\.[^.]+$/, ''))
        await api(`/api/consejos/${c.id}/fotos/`, { method: 'POST', body: fd })
      }
      return c
    },
    onSuccess: (c) => {
      toast.success(editando ? 'Registro actualizado' : 'Registro guardado correctamente')
      qc.invalidateQueries()
      navigate(`/consejos/${c.id}`)
    },
    onError: (e: Error) => toast.error(`No se pudo guardar: ${e.message}`),
  })

  const usarGps = () => {
    if (!navigator.geolocation) { toast.error('Este navegador no permite obtener la ubicación.'); return }
    setUbicando(true)
    navigator.geolocation.getCurrentPosition(
      (p) => {
        setF((prev) => ({
          ...prev, lat: p.coords.latitude, lng: p.coords.longitude, precision_gps_m: Math.round(p.coords.accuracy * 10) / 10,
          altitud_m: p.coords.altitude != null ? String(Math.round(p.coords.altitude)) : prev.altitud_m,
        }))
        setUbicando(false)
      },
      (e) => { toast.error(`No se pudo obtener la ubicación: ${e.message}`); setUbicando(false) },
      { enableHighAccuracy: true, timeout: 15000 },
    )
  }

  const enviar = (e: FormEvent) => {
    e.preventDefault()
    if (!f.nombre.trim()) return toast.error('Indica el nombre del consejo o productor.')
    if (!f.parroquia_id) return toast.error('Selecciona la parroquia.')
    if (f.lat == null || f.lng == null) return toast.error('Marca la ubicación en el mapa o usa el GPS.')
    guardar.mutate()
  }

  if (editando && (isLoading || !existente || !cat)) return <div className="grid h-full place-items-center"><Spinner className="size-8" /></div>
  if (editando && existente && !puedeEditar(existente)) {
    return <div className="p-8 text-sm text-stone-600">No tienes permiso para editar este registro.</div>
  }

  const voceros = f.voceros
  const setVocero = (i: number, patch: Partial<Vocero>) =>
    set('voceros', voceros.map((v, j) => (j === i ? { ...v, ...patch } : patch.es_principal ? { ...v, es_principal: false } : v)))

  return (
    <form onSubmit={enviar} className="mx-auto max-w-[1100px] p-4 pb-28 sm:p-8 sm:pb-28">
      <Link to={editando ? `/consejos/${id}` : '/consejos'} className="mb-4 inline-flex items-center gap-1.5 text-sm text-stone-500 hover:text-stone-800">
        <ArrowLeft className="size-4" /> {editando ? 'Volver a la ficha' : 'Volver al listado'}
      </Link>
      <PageHeader
        title={editando ? `Editar: ${existente?.nombre}` : 'Nuevo registro'}
        subtitle="Carga directa desde el panel. Los campos marcados con * son obligatorios."
      />

      <div className="space-y-6">
        <Seccion n={1} title="Identificación" subtitle="Datos de la organización o productor" icon={ClipboardList}>
          <div className="grid gap-4 sm:grid-cols-2">
            <Campo label="Nombre *" className="sm:col-span-2">
              <Input value={f.nombre} onChange={(e) => set('nombre', e.target.value)} placeholder="Ej.: Consejo Campesino Cerro Grande" required />
            </Campo>
            <Campo label="RIF / Cédula"><Input value={f.rif} onChange={(e) => set('rif', e.target.value)} placeholder="J-12345678-9" /></Campo>
            <Campo label="Código de registro"><Input value={f.codigo_registro} onChange={(e) => set('codigo_registro', e.target.value)} placeholder="LG-2025-001" /></Campo>
            <Campo label="Fecha de constitución"><Input type="date" value={f.fecha_constitucion} onChange={(e) => set('fecha_constitucion', e.target.value)} /></Campo>
          </div>
        </Seccion>

        <Seccion n={2} title="Ubicación" subtitle="Haz clic en el mapa, arrastra el marcador o usa el GPS del equipo" icon={MapPin}>
          <div className="grid gap-4 sm:grid-cols-2">
            <Campo label="Parroquia *">
              <Select value={f.parroquia_id} onChange={(e) => set('parroquia_id', e.target.value)} required>
                <option value="">Selecciona…</option>
                {cat?.parroquias.map((p) => <option key={p.id} value={p.id}>{p.nombre}</option>)}
              </Select>
            </Campo>
            <Campo label="Sector"><Input value={f.sector} onChange={(e) => set('sector', e.target.value)} /></Campo>
            <Campo label="Dirección" className="sm:col-span-2"><Input value={f.direccion} onChange={(e) => set('direccion', e.target.value)} /></Campo>
          </div>
          <LocationPicker
            value={f.lat != null && f.lng != null ? { lat: f.lat, lng: f.lng } : null}
            onChange={(lat, lng) => setF((p) => ({ ...p, lat, lng, precision_gps_m: null }))}
            className="mt-4 h-80 rounded-2xl ring-1 ring-stone-200"
          />
          <div className="mt-3 flex flex-wrap items-center gap-3">
            <Button type="button" variant="secondary" icon={LocateFixed} loading={ubicando} onClick={usarGps}>Usar mi ubicación</Button>
            <div className="flex flex-wrap gap-2 text-xs text-stone-600">
              <span className="inline-flex items-center gap-1 rounded-lg bg-stone-100 px-2 py-1"><Crosshair className="size-3.5" />
                {f.lat != null && f.lng != null ? `${f.lat.toFixed(6)}, ${f.lng.toFixed(6)}` : 'Sin coordenadas'}
              </span>
              {f.precision_gps_m != null && <span className="rounded-lg bg-stone-100 px-2 py-1">± {f.precision_gps_m} m</span>}
            </div>
            <div className="ml-auto w-40"><Input type="number" step="any" placeholder="Altitud (m)" value={f.altitud_m} onChange={(e) => set('altitud_m', e.target.value)} /></div>
          </div>
        </Seccion>

        <Seccion n={3} title="Población" icon={Users}>
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
            {([['num_familias', 'Familias'], ['num_hombres', 'Hombres'], ['num_mujeres', 'Mujeres'], ['num_jovenes', 'Jóvenes']] as const).map(([k, l]) => (
              <Campo key={k} label={l}><Input type="number" min={0} value={f[k]} onChange={(e) => set(k, e.target.value)} placeholder="0" /></Campo>
            ))}
          </div>
        </Seccion>

        <Seccion n={4} title="Tierra y producción agrícola" icon={LandPlot}>
          <div className="grid gap-4 sm:grid-cols-3">
            <Campo label="Superficie (ha)"><Input type="number" min={0} step="0.01" value={f.superficie_ha} onChange={(e) => set('superficie_ha', e.target.value)} /></Campo>
            <Campo label="Tenencia de la tierra">
              <Select value={f.tenencia_tierra} onChange={(e) => set('tenencia_tierra', e.target.value)}>
                <option value="">—</option>
                {cat?.tenencia_tierra.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
              </Select>
            </Campo>
            <Campo label="Fuente de agua">
              <Select value={f.fuente_agua} onChange={(e) => set('fuente_agua', e.target.value)}>
                <option value="">—</option>
                {cat?.fuente_agua.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
              </Select>
            </Campo>
          </div>
          <label className="mt-4 inline-flex cursor-pointer items-center gap-2 text-sm text-stone-700">
            <input type="checkbox" className="size-4 accent-brand-700" checked={f.tiene_riego} onChange={(e) => set('tiene_riego', e.target.checked)} />
            Cuenta con sistema de riego
          </label>
          <div className="mt-5">
            <Label>Tipo de cultivo</Label>
            <Opciones opciones={cat?.tipos_cultivo ?? []} value={f.tipos_cultivo} onChange={setMulti('tipos_cultivo')} />
          </div>
          <div className="mt-5">
            <Label>Rubros</Label>
            <Opciones tono="amber" opciones={(cat?.rubros ?? []).map((r) => ({ value: String(r.id), label: r.nombre }))}
              value={f.rubro_ids.map(String)} onChange={(v) => set('rubro_ids', v.map(Number))} />
          </div>
        </Seccion>

        <Seccion n={5} title="Sanidad de la cosecha" subtitle="Marca lo que se haya presentado" icon={Bug}>
          <div className="grid gap-5 sm:grid-cols-2">
            <div><Label>Enfermedades</Label><Opciones tono="rose" opciones={cat?.enfermedades ?? []} value={f.enfermedades} onChange={setMulti('enfermedades')} /></div>
            <div><Label>Plagas</Label><Opciones tono="rose" opciones={cat?.plagas ?? []} value={f.plagas} onChange={setMulti('plagas')} /></div>
          </div>
        </Seccion>

        <Seccion n={6} title="Destino de la producción" icon={ShoppingBasket}>
          <Opciones tono="sky" opciones={cat?.destino_produccion ?? []} value={f.destino_produccion} onChange={setMulti('destino_produccion')} />
        </Seccion>

        <Seccion n={7} title="Producción animal" icon={Fish}>
          <Opciones tono="amber" opciones={cat?.produccion_animal ?? []} value={f.produccion_animal} onChange={setMulti('produccion_animal')} />
        </Seccion>

        <Seccion n={8} title="Voceros y voceras" subtitle="Personas de contacto" icon={Users}>
          <div className="space-y-3">
            {voceros.map((v, i) => (
              <div key={i} className="grid items-end gap-3 rounded-2xl bg-stone-50 p-3 ring-1 ring-stone-100 sm:grid-cols-[1.4fr_1fr_1fr_1fr_auto]">
                <Campo label="Nombre"><Input value={v.nombre} onChange={(e) => setVocero(i, { nombre: e.target.value })} /></Campo>
                <Campo label="Cédula"><Input value={v.cedula} onChange={(e) => setVocero(i, { cedula: e.target.value })} /></Campo>
                <Campo label="Teléfono"><Input value={v.telefono} onChange={(e) => setVocero(i, { telefono: e.target.value })} /></Campo>
                <Campo label="Cargo"><Input value={v.cargo} onChange={(e) => setVocero(i, { cargo: e.target.value })} /></Campo>
                <div className="flex gap-1 pb-0.5">
                  <button type="button" title="Vocero principal" onClick={() => setVocero(i, { es_principal: !v.es_principal })}
                    className={clsx('rounded-lg p-2', v.es_principal ? 'text-amber-500' : 'text-stone-400 hover:bg-white')}>
                    <Star className={clsx('size-4', v.es_principal && 'fill-amber-400')} />
                  </button>
                  <button type="button" title="Quitar" onClick={() => set('voceros', voceros.filter((_, j) => j !== i))} className="rounded-lg p-2 text-stone-400 hover:bg-white hover:text-rose-600">
                    <Trash2 className="size-4" />
                  </button>
                </div>
              </div>
            ))}
            <Button type="button" variant="secondary" icon={Plus} onClick={() => set('voceros', [...voceros, { ...VOCERO_VACIO, es_principal: voceros.length === 0 }])}>
              Agregar vocero
            </Button>
          </div>
        </Seccion>

        <Seccion n={9} title="Requerimientos y observaciones" icon={FileText}>
          <div className="grid gap-4 sm:grid-cols-2">
            <Campo label="Requerimientos - otros" className="sm:col-span-2">
              <textarea rows={3} className={textarea} value={f.requerimientos} onChange={(e) => set('requerimientos', e.target.value)} placeholder="Insumos, maquinaria, financiamiento, asistencia técnica…" />
            </Campo>
            <Campo label="Necesidades"><textarea rows={3} className={textarea} value={f.necesidades} onChange={(e) => set('necesidades', e.target.value)} /></Campo>
            <Campo label="Observaciones"><textarea rows={3} className={textarea} value={f.observaciones} onChange={(e) => set('observaciones', e.target.value)} /></Campo>
          </div>
        </Seccion>

        <Seccion n={10} title="Fotografías" subtitle="Opcional" icon={Camera}>
          <label className="flex cursor-pointer flex-col items-center justify-center gap-2 rounded-2xl border-2 border-dashed border-stone-200 py-8 text-sm text-stone-500 hover:border-brand-300 hover:bg-brand-50/40">
            <Camera className="size-6 text-stone-400" />
            Selecciona una o varias imágenes
            <input type="file" accept="image/*" multiple className="hidden" onChange={(e) => setFotos([...fotos, ...Array.from(e.target.files ?? [])])} />
          </label>
          {fotos.length > 0 && (
            <div className="mt-3 flex flex-wrap gap-2">
              {fotos.map((file, i) => (
                <span key={i} className="inline-flex items-center gap-1.5 rounded-lg bg-stone-100 px-2 py-1 text-xs text-stone-700">
                  {file.name}
                  <button type="button" onClick={() => setFotos(fotos.filter((_, j) => j !== i))}><X className="size-3.5" /></button>
                </span>
              ))}
            </div>
          )}
        </Seccion>
      </div>

      <div className="fixed right-0 bottom-0 left-0 z-30 border-t border-stone-200 bg-white/90 backdrop-blur lg:left-64">
        <div className="mx-auto flex max-w-[1100px] items-center justify-between gap-3 px-4 py-3 sm:px-8">
          <p className="hidden items-center gap-2 text-xs text-stone-500 sm:flex"><Sprout className="size-4 text-brand-600" /><Wheat className="size-4 text-amber-500" />
            Quedará en estado «Enviado» hasta que un supervisor lo valide.</p>
          <div className="ml-auto flex gap-2">
            <Button type="button" variant="ghost" onClick={() => navigate(-1)}>Cancelar</Button>
            <Button type="submit" icon={Save} loading={guardar.isPending}>{editando ? 'Guardar cambios' : 'Guardar registro'}</Button>
          </div>
        </div>
      </div>
    </form>
  )
}
