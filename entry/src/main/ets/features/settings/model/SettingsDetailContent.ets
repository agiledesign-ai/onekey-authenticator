import { AppConfig } from '../../../common/config/AppConfig';

/** 列表图标语义，由视图统一映射到系统符号。 */
export enum SettingsDetailIcon {
  ACCOUNT,
  KEY,
  FILE,
  SHIELD,
  QR,
  BACKUP,
  CAMERA,
  CLIPBOARD,
  NETWORK,
  TRASH,
  EXTERNAL,
  RECOVERY
}

/** 二级页说明条目。 */
export interface SettingsDetailItem {
  title: string;
  description: string;
  icon: SettingsDetailIcon;
  badge?: string;
  value?: string;
  dangerous?: boolean;
}

/** 二级页内容分区。 */
export interface SettingsDetailSection {
  title: string;
  items: SettingsDetailItem[];
}

/** 隐私政策段落。 */
export interface PrivacyParagraph {
  text: string;
  emphasized: boolean;
}

/** 隐私政策章节。 */
export interface PrivacyArticleSection {
  heading: string;
  paragraphs: PrivacyParagraph[];
}

/** 隐私政策全文。 */
export interface PrivacyArticle {
  title: string;
  updatedAt: string;
  effectiveAt: string;
  notice: string;
  footer: string;
  sections: PrivacyArticleSection[];
}

/**
 * 设置二级页的说明内容。
 * 文案与页面组件分离，确保测试可以验证信息完整性。
 */
export class SettingsDetailContent {
  static versionSections(): SettingsDetailSection[] {
    return [
      {
        title: '版本详情',
        items: [
          {
            title: '当前版本', description: '当前安装的2FA验证器版本。',
            icon: SettingsDetailIcon.ACCOUNT, value: AppConfig.APP_VERSION_LABEL
          },
          {
            title: '运行方式', description: '验证码由设备本地生成。',
            icon: SettingsDetailIcon.NETWORK, badge: '本地'
          }
        ]
      }
    ];
  }

  static aboutName(): string {
    return AppConfig.APP_NAME;
  }

  static aboutTagline(): string {
    return '本地优先，云空间可选';
  }

  static aboutSections(): SettingsDetailSection[] {
    return [
      {
        title: '能力',
        items: [
          {
            title: '本地验证码',
            description: 'TOTP、HOTP 与 Steam 均在本机生成',
            icon: SettingsDetailIcon.SHIELD,
            badge: '离线'
          },
          {
            title: '扫码添加',
            description: '支持 otpauth 与 Google 迁移二维码',
            icon: SettingsDetailIcon.QR,
            badge: '相机'
          },
          {
            title: '本地备份',
            description: '导出明文 JSON，导入导出都在本机完成',
            icon: SettingsDetailIcon.BACKUP,
            badge: '本机'
          },
          {
            title: '令牌卡片',
            description: '桌面显示常用验证码，密钥仍留在本机',
            icon: SettingsDetailIcon.SHIELD,
            badge: '桌面'
          },
          {
            title: '华为云空间',
            description: '登录后可选择自动同步或手动推送、获取',
            icon: SettingsDetailIcon.NETWORK,
            badge: '可选'
          }
        ]
      },
      {
        title: '原则',
        items: [
          {
            title: '默认不出设备',
            description: '密钥保存在系统安全存储；只有你开启云空间时才会离开本机',
            icon: SettingsDetailIcon.KEY,
            badge: '本地'
          },
          {
            title: '没有2FA验证器账号',
            description: '不注册应用账号。华为账号只用于你主动开启的云空间同步',
            icon: SettingsDetailIcon.NETWORK,
            badge: '可选'
          },
          {
            title: '权限按需申请',
            description: '扫码、备份或开启云同步时才申请对应权限',
            icon: SettingsDetailIcon.CAMERA,
            badge: '按需'
          }
        ]
      }
    ];
  }

  static privacyArticle(): PrivacyArticle {
    return {
      title: '2FA验证器隐私政策',
      updatedAt: '更新日期：2026年8月15日',
      effectiveAt: '生效日期：2026年8月14日',
      notice: '请在使用2FA验证器前阅读本政策。验证码在设备本地计算。默认不把密钥同步到云端；只有你登录华为账号并开启云空间后，账号和分组才会写入你的华为云空间。使用本应用即表示你理解并同意下列说明。',
      footer: '2FA验证器',
      sections: [
        {
          heading: '1. 数据留在本机',
          paragraphs: [
            {
              text: '账号名称、服务名和验证密钥默认只保存在系统 Asset Store，不会自动同步到其他设备。只有你开启华为云空间时，才会拷贝所选账号。',
              emphasized: false
            },
            {
              text: '验证码始终在本机根据密钥计算。应用界面、日志和备份文件以外的位置都不会保存明文密钥或当前验证码。',
              emphasized: false
            },
            {
              text: '桌面服务卡片会显示你选择的账号名称和当前验证码。验证码在本机计算，密钥仍只保存在系统安全存储，不会写入卡片配置。',
              emphasized: false
            }
          ]
        },
        {
          heading: '2. 权限使用',
          paragraphs: [
            {
              text: '相机只在你主动扫码添加账号时使用。剪贴板只在你主动复制验证码时写入，并在验证码失效或 30 秒后清除。跨设备数据同步权限只在你开启华为云空间时申请。',
              emphasized: false
            },
            {
              text: '开启人脸解锁后，启动或回到应用时会调用系统人脸认证。认证在系统侧完成，2FA验证器不保存人脸图像。',
              emphasized: false
            }
          ]
        },
        {
          heading: '3. 备份与导出',
          paragraphs: [
            {
              text: '只有你主动导出时，才会生成本地 JSON 备份文件。你可以勾选部分账号。导入同样只在你选择文件后进行。',
              emphasized: false
            },
            {
              text: '请妥善保管设备和锁屏凭据。备份文件是明文 JSON，不要上传网盘或发给他人。设备遗失或越权访问导致的风险，需要由你自行承担。建议同时保留各服务发放的恢复码。',
              emphasized: true
            }
          ]
        },
        {
          heading: '4. 网络通信',
          paragraphs: [
            {
              text: '未开启云空间时，应用不发起业务网络请求，也不包含统计 SDK 或远程配置。本政策页面不加载网页。',
              emphasized: false
            }
          ]
        },
        {
          heading: '5. 华为账号与云空间',
          paragraphs: [
            {
              text: '华为云空间是可选功能。只有你主动登录华为账号并开启自动同步或手动推送后，账号和分组（含加密密钥）才会写入你的华为云空间，用于换机恢复。',
              emphasized: false
            },
            {
              text: '登录华为账号、云空间同步由系统服务提供，并受华为账号与云空间条款约束。网络、账号状态、云空间容量或系统维护可能影响同步结果。退出华为账号会关闭自动同步，但不会删除本机或云端已有数据。',
              emphasized: false
            }
          ]
        },
        {
          heading: '6. 政策更新',
          paragraphs: [
            {
              text: `本政策描述 ${AppConfig.APP_VERSION_LABEL} 的实际行为。功能变化时，我们会在应用内更新本页。若你不同意更新后的说明，应停止使用本应用。`,
              emphasized: false
            }
          ]
        }
      ]
    };
  }

  static clearSections(): SettingsDetailSection[] {
    return [
      {
        title: '操作影响',
        items: [
          {
            title: '将删除', description: '本机账号信息和验证密钥。',
            icon: SettingsDetailIcon.TRASH, dangerous: true
          },
          {
            title: '不会改变', description: '外部服务的双重验证仍然开启。',
            icon: SettingsDetailIcon.EXTERNAL
          },
          {
            title: '操作前', description: '先导出备份，并确认你持有恢复码。',
            icon: SettingsDetailIcon.RECOVERY
          },
          {
            title: '云空间', description: '若已开启云空间自动同步，这些账号也会从云空间删除。',
            icon: SettingsDetailIcon.NETWORK
          }
        ]
      }
    ];
  }
}
