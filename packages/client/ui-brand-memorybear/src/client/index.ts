/** MemoryBear occupants for the generic browser-brand slots. */
import type { ClientContext } from '@deepseek-ai/dsh-client-runtime/client'
import type {} from '@deepseek-ai/dsh-client-ui-conversation/client'
import type {} from '@deepseek-ai/dsh-client-ui-sidebar/client'
import { MemoryBearBrandMark, MemoryBearBrandName } from './Brand.tsx'

/** Required service: the UI slot registry. */
export const inject = ['slots']

/**
 * Fill every shipped brand slot as one declaration-aware registration set.
 *
 * Registration is unconditional: this row is mounted by the MemoryBear patch
 * overlay, so its presence in the tree IS the deployment's decision. The
 * upstream official occupants gate themselves on an artifact profile instead,
 * which is why both packages can never register at once.
 * @param ctx - Client root context.
 */
export function apply(ctx: ClientContext): void {
  ctx.slots.inject('sidebar.brand.mark', () =>
    ctx.slots.inject('sidebar.brand.name', () =>
      ctx.slots.inject('conversation.hero.brand.mark', function* () {
        yield ctx.slots.register({ name: 'sidebar.brand.mark' }, MemoryBearBrandMark)
        yield ctx.slots.register({ name: 'sidebar.brand.name' }, MemoryBearBrandName)
        yield ctx.slots.register({ name: 'conversation.hero.brand.mark' }, MemoryBearBrandMark)
      })))
}
