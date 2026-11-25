import assert from 'node:assert/strict';
import { test } from 'node:test';
import { classifyClient } from './classify.js';

const IPHONE = 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko)';
const ANDROID_WV = 'Mozilla/5.0 (Linux; Android 14; SM-A546B Build/UP1A.231005.007; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/137.0.7151.115 Mobile Safari/537.36';
const WINDOWS = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)';

const is = (ua: string | undefined, device: string, browser: string, inApp: string, what?: string) =>
  assert.deepEqual(classifyClient(ua), { device, browser, inApp }, what ?? ua);

test('phones and their browsers', () => {
  is(`${IPHONE} Version/18.6 Mobile/15E148 Safari/604.1`, 'iphone', 'safari', '');
  is(`${IPHONE} CriOS/138.0.7204.156 Mobile/15E148 Safari/604.1`, 'iphone', 'chrome', '');
  is(`${IPHONE} FxiOS/141.0 Mobile/15E148 Safari/605.1.15`, 'iphone', 'firefox', '');
  is(`${IPHONE} Version/18.0 EdgiOS/138.0.3351.83 Mobile/15E148 Safari/604.1`, 'iphone', 'edge', '');
  is('Mozilla/5.0 (Linux; Android 15; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Mobile Safari/537.36', 'android', 'chrome', '');
  is('Mozilla/5.0 (Linux; Android 14; SAMSUNG SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) SamsungBrowser/27.0 Chrome/125.0.0.0 Mobile Safari/537.36', 'android', 'samsung', '');
  is('Mozilla/5.0 (Android 15; Mobile; rv:141.0) Gecko/141.0 Firefox/141.0', 'android', 'firefox', '');
});

test('tablets and computers', () => {
  is('Mozilla/5.0 (iPad; CPU OS 17_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.7 Mobile/15E148 Safari/604.1', 'ipad', 'safari', '');
  is('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Safari/605.1.15', 'desktop', 'safari', '', 'a Mac, and an iPad in its default desktop mode');
  is(`${WINDOWS} Chrome/138.0.0.0 Safari/537.36`, 'desktop', 'chrome', '');
  is(`${WINDOWS} Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0`, 'desktop', 'edge', '');
  is(`${WINDOWS} Chrome/137.0.0.0 Safari/537.36 OPR/121.0.0.0`, 'desktop', 'opera', '');
  is('Mozilla/5.0 (X11; Linux x86_64; rv:141.0) Gecko/20100101 Firefox/141.0', 'desktop', 'firefox', '');
  is('Mozilla/5.0 (X11; CrOS x86_64 14541.0.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', 'desktop', 'chrome', '');
});

test('inside an app, the app is what counts: the browser is "other"', () => {
  is(`${IPHONE} Mobile/15E148 [Pinterest/iOS]`, 'iphone', 'other', 'pinterest');
  is(`${ANDROID_WV} [Pinterest/Android]`, 'android', 'other', 'pinterest');
  is(`${IPHONE} Mobile/15E148 Instagram 339.0.3.12.91 (iPhone15,2; iOS 18_6; en_US; en; scale=3.00; 1179x2556; 619461904)`, 'iphone', 'other', 'instagram');
  is(`${ANDROID_WV} Instagram 339.0.0.30.105 Android (34/14; 450dpi; 1080x2340; samsung; SM-A546B; a54x; s5e8835; fr_FR; 619461904)`, 'android', 'other', 'instagram');
  is(`${IPHONE} Mobile/15E148 [FBAN/FBIOS;FBAV/470.0.0.37.108;FBBV/612345678;FBDV/iPhone14,5;FBMD/iPhone;FBSN/iOS;FBSV/18.6;FBSS/3;FBID/phone;FBLC/fr_FR;FBOP/5]`, 'iphone', 'other', 'facebook');
  is(`${ANDROID_WV} [FB_IAB/FB4A;FBAV/470.0.0.43.109;]`, 'android', 'other', 'facebook');
  is(`${IPHONE} Mobile/15E148 musical_ly_34.5.0 JsSdk/2.0 NetType/WIFI Channel/App Store ByteLocale/en Region/US isDarkMode/0 WKWebView/1 BytedanceWebview/d8a21c6`, 'iphone', 'other', 'tiktok');
  is(`${ANDROID_WV} trill_340502 JsSdk/1.0 NetType/WIFI Channel/googleplay AppName/trill app_version/34.5.2 ByteLocale/en BytedanceWebview/d8a21c6`, 'android', 'other', 'tiktok');
});

test('what cannot be read is "other", never an exception', () => {
  is(undefined, 'other', 'other', '');
  is('', 'other', 'other', '');
  is('curl/8.7.1', 'other', 'other', '');
  is('Mozilla/5.0', 'other', 'other', '');
});

test('a very long User-Agent costs nothing', () => {
  const long = 'a'.repeat(10_000);
  classifyClient(long); // warm up
  const started = performance.now();
  is(long, 'other', 'other', '', '10 000 characters');
  is(`${'('.repeat(5_000)}${' Chrome/'.repeat(600)}`, 'other', 'other', '', 'only the first 512 characters are read');
  assert.ok(performance.now() - started < 5, 'under 5 ms');
});
