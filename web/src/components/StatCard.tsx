import clsx from 'clsx'
import type { LucideIcon } from 'lucide-react'
import type { ReactNode } from 'react'

const TONES = {
  brand: 'from-brand-500/15 to-brand-500/0 text-brand-700',
  amber: 'from-amber-500/15 to-amber-500/0 text-amber-700',
  sky: 'from-sky-500/15 to-sky-500/0 text-sky-700',
  violet: 'from-violet-500/15 to-violet-500/0 text-violet-700',
  rose: 'from-rose-500/15 to-rose-500/0 text-rose-700',
}

export function StatCard({ label, value, hint, icon: Icon, tone = 'brand' }:
  { label: string; value: ReactNode; hint?: ReactNode; icon: LucideIcon; tone?: keyof typeof TONES }) {
  return (
    <div className="relative overflow-hidden rounded-2xl bg-white p-5 shadow-sm ring-1 ring-stone-200/70">
      <div className={clsx('pointer-events-none absolute -top-10 -right-10 size-32 rounded-full bg-gradient-to-br', TONES[tone])} />
      <div className="relative flex items-start justify-between">
        <div>
          <p className="text-xs font-medium tracking-wide text-stone-500 uppercase">{label}</p>
          <p className="mt-2 text-3xl font-semibold tracking-tight text-stone-900 tabular-nums">{value}</p>
          {hint && <p className="mt-1 text-xs text-stone-500">{hint}</p>}
        </div>
        <div className={clsx('grid size-10 place-items-center rounded-xl bg-gradient-to-br', TONES[tone])}>
          <Icon className="size-5" />
        </div>
      </div>
    </div>
  )
}
