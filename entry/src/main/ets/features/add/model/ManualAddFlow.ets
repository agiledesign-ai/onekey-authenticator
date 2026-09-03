import { AppConfig } from '../../../common/config/AppConfig';

/** 手动添加流程步骤。 */
export enum ManualAddStep {
  SERVICE = 0,
  SECRET = 1,
  CONFIRM = 2
}

/** 手动添加流程的纯逻辑边界，供页面和单元测试共同使用。 */
export class ManualAddFlow {
  static canContinue(step: ManualAddStep, service: string, secret: string): boolean {
    if (step === ManualAddStep.SERVICE) {
      return service.trim().length > 0;
    }
    if (step === ManualAddStep.SECRET) {
      return new RegExp(AppConfig.SECRET_PATTERN).test(secret.trim());
    }
    return true;
  }

  static next(step: ManualAddStep, service: string, secret: string): ManualAddStep {
    if (!ManualAddFlow.canContinue(step, service, secret)) {
      return step;
    }
    if (step === ManualAddStep.SERVICE) {
      return ManualAddStep.SECRET;
    }
    return ManualAddStep.CONFIRM;
  }

  static previous(step: ManualAddStep): ManualAddStep {
    if (step === ManualAddStep.CONFIRM) {
      return ManualAddStep.SECRET;
    }
    return ManualAddStep.SERVICE;
  }

  static maskSecret(secret: string): string {
    const normalized: string = secret.trim().toUpperCase();
    const edgeLength: number = normalized.length <= AppConfig.SECRET_MIN_LENGTH ? 2 : 4;
    const prefix: string = normalized.substring(0, edgeLength);
    const suffix: string = normalized.substring(normalized.length - edgeLength);
    return `${prefix} •••• ${suffix}`;
  }
}
