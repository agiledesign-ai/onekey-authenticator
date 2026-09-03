import { window } from '@kit.ArkUI';
import { Log } from './LogUtil';

/**
 * 窗口与状态栏沉浸式工具。
 */
export class WindowUtil {
  private static mainWindow: window.Window | null = null;
  private static statusBarContentColor: string = '#000000';

  /** 开启全屏沉浸 + 深色状态栏图标。 */
  static async setupImmersive(windowStage: window.WindowStage): Promise<void> {
    try {
      WindowUtil.mainWindow = await windowStage.getMainWindow();
      await WindowUtil.mainWindow.setWindowLayoutFullScreen(true);
      await WindowUtil.applyStatusBarContentColor();
    } catch (err) {
      Log.e('WindowUtil.setupImmersive failed: ' + JSON.stringify(err));
    }
  }

  /** 获取主窗口引用（供 ToastUtil 等工具类访问 UIContext）。 */
  static getWindow(): window.Window | null {
    return WindowUtil.mainWindow;
  }

  /** 人脸锁启用时统一返回首页，由首页遮罩发起认证。 */
  static async returnToFaceLock(): Promise<void> {
    if (WindowUtil.mainWindow === null) {
      return;
    }
    try {
      const pageRouter = WindowUtil.mainWindow.getUIContext().getRouter();
      if (pageRouter.getState().path === 'pages/Index') {
        return;
      }
      await pageRouter.replaceUrl({ url: 'pages/Index' });
      pageRouter.clear();
    } catch (error) {
      Log.e('WindowUtil.returnToFaceLock failed: ' + JSON.stringify(error));
    }
  }

  /** 切换状态栏内容颜色，并记录尚未创建窗口时的期望值。 */
  static async setStatusBarContentColor(color: string): Promise<void> {
    WindowUtil.statusBarContentColor = color;
    if (WindowUtil.mainWindow === null) {
      return;
    }
    try {
      await WindowUtil.applyStatusBarContentColor();
    } catch (err) {
      Log.e('WindowUtil.setStatusBarContentColor failed: ' + JSON.stringify(err));
    }
  }

  private static async applyStatusBarContentColor(): Promise<void> {
    try {
      if (WindowUtil.mainWindow !== null) {
        await WindowUtil.mainWindow.setWindowSystemBarProperties({
          statusBarColor: '#00000000',
          navigationBarColor: '#00000000',
          statusBarContentColor: WindowUtil.statusBarContentColor
        });
      }
    } catch (err) {
      Log.e('WindowUtil.applyStatusBarContentColor failed: ' + JSON.stringify(err));
    }
  }

  /** 获取系统状态栏避让高度（px，调用方用 getUIContext().px2vp 转换）。 */
  static async getStatusBarHeightPx(context: Context): Promise<number> {
    try {
      const mainWindow: window.Window = await window.getLastWindow(context);
      const avoidArea = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      return avoidArea.topRect.height;
    } catch (err) {
      Log.e('WindowUtil.getStatusBarHeightPx failed: ' + JSON.stringify(err));
      return 0;
    }
  }

  /** 获取三键导航栏或手势指示条的最大底部高度（px）。 */
  static async getBottomAvoidHeightPx(context: Context): Promise<number> {
    try {
      const mainWindow: window.Window = await window.getLastWindow(context);
      const systemArea = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      const indicatorArea = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      return Math.max(systemArea.bottomRect.height, indicatorArea.bottomRect.height);
    } catch (err) {
      Log.e('WindowUtil.getBottomAvoidHeightPx failed: ' + JSON.stringify(err));
      return 0;
    }
  }
}
