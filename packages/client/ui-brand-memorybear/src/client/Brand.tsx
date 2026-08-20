import type { HeroBrandMarkOwnerProps } from '@deepseek-ai/dsh-client-ui-conversation/client'
import type { SidebarBrandMarkOwnerProps } from '@deepseek-ai/dsh-client-ui-sidebar/client'
import css from './Brand.module.css'

type MemoryBearBrandMarkProps = HeroBrandMarkOwnerProps & SidebarBrandMarkOwnerProps

/** Head silhouette, traced from the MemoryBear product icon on a 48×48 grid. */
const HEAD = 'M24 5.95C38.74 5.95 42.56 25.73 42.56 30.35C42.56 38.62 24.55 43.99 24 43.99'
  + 'C23.45 43.99 5.44 38.62 5.44 30.35C5.44 25.73 9.26 5.95 24 5.95Z'

/**
 * Render the MemoryBear mark at the size its host surface requests.
 *
 * The geometry is the same trace that produces `deploy/memorybear/public/favicon.svg`,
 * so the tab icon and the in-app mark cannot drift apart. Colours are fixed
 * rather than themed: this is the product mark, and the red spectacles are the
 * feature that makes it recognisable at rail size.
 * @param props - Host-supplied mark presentation.
 * @returns the MemoryBear bear mark.
 */
export function MemoryBearBrandMark({ size, className }: MemoryBearBrandMarkProps) {
  return (
    <svg
      viewBox="0 0 48 48"
      width={size}
      height={size}
      className={className}
      aria-hidden="true"
      focusable="false"
    >
      {/* Ears sit behind the head, so the head silhouette clips their inner edge. */}
      <circle cx="11" cy="11" r="5" fill="#DD3838" />
      <circle cx="37" cy="11" r="5" fill="#DD3838" />
      <path d={HEAD} fill="#212332" />
      {/* The muzzle's upper flanks fall under the wide lower arcs of the rims. */}
      <ellipse cx="24" cy="28" rx="8" ry="9" fill="#FFFFFF" />
      {/* Unfilled rims, so the head colour reads as the eyes. */}
      <g fill="none" stroke="#DD3838" strokeWidth="2">
        <circle cx="16" cy="21" r="4" />
        <circle cx="32" cy="21" r="4" />
        <path d="M20.8 19.6Q24 16.9 27.2 19.6" />
      </g>
      <circle cx="24" cy="28" r="3" fill="#DD3838" />
      <path d="M20 34.1Q24 31.7 28 34.1" fill="none" stroke="#212332" strokeWidth="1.2" strokeLinecap="round" />
    </svg>
  )
}

/**
 * Render the MemoryBear name artwork without its independently slotted mark.
 * @returns the MemoryBear name wordmark.
 */
export function MemoryBearBrandName() {
  return (
    <span className={css.wordmark}>
      Memory<span className={css.accent}>Bear</span>
    </span>
  )
}
