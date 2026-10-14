import { chromium } from '@playwright/test';
const BASE = 'https://kdportal.com.tr';
const pages = ['/giris','/sifre','/kurulum','/dashboard','/admin','/admin/approvals','/projects/new'];
const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium' });
const ctx = await browser.newContext({ ignoreHTTPSErrors: true });
const page = await ctx.newPage();
const api = [];
page.on('response', async r => { const u=r.url(); if(/\/api\//.test(u)) api.push(`${r.request().method()} ${u.replace(BASE,'')} -> ${r.status()}`); });
for (const route of pages) {
  try {
    await page.goto(BASE+route, { waitUntil:'networkidle', timeout:25000 });
    await page.waitForTimeout(1000);
    const inputs = await page.evaluate(() => [...document.querySelectorAll('input,textarea,select')].map(el=>({t:el.type||el.tagName,name:el.name||el.getAttribute('aria-label')||el.placeholder||'',ph:el.placeholder||''})));
    const buttons = await page.evaluate(() => [...document.querySelectorAll('button,[role=button],a')].map(b=>(b.innerText||b.getAttribute('aria-label')||'').trim()).filter(Boolean).slice(0,25));
    console.log(`\n### ${route}`);
    console.log('INPUTS:', JSON.stringify(inputs));
    console.log('BUTTONS/LINKS:', JSON.stringify([...new Set(buttons)]));
    await page.screenshot({ path:`artifacts/shot${route.replace(/\//g,'_')}.png`, fullPage:true });
  } catch(e){ console.log(`\n### ${route} ERROR ${e.message.split('\n')[0]}`); }
}
console.log('\n=== API calls observed ===\n'+[...new Set(api)].join('\n'));
await browser.close();
