import assert from 'node:assert/strict';
import test from 'node:test';

function account(id, updatedAt, groupId = '') {
  return { id, updatedAt, groupId, serviceName: id };
}

function group(id, name, updatedAt) {
  return { id, name, updatedAt };
}

function merge(local, cloud) {
  const groups = mergeById(local.groups, cloud.groups);
  const groupIds = groups.map((item) => item.id);
  const accounts = mergeById(local.accounts, cloud.accounts).map((item) => {
    if (item.groupId && !groupIds.includes(item.groupId)) {
      return { ...item, groupId: '' };
    }
    return item;
  });
  return { accounts, groups };
}

function mergeById(localItems, cloudItems) {
  const result = [];
  const seen = [];
  for (const localItem of localItems) {
    const cloudItem = cloudItems.find((item) => item.id === localItem.id);
    if (!cloudItem || localItem.updatedAt >= cloudItem.updatedAt) {
      result.push(localItem);
    } else {
      result.push(cloudItem);
    }
    seen.push(localItem.id);
  }
  for (const cloudItem of cloudItems) {
    if (!seen.includes(cloudItem.id)) {
      result.push(cloudItem);
    }
  }
  return result;
}

test('merge adds cloud-only records and keeps local-only records', () => {
  const merged = merge(
    { accounts: [account('local-1', 10)], groups: [group('g-local', '本机', 10)] },
    { accounts: [account('cloud-1', 20)], groups: [group('g-cloud', '云端', 20)] }
  );
  assert.equal(merged.accounts.length, 2);
  assert.equal(merged.groups.length, 2);
});

test('merge prefers newer updatedAt and keeps local when equal', () => {
  const newer = merge(
    { accounts: [account('a-1', 10)], groups: [group('g-1', '旧名', 10)] },
    { accounts: [account('a-1', 30)], groups: [group('g-1', '新名', 30)] }
  );
  assert.equal(newer.accounts[0].updatedAt, 30);
  assert.equal(newer.groups[0].name, '新名');

  const tied = merge(
    { accounts: [{ ...account('a-1', 20), serviceName: '本机' }], groups: [group('g-1', '本机', 20)] },
    { accounts: [{ ...account('a-1', 20), serviceName: '云端' }], groups: [group('g-1', '云端', 20)] }
  );
  assert.equal(tied.accounts[0].serviceName, '本机');
  assert.equal(tied.groups[0].name, '本机');
});

test('merge clears orphan groupId', () => {
  const merged = merge(
    { accounts: [account('a-1', 10, 'missing')], groups: [] },
    { accounts: [], groups: [] }
  );
  assert.equal(merged.accounts[0].groupId, '');
});
