/** 验证码账号分组；排序值由管理页显式维护。 */
export interface GroupItem {
  id: string;
  name: string;
  sortIndex: number;
  createdAt: number;
  updatedAt: number;
}

export function normalizeGroupName(name: string): string {
  return name.trim();
}

/** 分组名去除首尾空白后按大小写不敏感方式判重。 */
export function isSameGroupName(first: string, second: string): boolean {
  const firstName: string = normalizeGroupName(first);
  const secondName: string = normalizeGroupName(second);
  return firstName.length > 0 && firstName.toLowerCase() === secondName.toLowerCase();
}

export function createGroupItem(
  id: string,
  name: string,
  sortIndex: number,
  timestamp: number = Date.now()
): GroupItem | null {
  const normalizedId: string = id.trim();
  const normalizedName: string = normalizeGroupName(name);
  if (normalizedId.length === 0 || normalizedName.length === 0 ||
    !Number.isInteger(sortIndex) || timestamp <= 0) {
    return null;
  }
  return {
    id: normalizedId,
    name: normalizedName,
    sortIndex: sortIndex,
    createdAt: timestamp,
    updatedAt: timestamp
  };
}
