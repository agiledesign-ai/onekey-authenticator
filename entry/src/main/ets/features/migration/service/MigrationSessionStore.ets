import { GoogleMigrationPage, GoogleMigrationParameter } from '../codec/GoogleMigrationCodec';

export class MigrationSessionStatus {
  static readonly COMPLETE: string = 'complete';
  static readonly PROGRESS: string = 'progress';
  static readonly MIXED_BATCH: string = 'mixed_batch';
  static readonly TOO_LARGE: string = 'too_large';
  static readonly EXPIRED: string = 'expired';
  static readonly INVALID: string = 'invalid';
}

export interface MigrationSessionResult {
  status: string;
  scanned: number;
  total: number;
}

interface MigrationSession {
  batchId: number;
  batchSize: number;
  startedAt: number;
  pages: GoogleMigrationParameter[][];
}

const MAX_ACCOUNTS: number = 200;
const SESSION_TTL_MS: number = 120_000;

/** 仅存在于进程内存的 Google 多页迁移会话。 */
export class MigrationSessionStore {
  private static session: MigrationSession | null = null;
  private static scanInProgress: boolean = false;

  static clear(): void {
    MigrationSessionStore.session = null;
    MigrationSessionStore.scanInProgress = false;
  }

  static markScanInProgress(): void {
    MigrationSessionStore.scanInProgress = true;
  }

  static markScanFinished(): void {
    MigrationSessionStore.scanInProgress = false;
  }

  static clearIfBackgrounded(): void {
    if (!MigrationSessionStore.scanInProgress) {
      MigrationSessionStore.clear();
    }
  }

  static scannedCount(): number {
    const session: MigrationSession | null = MigrationSessionStore.session;
    if (session === null) {
      return 0;
    }
    return MigrationSessionStore.filledPageCount(session);
  }

  static collectParameters(): GoogleMigrationParameter[] {
    const session: MigrationSession | null = MigrationSessionStore.session;
    const collected: GoogleMigrationParameter[] = [];
    if (session === null) {
      return collected;
    }
    for (let i: number = 0; i < session.pages.length; i++) {
      const page: GoogleMigrationParameter[] = session.pages[i];
      for (let j: number = 0; j < page.length; j++) {
        collected.push(page[j]);
      }
    }
    return collected;
  }

  static addPage(page: GoogleMigrationPage, now: number): MigrationSessionResult {
    if (page.batchSize <= 0 || page.batchIndex < 0 || page.batchIndex >= page.batchSize) {
      return { status: MigrationSessionStatus.INVALID, scanned: 0, total: 0 };
    }
    const accountCount: number = page.parameters.length;
    if (accountCount > MAX_ACCOUNTS) {
      MigrationSessionStore.clear();
      return { status: MigrationSessionStatus.TOO_LARGE, scanned: 0, total: page.batchSize };
    }

    let session: MigrationSession | null = MigrationSessionStore.session;
    if (session !== null && now - session.startedAt > SESSION_TTL_MS) {
      MigrationSessionStore.clear();
      return { status: MigrationSessionStatus.EXPIRED, scanned: 0, total: page.batchSize };
    }

    if (session !== null && session.batchId !== page.batchId) {
      return {
        status: MigrationSessionStatus.MIXED_BATCH,
        scanned: MigrationSessionStore.filledPageCount(session),
        total: session.batchSize
      };
    }

    if (session === null) {
      const pages: GoogleMigrationParameter[][] = [];
      for (let i: number = 0; i < page.batchSize; i++) {
        pages.push([]);
      }
      session = {
        batchId: page.batchId,
        batchSize: page.batchSize,
        startedAt: now,
        pages: pages
      };
      MigrationSessionStore.session = session;
    }

    if (page.batchSize !== session.batchSize || page.batchIndex >= session.pages.length) {
      return { status: MigrationSessionStatus.INVALID, scanned: MigrationSessionStore.filledPageCount(session),
        total: session.batchSize };
    }

    const already: boolean = session.pages[page.batchIndex].length > 0;
    if (!already) {
      let totalAccounts: number = accountCount;
      for (let i: number = 0; i < session.pages.length; i++) {
        totalAccounts += session.pages[i].length;
      }
      if (totalAccounts > MAX_ACCOUNTS) {
        MigrationSessionStore.clear();
        return { status: MigrationSessionStatus.TOO_LARGE, scanned: 0, total: page.batchSize };
      }
      const copy: GoogleMigrationParameter[] = [];
      for (let i: number = 0; i < page.parameters.length; i++) {
        copy.push(page.parameters[i]);
      }
      session.pages[page.batchIndex] = copy;
    }

    const scanned: number = MigrationSessionStore.filledPageCount(session);
    if (scanned === session.batchSize) {
      return { status: MigrationSessionStatus.COMPLETE, scanned: scanned, total: session.batchSize };
    }
    return { status: MigrationSessionStatus.PROGRESS, scanned: scanned, total: session.batchSize };
  }

  private static filledPageCount(session: MigrationSession): number {
    let count: number = 0;
    for (let i: number = 0; i < session.pages.length; i++) {
      if (session.pages[i].length > 0) {
        count++;
      }
    }
    return count;
  }
}
