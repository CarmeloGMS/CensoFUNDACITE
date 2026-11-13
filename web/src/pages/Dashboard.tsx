import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { Area, AreaChart, Bar, BarChart, CartesianGrid, Cell, Pie, PieChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts'
import { ArrowRight, BarChart3, CheckCircle2, Clock, Home, LandPlot, Map as MapIcon, Sprout, TrendingUp, Users, Wheat } from 'lucide-react'
import { PageHeader } from '../components/Layout'
import { StatCard } from '../components/StatCard'
import { Card, CardHeader, EstadoBadge, Select, Spinner } from '../components/ui'
import { ConsejosMap } from '../components/ConsejosMap'
import { useAuth } from '../lib/auth'
import { useCatalogos, useConsejos, useEstadisticas, useGeojson } from '../lib/queries'
import { ESTADO_META, fmtFecha, fmtMes, fmtNum } from '../lib/format'

const tooltipStyle = { borderRadius: 12, border: '1px solid #e7e5e4', boxShadow: '0 8px 24px rgba(0,0,0,.08)', fontSize: 12 }

export default function Dashboard() {
  const { user } = useAuth()
  const navigate = useNavigate()
  const [parroquia, setParroquia] = useState('')
  const f = { parroquia }
  const { data: cat } = useCatalogos()
  const { data: st, isLoading } = useEstadisticas(f)
  const { data: geo } = useGeojson(f)
  const { data: recientes } = useConsejos({ ...f, page_size: 6, ordering: '-fecha_captura' })

  const estados = st ? [
    { name: ESTADO_META.validado.label, value: st.validados, color: ESTADO_META.validado.color },
    { name: ESTADO_META.enviado.label, value: st.pendientes, color: ESTADO_META.enviado.color },
    { name: ESTADO_META.rechazado.label, value: st.rechazados, color: ESTADO_META.rechazado.color },
  ] : []
  const pctValidado = st && st.total ? Math.round((st.validados / st.total) * 100) : 0
  const porParroquia = [...(st?.por_parroquia ?? [])].sort((a, b) => b.total - a.total)
  const porRubro = [...(st?.por_rubro ?? [])].sort((a, b) => b.total - a.total).slice(0, 8)
  const hora = new Date().getHours()
  const saludo = hora < 12 ? 'Buenos días' : hora < 19 ? 'Buenas tardes' : 'Buenas noches'

  return (
    <div className="mx-auto max-w-[1400px] p-4 sm:p-8">
      <PageHeader
        title={`${saludo}, ${user?.first_name || user?.username}`}
        subtitle="Resumen del censo de consejos campesinos del estado La Guaira"
        actions={
          <Select value={parroquia} onChange={(e) => setParroquia(e.target.value)} className="w-56">
            <option value="">Todas las parroquias</option>
            {cat?.parroquias.map((p) => <option key={p.id} value={p.id}>{p.nombre}</option>)}
          </Select>
        }
      />

      {isLoading || !st ? (
        <div className="grid h-64 place-items-center"><Spinner className="size-8" /></div>
      ) : (
        <div className="space-y-6">
          <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            <StatCard label="Consejos registrados" value={fmtNum(st.total)} icon={Sprout} tone="brand"
              hint={<span className="inline-flex items-center gap-1"><CheckCircle2 className="size-3 text-emerald-600" />{pctValidado}% validados</span>} />
            <StatCard label="Familias" value={fmtNum(st.familias)} icon={Home} tone="amber" hint="Núcleos familiares vinculados" />
            <StatCard label="Productores" value={fmtNum(st.miembros)} icon={Users} tone="sky" hint="Hombres y mujeres miembros" />
            <StatCard label="Superficie" value={<>{fmtNum(st.superficie_ha, 1)}<span className="ml-1 text-base font-medium text-stone-400">ha</span></>} icon={LandPlot} tone="violet" hint="Área productiva declarada" />
          </div>

          <div className="grid gap-6 xl:grid-cols-3">
            <Card className="overflow-hidden xl:col-span-2">
              <CardHeader title="Distribución geográfica" subtitle={`${geo?.features.length ?? 0} consejos georreferenciados`} icon={MapIcon}
                action={<Link to="/mapa" className="inline-flex items-center gap-1 text-xs font-medium text-brand-700 hover:text-brand-800">Mapa completo <ArrowRight className="size-3.5" /></Link>} />
              <ConsejosMap data={geo} onNavigate={navigate} className="h-[420px] border-t border-stone-100" />
            </Card>

            <Card>
              <CardHeader title="Estado de validación" subtitle="Revisión de los registros de campo" icon={CheckCircle2} />
              <div className="relative h-52">
                <ResponsiveContainer>
                  <PieChart>
                    <Pie data={estados} dataKey="value" innerRadius={62} outerRadius={88} paddingAngle={3} cornerRadius={6} stroke="none">
                      {estados.map((e) => <Cell key={e.name} fill={e.color} />)}
                    </Pie>
                    <Tooltip contentStyle={tooltipStyle} />
                  </PieChart>
                </ResponsiveContainer>
                <div className="pointer-events-none absolute inset-0 grid place-items-center">
                  <div className="text-center">
                    <p className="text-3xl font-semibold text-stone-900">{pctValidado}%</p>
                    <p className="text-xs text-stone-500">validado</p>
                  </div>
                </div>
              </div>
              <div className="space-y-2 px-5 pb-5">
                {estados.map((e) => (
                  <div key={e.name} className="flex items-center justify-between rounded-xl bg-stone-50 px-3 py-2 text-sm">
                    <span className="flex items-center gap-2 text-stone-600"><span className="size-2.5 rounded-full" style={{ background: e.color }} />{e.name}</span>
                    <span className="font-semibold text-stone-900 tabular-nums">{fmtNum(e.value)}</span>
                  </div>
                ))}
              </div>
            </Card>
          </div>

          <div className="grid gap-6 xl:grid-cols-2">
            <Card>
              <CardHeader title="Consejos por parroquia" subtitle="Municipio Vargas" icon={BarChart3} />
              <div className="h-80 px-3 pb-4">
                <ResponsiveContainer>
                  <BarChart data={porParroquia} layout="vertical" margin={{ left: 10, right: 24 }}>
                    <defs>
                      <linearGradient id="gp" x1="0" y1="0" x2="1" y2="0">
                        <stop offset="0%" stopColor="#10b981" /><stop offset="100%" stopColor="#047857" />
                      </linearGradient>
                    </defs>
                    <CartesianGrid horizontal={false} stroke="#f5f5f4" />
                    <XAxis type="number" allowDecimals={false} tick={{ fontSize: 11, fill: '#a8a29e' }} axisLine={false} tickLine={false} />
                    <YAxis type="category" dataKey="parroquia" width={120} tick={{ fontSize: 12, fill: '#57534e' }} axisLine={false} tickLine={false} />
                    <Tooltip contentStyle={tooltipStyle} cursor={{ fill: '#f5f5f4' }} formatter={(v) => [v, 'Consejos']} />
                    <Bar dataKey="total" fill="url(#gp)" radius={[0, 8, 8, 0]} barSize={16} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </Card>

            <Card>
              <CardHeader title="Rubros principales" subtitle="Consejos que producen cada rubro" icon={Wheat} />
              <div className="h-80 px-3 pb-4">
                <ResponsiveContainer>
                  <BarChart data={porRubro} margin={{ top: 8, right: 12, bottom: 30 }}>
                    <defs>
                      <linearGradient id="gr" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stopColor="#f59e0b" /><stop offset="100%" stopColor="#d97706" />
                      </linearGradient>
                    </defs>
                    <CartesianGrid vertical={false} stroke="#f5f5f4" />
                    <XAxis dataKey="rubro" tick={{ fontSize: 11, fill: '#57534e' }} angle={-25} textAnchor="end" interval={0} axisLine={false} tickLine={false} />
                    <YAxis allowDecimals={false} tick={{ fontSize: 11, fill: '#a8a29e' }} axisLine={false} tickLine={false} width={30} />
                    <Tooltip contentStyle={tooltipStyle} cursor={{ fill: '#f5f5f4' }} formatter={(v) => [v, 'Consejos']} />
                    <Bar dataKey="total" fill="url(#gr)" radius={[8, 8, 0, 0]} barSize={28} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </Card>
          </div>

          <div className="grid gap-6 xl:grid-cols-3">
            <Card className="xl:col-span-2">
              <CardHeader title="Avance del censo" subtitle="Registros capturados por mes" icon={TrendingUp} />
              <div className="h-64 px-3 pb-4">
                <ResponsiveContainer>
                  <AreaChart data={st.por_mes.map((m) => ({ ...m, label: fmtMes(m.mes) }))} margin={{ top: 8, right: 16 }}>
                    <defs>
                      <linearGradient id="ga" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stopColor="#10b981" stopOpacity={0.35} /><stop offset="100%" stopColor="#10b981" stopOpacity={0} />
                      </linearGradient>
                    </defs>
                    <CartesianGrid vertical={false} stroke="#f5f5f4" />
                    <XAxis dataKey="label" tick={{ fontSize: 11, fill: '#a8a29e' }} axisLine={false} tickLine={false} />
                    <YAxis allowDecimals={false} tick={{ fontSize: 11, fill: '#a8a29e' }} axisLine={false} tickLine={false} width={30} />
                    <Tooltip contentStyle={tooltipStyle} formatter={(v) => [v, 'Registros']} />
                    <Area type="monotone" dataKey="total" stroke="#047857" strokeWidth={2.5} fill="url(#ga)" dot={{ r: 3, fill: '#047857', strokeWidth: 0 }} />
                  </AreaChart>
                </ResponsiveContainer>
              </div>
            </Card>

            <Card>
              <CardHeader title="Encuestadores" subtitle="Registros por persona" icon={Users} />
              <div className="space-y-3 px-5 pb-5">
                {st.por_encuestador.length === 0 && <p className="text-sm text-stone-500">Sin datos</p>}
                {st.por_encuestador.slice(0, 6).map((e) => {
                  const max = Math.max(...st.por_encuestador.map((x) => x.total), 1)
                  return (
                    <div key={e.usuario}>
                      <div className="mb-1 flex justify-between text-sm"><span className="text-stone-700">{e.usuario}</span><span className="font-semibold tabular-nums">{e.total}</span></div>
                      <div className="h-2 overflow-hidden rounded-full bg-stone-100">
                        <div className="h-full rounded-full bg-gradient-to-r from-brand-400 to-brand-700" style={{ width: `${(e.total / max) * 100}%` }} />
                      </div>
                    </div>
                  )
                })}
              </div>
            </Card>
          </div>

          <Card>
            <CardHeader title="Últimos registros" subtitle="Capturas más recientes desde campo" icon={Clock}
              action={<Link to="/consejos" className="inline-flex items-center gap-1 text-xs font-medium text-brand-700 hover:text-brand-800">Ver todos <ArrowRight className="size-3.5" /></Link>} />
            <div className="divide-y divide-stone-100">
              {recientes?.results.map((c) => (
                <Link key={c.id} to={`/consejos/${c.id}`} className="flex items-center gap-4 px-5 py-3 transition-colors hover:bg-stone-50">
                  <div className="grid size-10 shrink-0 place-items-center rounded-xl bg-brand-50 text-brand-700"><Sprout className="size-5" /></div>
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-sm font-medium text-stone-900">{c.nombre}</p>
                    <p className="truncate text-xs text-stone-500">{c.parroquia.nombre} · {c.sector || 'Sin sector'} · {c.num_familias} familias</p>
                  </div>
                  <p className="hidden text-xs text-stone-500 sm:block">{fmtFecha(c.fecha_captura ?? c.creado)}</p>
                  <EstadoBadge estado={c.estado} />
                </Link>
              ))}
            </div>
          </Card>
        </div>
      )}
    </div>
  )
}
