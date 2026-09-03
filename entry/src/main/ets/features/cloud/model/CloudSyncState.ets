/** 一次云同步命令的进度与结果。 */
export interface CloudSyncState {
  status: string;
  finished: boolean;
  success: boolean;
  message?: string;
}

export interface CloudCommandResult {
  success: boolean;
  status: string;
}

export class CloudCommand {
  static busy(): CloudCommandResult {
    return { success: false, status: '正在同步，请稍候' };
  }

  static fail(status: string): CloudCommandResult {
    return { success: false, status: status };
  }

  static ok(status: string): CloudCommandResult {
    return { success: true, status: status };
  }
}
