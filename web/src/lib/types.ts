export type Rol = 'administrador' | 'supervisor' | 'encuestador'
export type Estado = 'enviado' | 'validado' | 'rechazado'

export interface Usuario {
  id: number
  username: string
  first_name: string
  last_name: string
  email: string
  rol: Rol | null
  is_active?: boolean
}

export interface Opcion { value: string; label: string }
export interface Parroquia { id: number; nombre: string; municipio: string; centroide: [number, number] | null }
export interface Rubro { id: number; nombre: string }

export interface Catalogos {
  parroquias: Parroquia[]
  rubros: Rubro[]
  tenencia_tierra: Opcion[]
  fuente_agua: Opcion[]
  estados: Opcion[]
  enfermedades: Opcion[]
  plagas: Opcion[]
  destino_produccion: Opcion[]
  tipos_cultivo: Opcion[]
  produccion_animal: Opcion[]
}

export const CAMPOS_MULTIPLES = ['enfermedades', 'plagas', 'destino_produccion', 'tipos_cultivo', 'produccion_animal'] as const
export type CampoMultiple = (typeof CAMPOS_MULTIPLES)[number]

export interface Vocero { id?: number; nombre: string; cedula: string; telefono: string; cargo: string; es_principal: boolean }
export interface Foto { id: number; uuid: string; url: string; descripcion: string }

export interface Consejo {
  id: number
  uuid: string
  nombre: string
  rif: string
  codigo_registro: string
  parroquia: { id: number; nombre: string }
  sector: string
  direccion: string
  lat: number
  lng: number
  precision_gps_m: number | null
  altitud_m: number | null
  fecha_constitucion: string | null
  num_familias: number
  num_hombres: number
  num_mujeres: number
  num_jovenes: number
  superficie_ha: string | number | null
  tenencia_tierra: string
  fuente_agua: string
  tiene_riego: boolean
  rubros: Rubro[]
  enfermedades: string[]
  plagas: string[]
  destino_produccion: string[]
  tipos_cultivo: string[]
  produccion_animal: string[]
  requerimientos: string
  necesidades: string
  observaciones: string
  estado: Estado
  registrado_por: { id: number; username: string; nombre: string } | null
  dispositivo_id: string
  fecha_captura: string | null
  creado: string
  actualizado: string
  voceros: Vocero[]
  fotos: Foto[]
}

export interface Paginated<T> { count: number; next: string | null; previous: string | null; results: T[] }

export interface Estadisticas {
  total: number
  validados: number
  pendientes: number
  rechazados: number
  familias: number
  miembros: number
  superficie_ha: number | string | null
  por_parroquia: { parroquia: string; total: number; familias: number }[]
  por_rubro: { rubro: string; total: number }[]
  por_mes: { mes: string; total: number }[]
  por_encuestador: { usuario: string; total: number }[]
  sanidad_produccion: Record<CampoMultiple, (Opcion & { total: number })[]>
}

export interface ConsejoFeature {
  type: 'Feature'
  geometry: { type: 'Point'; coordinates: [number, number] }
  properties: { id: number; nombre: string; parroquia: string; estado: Estado; num_familias: number; rubros: string[] | string }
}
export interface ConsejoFC { type: 'FeatureCollection'; features: ConsejoFeature[] }

export interface Filtros {
  search?: string
  parroquia?: string
  rubro?: string
  estado?: string
  fecha_desde?: string
  fecha_hasta?: string
}
