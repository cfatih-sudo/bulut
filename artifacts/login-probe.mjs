import { chromium } from '@playwright/test';
const BASE='https://kdportal.com.tr';
const b = await chromium.launch({ executablePath:'/opt/pw-browsers/chromium' });
const ctx = await b.newContext({ ignoreHTTPSErrors:true });
const p = await ctx.newPage();
await p.goto(BASE+'/giris',{waitUntil:'networkidle'});
// empty submit
await p.getByRole('button',{name:/Giriş yap/i}).click();
await p.waitForTimeout(800);
let t1=(await p.evaluate(()=>document.body.innerText)).replace(/\s+/g,' ');
console.log('AFTER EMPTY SUBMIT (errors?):', t1.match(/(zorunlu|gerekli|geçerli|hatalı|eksik|en az|boş)[^.]*\.?/gi)?.slice(0,8));
// fill bad creds
await p.fill('input[type=email]','nouser@example.com');
await p.fill('input[type=password]','wrongpass123');
const [resp] = await Promise.all([
  p.waitForResponse(r=>/\/api\/auth\/login/.test(r.url()), {timeout:15000}).catch(()=>null),
  p.getByRole('button',{name:/Giriş yap/i}).click(),
]);
await p.waitForTimeout(1000);
if(resp) console.log('LOGIN API:', resp.request().method(), resp.url().replace(BASE,''), '->', resp.status());
let t2=(await p.evaluate(()=>document.body.innerText)).replace(/\s+/g,' ');
console.log('AFTER BAD CREDS UI MSG:', t2.match(/(hatalı|geçersiz|yanlış|bulunamadı|başarısız|E-posta veya)[^.]*\.?/gi)?.slice(0,6));
// cookies after attempt
console.log('COOKIES:', (await ctx.cookies()).map(c=>({name:c.name,httpOnly:c.httpOnly,secure:c.secure,sameSite:c.sameSite})));
await b.close();
