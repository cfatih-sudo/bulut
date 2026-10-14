import { chromium } from '@playwright/test';

const BASE = 'https://kdportal.com.tr';
const routes = ['/', '/login', '/giris', '/kayit', '/register', '/uye-ol', '/sifremi-unuttum', '/forgot-password', '/panel', '/dashboard', '/profil', '/setup', '/+not-found', '/_sitemap'];

const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium' });
const ctx = await browser.newContext({ ignoreHTTPSErrors: true });
const page = await ctx.newPage();

const consoleErrs = [];
const netFails = [];
const apiCalls = [];
page.on('console', m => { if (m.type()==='error') consoleErrs.push(m.text()); });
page.on('requestfailed', r => netFails.push(`${r.method()} ${r.url()} :: ${r.failure()?.errorText}`));
page.on('request', r => { const u=r.url(); if(!/kdportal\.com\.tr\/_expo|\.(js|css|svg|png|woff2?|ico|map)(\?|$)/.test(u)) apiCalls.push(`${r.method()} ${u}`); });

for (const route of routes) {
  const url = BASE + route;
  try {
    const resp = await page.goto(url, { waitUntil: 'networkidle', timeout: 25000 });
    await page.waitForTimeout(1200);
    const status = resp ? resp.status() : 'n/a';
    const title = await page.title();
    const bodyText = (await page.evaluate(() => document.body.innerText || '')).replace(/\s+/g,' ').trim().slice(0, 300);
    console.log(`\n### ${route}  [HTTP ${status}]  title="${title}"`);
    console.log(`TEXT: ${bodyText}`);
  } catch (e) {
    console.log(`\n### ${route}  ERROR: ${e.message.split('\n')[0]}`);
  }
}

console.log('\n\n=== CONSOLE ERRORS ===\n' + ([...new Set(consoleErrs)].slice(0,20).join('\n') || '(none)'));
console.log('\n=== NETWORK FAILURES ===\n' + ([...new Set(netFails)].slice(0,20).join('\n') || '(none)'));
console.log('\n=== NON-ASSET REQUESTS (possible API) ===\n' + ([...new Set(apiCalls)].slice(0,40).join('\n') || '(none)'));

await browser.close();
