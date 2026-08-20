/** Durable settings namespace for product-wide GUI onboarding facts. */
export const WELCOME_NOTICE_SETTINGS_NAMESPACE = 'ui-onboarding'

/** Field storing the last welcome notice version the user acknowledged. */
export const WELCOME_NOTICE_ACK_FIELD = 'welcomeNoticeVersion'

/**
 * Bump only when the notice changes materially and every user should see it
 * again. The acknowledgement is compared for exact equality.
 *
 * Bumped from the upstream `2026-08-13.1` because this deployment replaced the
 * notice body wholesale: anyone who acknowledged the DeepSeek Harness text has
 * not seen this one.
 */
export const WELCOME_NOTICE_VERSION = '2026-08-20.memorybear.1'

/** The complete editable internal-testing notice in both supported GUI locales. */
export const WELCOME_NOTICE_COPY = {
  zh: {
    title: '内测声明',
    body: 'MemoryBear 目前处于内测阶段，还有许多地方需要持续改进和打磨，希望听取你的反馈建议。核心能力与接口都可能在接下来的一段时间内快速调整。\n\nMemoryBear 构建在开源的 DeepSeek Harness 之上，沿用其「一切皆插件」的架构。',
    continueLabel: '继续',
  },
  en: {
    title: 'Internal Testing Notice',
    body: 'MemoryBear is in internal testing. Many areas still need improvement and polish, and your feedback is welcome. Core capabilities and interfaces may change quickly over the coming months.\n\nMemoryBear is built on the open-source DeepSeek Harness and keeps its plugin-based architecture.',
    continueLabel: 'Continue',
  },
} as const
