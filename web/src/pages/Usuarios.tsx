import { useState, type FormEvent } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import { Pencil, Plus, ShieldCheck, UserCog, Users } from 'lucide-react'
import clsx from 'clsx'
import { PageHeader } from '../components/Layout'
import { Avatar, Button, Card, Empty, Input, Label, Modal, Select, Spinner } from '../components/ui'
import { api } from '../lib/api'
import { ROL_LABEL } from '../lib/format'
import type { Paginated, Rol, Usuario } from '../lib/types'

type Form = { username: string; first_name: string; last_name: string; email: string; rol: Rol; is_active: boolean; password: string }
const vacio: Form = { username: '', first_name: '', last_name: '', email: '', rol: 'encuestador', is_active: true, password: '' }

const ROL_STYLE: Record<string, string> = {
  administrador: 'bg-violet-50 text-violet-700 ring-violet-600/20',
  supervisor: 'bg-sky-50 text-sky-700 ring-sky-600/20',
  encuestador: 'bg-brand-50 text-brand-700 ring-brand-600/20',
}

export default function Usuarios() {
  const qc = useQueryClient()
  const { data, isLoading } = useQuery({
    queryKey: ['usuarios'],
    queryFn: async () => {
      const r = await api<Paginated<Usuario> | Usuario[]>('/api/usuarios/?page_size=200')
      return Array.isArray(r) ? r : r.results
    },
  })
  const [editando, setEditando] = useState<Usuario | null>(null)
  const [open, setOpen] = useState(false)
  const [form, setForm] = useState<Form>(vacio)

  const abrir = (u?: Usuario) => {
    setEditando(u ?? null)
    setForm(u ? { username: u.username, first_name: u.first_name, last_name: u.last_name, email: u.email, rol: (u.rol ?? 'encuestador'), is_active: u.is_active ?? true, password: '' } : vacio)
    setOpen(true)
  }

  const guardar = useMutation({
    mutationFn: (f: Form) => {
      const body: Partial<Form> = { ...f }
      if (!body.password) delete body.password
      return editando
        ? api<Usuario>(`/api/usuarios/${editando.id}/`, { method: 'PATCH', body: JSON.stringify(body) })
        : api<Usuario>('/api/usuarios/', { method: 'POST', body: JSON.stringify(body) })
    },
    onSuccess: () => {
      toast.success(editando ? 'Usuario actualizado' : 'Usuario creado')
      qc.invalidateQueries({ queryKey: ['usuarios'] })
      setOpen(false)
    },
    onError: (e: Error) => toast.error(e.message),
  })

  const submit = (e: FormEvent) => { e.preventDefault(); guardar.mutate(form) }
  const conteo = (r: Rol) => data?.filter((u) => u.rol === r).length ?? 0

  return (
    <div className="mx-auto max-w-[1200px] p-4 sm:p-8">
      <PageHeader title="Usuarios" subtitle="Gestiona el acceso del personal de campo y supervisión"
        actions={<Button icon={Plus} onClick={() => abrir()}>Nuevo usuario</Button>} />

      <div className="mb-6 grid gap-4 sm:grid-cols-3">
        {(['administrador', 'supervisor', 'encuestador'] as Rol[]).map((r) => (
          <Card key={r} className="flex items-center gap-4 p-4">
            <div className={clsx('grid size-11 place-items-center rounded-xl ring-1 ring-inset', ROL_STYLE[r])}>
              {r === 'administrador' ? <ShieldCheck className="size-5" /> : r === 'supervisor' ? <UserCog className="size-5" /> : <Users className="size-5" />}
            </div>
            <div>
              <p className="text-2xl font-semibold text-stone-900">{conteo(r)}</p>
              <p className="text-xs text-stone-500">{ROL_LABEL[r]}{conteo(r) === 1 ? '' : 'es'}</p>
            </div>
          </Card>
        ))}
      </div>

      <Card className="overflow-hidden">
        {isLoading ? <div className="grid h-48 place-items-center"><Spinner /></div> : !data?.length ? <Empty icon={Users} title="Sin usuarios" /> : (
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-stone-100 bg-stone-50/70 text-left text-xs font-medium tracking-wide text-stone-500 uppercase">
                <th className="px-5 py-3">Usuario</th><th className="px-4 py-3">Correo</th><th className="px-4 py-3">Rol</th><th className="px-4 py-3">Estado</th><th className="px-5 py-3" />
              </tr>
            </thead>
            <tbody className="divide-y divide-stone-100">
              {data.map((u) => {
                const nombre = [u.first_name, u.last_name].filter(Boolean).join(' ') || u.username
                return (
                  <tr key={u.id} className="hover:bg-stone-50/60">
                    <td className="px-5 py-3">
                      <div className="flex items-center gap-3"><Avatar name={nombre} className="size-9" />
                        <div><p className="font-medium text-stone-900">{nombre}</p><p className="text-xs text-stone-500">@{u.username}</p></div>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-stone-600">{u.email || '—'}</td>
                    <td className="px-4 py-3">
                      <span className={clsx('rounded-full px-2.5 py-0.5 text-xs font-medium ring-1 ring-inset', ROL_STYLE[u.rol ?? ''] ?? 'bg-stone-100 text-stone-600 ring-stone-300')}>{ROL_LABEL[u.rol ?? ''] ?? 'Sin rol'}</span>
                    </td>
                    <td className="px-4 py-3">
                      <span className={clsx('inline-flex items-center gap-1.5 text-xs font-medium', u.is_active ? 'text-emerald-700' : 'text-stone-400')}>
                        <span className={clsx('size-1.5 rounded-full', u.is_active ? 'bg-emerald-500' : 'bg-stone-300')} />{u.is_active ? 'Activo' : 'Inactivo'}
                      </span>
                    </td>
                    <td className="px-5 py-3 text-right"><Button variant="ghost" icon={Pencil} onClick={() => abrir(u)}>Editar</Button></td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        )}
      </Card>

      <Modal open={open} onClose={() => setOpen(false)} title={editando ? 'Editar usuario' : 'Nuevo usuario'}
        footer={<><Button variant="secondary" onClick={() => setOpen(false)}>Cancelar</Button><Button form="fu" type="submit" loading={guardar.isPending}>Guardar</Button></>}>
        <form id="fu" onSubmit={submit} className="grid gap-4 sm:grid-cols-2">
          <div><Label>Nombre</Label><Input value={form.first_name} onChange={(e) => setForm({ ...form, first_name: e.target.value })} required /></div>
          <div><Label>Apellido</Label><Input value={form.last_name} onChange={(e) => setForm({ ...form, last_name: e.target.value })} /></div>
          <div><Label>Usuario</Label><Input value={form.username} onChange={(e) => setForm({ ...form, username: e.target.value })} required disabled={!!editando} /></div>
          <div><Label>Correo</Label><Input type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} /></div>
          <div><Label>Rol</Label>
            <Select value={form.rol} onChange={(e) => setForm({ ...form, rol: e.target.value as Rol })}>
              <option value="encuestador">Encuestador</option><option value="supervisor">Supervisor</option><option value="administrador">Administrador</option>
            </Select>
          </div>
          <div><Label>{editando ? 'Nueva contraseña (opcional)' : 'Contraseña'}</Label>
            <Input type="password" value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })} required={!editando} minLength={8} />
          </div>
          <label className="flex items-center gap-2 text-sm text-stone-700 sm:col-span-2">
            <input type="checkbox" className="size-4 rounded accent-brand-700" checked={form.is_active} onChange={(e) => setForm({ ...form, is_active: e.target.checked })} />
            Usuario activo
          </label>
        </form>
      </Modal>
    </div>
  )
}
