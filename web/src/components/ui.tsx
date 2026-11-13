import clsx from 'clsx'
import { Loader2, type LucideIcon } from 'lucide-react'
import type { ButtonHTMLAttributes, InputHTMLAttributes, ReactNode, SelectHTMLAttributes } from 'react'
import { ESTADO_META } from '../lib/format'
import type { Estado } from '../lib/types'

export function Card({ className, children }: { className?: string; children: ReactNode }) {
  return <div className={clsx('rounded-2xl bg-white shadow-sm ring-1 ring-stone-200/70', className)}>{children}</div>
}

export function CardHeader({ title, subtitle, action, icon: Icon }: { title: string; subtitle?: string; action?: ReactNode; icon?: LucideIcon }) {
  return (
    <div className="flex items-start justify-between gap-4 px-5 pt-5 pb-3">
      <div className="flex items-center gap-3">
        {Icon && <div className="grid size-9 place-items-center rounded-xl bg-brand-50 text-brand-700"><Icon className="size-4.5" /></div>}
        <div>
          <h3 className="text-[15px] font-semibold text-stone-900">{title}</h3>
          {subtitle && <p className="text-xs text-stone-500">{subtitle}</p>}
        </div>
      </div>
      {action}
    </div>
  )
}

type Variant = 'primary' | 'secondary' | 'ghost' | 'danger' | 'success'
const VARIANTS: Record<Variant, string> = {
  primary: 'bg-brand-700 text-white hover:bg-brand-800 shadow-sm shadow-brand-900/10',
  secondary: 'bg-white text-stone-700 ring-1 ring-stone-200 hover:bg-stone-50 shadow-sm',
  ghost: 'text-stone-600 hover:bg-stone-100',
  danger: 'bg-rose-600 text-white hover:bg-rose-700 shadow-sm',
  success: 'bg-emerald-600 text-white hover:bg-emerald-700 shadow-sm',
}

export function Button({ variant = 'primary', loading, icon: Icon, className, children, disabled, ...props }:
  ButtonHTMLAttributes<HTMLButtonElement> & { variant?: Variant; loading?: boolean; icon?: LucideIcon }) {
  return (
    <button
      {...props}
      disabled={disabled || loading}
      className={clsx(
        'inline-flex items-center justify-center gap-2 rounded-xl px-3.5 py-2 text-sm font-medium transition-colors',
        'focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand-600 disabled:cursor-not-allowed disabled:opacity-60',
        VARIANTS[variant], className,
      )}
    >
      {loading ? <Loader2 className="size-4 animate-spin" /> : Icon && <Icon className="size-4" />}
      {children}
    </button>
  )
}

const field = 'w-full rounded-xl border-0 bg-white px-3 py-2 text-sm text-stone-800 shadow-sm ring-1 ring-stone-200 placeholder:text-stone-400 focus:ring-2 focus:ring-brand-600 focus:outline-none'

export function Input({ className, ...props }: InputHTMLAttributes<HTMLInputElement>) {
  return <input {...props} className={clsx(field, className)} />
}

export function Select({ className, children, ...props }: SelectHTMLAttributes<HTMLSelectElement>) {
  return <select {...props} className={clsx(field, 'pr-8', className)}>{children}</select>
}

export function Label({ children, htmlFor }: { children: ReactNode; htmlFor?: string }) {
  return <label htmlFor={htmlFor} className="mb-1.5 block text-xs font-medium text-stone-600">{children}</label>
}

export function EstadoBadge({ estado, className }: { estado: Estado; className?: string }) {
  const m = ESTADO_META[estado] ?? ESTADO_META.enviado
  return (
    <span className={clsx('inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-medium ring-1 ring-inset', m.badge, className)}>
      <span className={clsx('size-1.5 rounded-full', m.dot)} />
      {m.label}
    </span>
  )
}

export function Chip({ children, className }: { children: ReactNode; className?: string }) {
  return <span className={clsx('inline-flex items-center whitespace-nowrap rounded-lg bg-stone-100 px-2 py-0.5 text-xs font-medium text-stone-700', className)}>{children}</span>
}

export function Spinner({ className }: { className?: string }) {
  return <Loader2 className={clsx('size-5 animate-spin text-brand-600', className)} />
}

export function Empty({ icon: Icon, title, text }: { icon: LucideIcon; title: string; text?: string }) {
  return (
    <div className="flex flex-col items-center justify-center gap-2 py-14 text-center">
      <div className="grid size-12 place-items-center rounded-2xl bg-stone-100 text-stone-400"><Icon className="size-6" /></div>
      <p className="text-sm font-medium text-stone-700">{title}</p>
      {text && <p className="max-w-xs text-xs text-stone-500">{text}</p>}
    </div>
  )
}

export function Avatar({ name, className }: { name: string; className?: string }) {
  const init = name.split(/\s+/).filter(Boolean).slice(0, 2).map((p) => p[0]?.toUpperCase()).join('') || '?'
  return (
    <div className={clsx('grid size-8 shrink-0 place-items-center rounded-full bg-gradient-to-br from-brand-500 to-brand-700 text-xs font-semibold text-white', className)}>
      {init}
    </div>
  )
}

export function Modal({ open, onClose, title, children, footer }: { open: boolean; onClose: () => void; title: string; children: ReactNode; footer?: ReactNode }) {
  if (!open) return null
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-stone-900/40 backdrop-blur-sm" onClick={onClose} />
      <div className="relative w-full max-w-lg rounded-2xl bg-white shadow-2xl ring-1 ring-stone-200">
        <div className="border-b border-stone-100 px-6 py-4"><h2 className="text-base font-semibold text-stone-900">{title}</h2></div>
        <div className="max-h-[70vh] overflow-y-auto px-6 py-5">{children}</div>
        {footer && <div className="flex justify-end gap-2 rounded-b-2xl border-t border-stone-100 bg-stone-50/60 px-6 py-3">{footer}</div>}
      </div>
    </div>
  )
}
