import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import test from 'node:test';

const read = (path) => readFileSync(new URL(`../${path}`, import.meta.url), 'utf8');

test('feedback page is registered and reachable from settings', () => {
  const pagePath = 'entry/src/main/ets/pages/FeedbackPage.ets';
  assert.equal(existsSync(new URL(`../${pagePath}`, import.meta.url)), true, 'FeedbackPage should exist');

  const routes = read('entry/src/main/ets/features/settings/model/SettingsDetailPolicy.ets');
  const settings = read('entry/src/main/ets/features/settings/components/SettingsTabContent.ets');
  const pages = read('entry/src/main/resources/base/profile/main_pages.json');

  assert.match(routes, /FEEDBACK: string = 'pages\/FeedbackPage'/);
  assert.match(settings, /title: '建议反馈'/);
  assert.match(settings, /openDetail\(SettingsRoutes\.FEEDBACK\)/);
  const guideIndex = settings.indexOf("title: '2FA 指南'");
  const feedbackIndex = settings.indexOf("title: '建议反馈'");
  const aboutIndex = settings.indexOf("title: '关于应用'");
  assert.ok(guideIndex < feedbackIndex && feedbackIndex < aboutIndex);
  assert.match(pages, /pages\/FeedbackPage/);
});

test('feedback page opens a prefilled system email and explains failure', () => {
  const pagePath = 'entry/src/main/ets/pages/FeedbackPage.ets';
  assert.equal(existsSync(new URL(`../${pagePath}`, import.meta.url)), true, 'FeedbackPage should exist');

  const page = read(pagePath);
  assert.match(page, /ohos\.want\.action\.sendToData/);
  assert.match(page, /FeedbackMailPolicy\.mailtoUri\(this\.feedbackContent\)/);
  assert.match(page, /FeedbackMailPolicy\.failureMessage\(\)/);
  assert.match(page, /发送邮件反馈/);
});
