/**
 * 应用动效令牌。统一时长和幅度，避免页面间出现节奏割裂。
 */
export class Motion {
  static readonly INTRO_MAX: number = 1400;
  static readonly INTRO_MORPH_DELAY: number = 16;
  static readonly INTRO_MORPH_DURATION: number = 360;
  static readonly INTRO_TITLE_DELAY: number = 110;
  static readonly INTRO_TITLE_DURATION: number = 240;
  static readonly INTRO_EXIT_AT: number = 920;
  static readonly INTRO_EXIT_DURATION: number = 220;
  static readonly INTRO_TOTAL: number = Motion.INTRO_EXIT_AT + Motion.INTRO_EXIT_DURATION;

  static readonly TAB_DURATION: number = 280;
  static readonly COACH_DURATION: number = 280;
  static readonly MANUAL_STEP_DURATION: number = 220;
  static readonly SETTINGS_SEGMENT_DURATION: number = 220;
  static readonly CARD_ENTRANCE_DELAY: number = 180;
  static readonly CARD_ENTRANCE_DURATION: number = 320;
  static readonly CARD_PRESS_SCALE: number = 0.985;
  static readonly COPY_HIGHLIGHT_IN: number = 100;
  static readonly COPY_HIGHLIGHT_HOLD: number = 130;
  static readonly COPY_HIGHLIGHT_OUT: number = 260;
}
