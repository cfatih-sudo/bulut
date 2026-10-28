// jetbilisim.com.tr musteri akisi testi (Playwright).
// Calistirma: npm i -D playwright && npx playwright install chromium
//   mkdir -p test-cikti/shots && node tests/musteri-akisi.js         -> siparis GONDERMEZ
//   SUBMIT=1 node tests/musteri-akisi.js                             -> gercek test siparisi olusturur
// Not: sitedeki 'kopyalama botlarini engelle' ayari aciksa headless tarayici 403 alir.
const { chromium } = require('playwright');
const fs = require('fs');
const OUT=process.env.OUT||'test-cikti'; const log=[]; let n=0;
const PASS = 'JetTest' + Math.random().toString(36).slice(2,8) + '9';
(async () => {
  const b = await chromium.launch();
  const ctx = await b.newContext({ locale:'tr-TR', viewport:{width:1366,height:850}, recordVideo:{dir:OUT+'/video', size:{width:1366,height:850}} });
  await ctx.grantPermissions(['clipboard-read','clipboard-write']);
  const p = await ctx.newPage();
  const errs=[]; p.on('pageerror',e=>errs.push({url:p.url(),msg:'JS hatası: '+e.message}));
  p.on('response', r => { if (r.status()>=400) errs.push({url:p.url(),msg:r.status()+' '+r.url().slice(0,150)}); });
  const shot = async (title, note, full=false) => { n++; const f=`shots/${String(n).padStart(2,'0')}.png`; await p.screenshot({path:OUT+'/'+f, fullPage:full}).catch(()=>{}); log.push({n,title,note,file:f,url:p.url(),time:new Date().toISOString()}); console.log(n,title,'|',note); };
  const go = async u => { const t=Date.now(); await p.goto(u,{waitUntil:'networkidle',timeout:60000}); return Date.now()-t; };
  try {
  let t = await go('https://jetbilisim.com.tr/');
  await shot('Ana sayfa', `jetbilisim.com.tr açıldı (${t} ms). Çerez bandı görünüyor.`);
  const cb = p.getByRole('button',{name:'Tümünü kabul et'}); if (await cb.isVisible().catch(()=>false)) { await cb.click(); await p.waitForTimeout(500); await shot('Çerez onayı','"Tümünü kabul et" tıklandı, bant kapandı.'); }
  t = await go('https://jetbilisim.com.tr/paketler/');
  await shot('Paketler sayfası', `Paketler ve fiyatlar (${t} ms).`);
  await p.locator('text=Jet KOBİ Premium').filter({hasText:/^Jet KOBİ Premium$/}).last().scrollIntoViewIfNeeded().catch(()=>{}); await p.waitForTimeout(500);
  await shot('Paket kartları', 'Jet Başla 14.990 ₺, Jet KOBİ 27.990 ₺, Jet KOBİ Premium 36.990 ₺ (+KDV).');
  t = await go('https://jetbilisim.com.tr/demolar/');
  await shot('Demolar sayfası', `Kategori kartları (${t} ms). Kartların hepsi demo vitrininin ana sayfasına gidiyor, kategoriye değil.`, true);
  t = await go('https://demo.jetbilisim.com.tr/');
  await shot('Demo vitrini', `213 demo, 23 kategori (${t} ms).`);
  await p.getByRole('button',{name:/^Yeme & İçme/}).click(); await p.waitForTimeout(1200);
  await shot('Kategori filtresi', '"Yeme & İçme" kategorisi seçildi.');
  await p.locator('#dg-q').fill('restoran').catch(()=>{}); await p.waitForTimeout(1200);
  await shot('Arama', '"restoran" arandı.');
  await p.locator('#dg-q').fill('JD-801').catch(()=>{}); await p.waitForTimeout(1200);
  await shot('Demo koduyla arama', '"JD-801" arandı.');
  t = await go('https://demo.jetbilisim.com.tr/demo/JD-801/');
  await p.waitForTimeout(1500);
  await shot('Demo: Lezzet Durağı (JD-801)', `Demo açıldı (${t} ms). Başlangıç: Header "Bölünmüş", Footer "Haritalı mega footer", 5 bölüm.`);
  await p.locator('.dg-pk-btn').nth(0).click(); await p.waitForTimeout(5000);
  await shot('Header seçici', 'Header seçici açıldı ve 5 sn beklendi. Önizleme kartları boş/çizgili görünüyor. Fareyle üzerine gelince açılan önizleme kutusu da boş ve seçicinin dışına taşıyor.');
  const hdrCard = p.locator(':text-is("Ortalı logo"):visible').first();
  let ok = await hdrCard.click({timeout:5000}).then(()=>true).catch(()=>false);
  if (!ok) { await p.selectOption('#dg-pv-hdr','centered'); await p.locator('#dg-pv-hdr').dispatchEvent('change'); }
  await p.waitForTimeout(3000);
  await shot('Header değişti: Ortalı logo', ok?'Kart tıklandı.':'Kart tıklanamadı; seçim gizli liste üzerinden yapıldı.');
  await p.keyboard.press('Escape');
  await p.locator('.dg-pk-btn').nth(1).click(); await p.waitForTimeout(1500);
  ok = await p.locator(':text-is("Bülten odaklı"):visible').first().click({timeout:5000}).then(()=>true).catch(()=>false);
  if (!ok) { await p.selectOption('#dg-pv-ftr','newsletter'); await p.locator('#dg-pv-ftr').dispatchEvent('change'); }
  await p.waitForTimeout(3000); await p.keyboard.press('Escape');
  await shot('Footer değişti: Bülten odaklı', ok?'Kart tıklandı.':'Kart tıklanamadı; seçim gizli liste üzerinden yapıldı.');
  const st = async()=>p.evaluate(()=>({code:document.querySelector('input.dgc-code').value,hdr:document.querySelectorAll('.dg-pk-btn')[0].innerText.trim().split('\n')[0],ftr:document.querySelectorAll('.dg-pk-btn')[1].innerText.trim().split('\n')[0]}));
  console.log('state', JSON.stringify(await st()));
  await p.locator('[data-a=shuf]').nth(1).click(); await p.waitForTimeout(2500);
  await shot('Bölüm değişti', '2. bölüm (Projeler/galeri) 🔀 ile başka bir tasarıma çevrildi. Düzen kodu: '+(await st()).code);
  await p.locator('[data-a=del]').nth(3).click(); await p.waitForTimeout(2500);
  await shot('Bölüm silindi', '4. bölüm (Yorumlar) ✕ ile silindi. Düzen kodu: '+(await st()).code);
  await p.locator('[data-a=undo]').click(); await p.waitForTimeout(2500);
  await shot('Geri al', '↶ ile silme geri alındı. Düzen kodu: '+(await st()).code);
  await p.locator('[data-a=redo]').click(); await p.waitForTimeout(2500);
  await shot('İleri al', '↷ ile silme tekrar uygulandı. Düzen kodu: '+(await st()).code);
  await p.locator('button[data-w="390px"]').click(); await p.waitForTimeout(3000);
  await shot('Mobil görünüm', 'Telefon (390 px) önizlemesi.');
  await p.locator('button[data-w="820px"]').click(); await p.waitForTimeout(3000);
  await shot('Tablet görünüm', 'Tablet (820 px) önizlemesi.');
  await p.locator('button[data-w="100%"]').click(); await p.waitForTimeout(1500);
  const finalState = await st(); console.log('final', JSON.stringify(finalState));
  await p.locator('#sc-share').click(); await p.waitForTimeout(1000);
  const share = await p.evaluate(()=>navigator.clipboard.readText().catch(()=>'' ));
  await shot('Bağlantıyı paylaş', 'Paylaşım linki: '+share+' — linkte header, footer ve bölüm düzeni var.');
  // open share link in new tab to check restore
  const p2 = await ctx.newPage(); await p2.goto(share,{waitUntil:'networkidle'}); await p2.waitForTimeout(2000);
  const st2 = await p2.evaluate(()=>({code:document.querySelector('input.dgc-code').value,hdr:document.querySelectorAll('.dg-pk-btn')[0].innerText.trim().split('\n')[0],ftr:document.querySelectorAll('.dg-pk-btn')[1].innerText.trim().split('\n')[0]}));
  n++; await p2.screenshot({path:`${OUT}/shots/${String(n).padStart(2,'0')}.png`}); log.push({n,title:'Paylaşım linki yeni sekmede',note:`Header: ${st2.hdr}, Footer: ${st2.ftr}, Düzen: ${st2.code}`,file:`shots/${String(n).padStart(2,'0')}.png`,url:share}); console.log(n,'share reopened',JSON.stringify(st2)); await p2.close();
  await p.getByRole('link',{name:'EN'}).first().click().catch(()=>{}); await p.waitForLoadState('networkidle'); await p.waitForTimeout(2000);
  const st3 = await st().catch(()=>({}));
  await shot('Dil: İngilizce', 'EN seçildi. Sonrasında: Header '+st3.hdr+', Footer '+st3.ftr+', Düzen '+st3.code);
  await p.getByRole('link',{name:'TR'}).first().click().catch(()=>{}); await p.waitForLoadState('networkidle');
  // redo customizations quickly before ordering
  await p.selectOption('#dg-pv-hdr','centered'); await p.locator('#dg-pv-hdr').dispatchEvent('change');
  await p.selectOption('#dg-pv-ftr','newsletter'); await p.locator('#dg-pv-ftr').dispatchEvent('change'); await p.waitForTimeout(2000);
  await p.locator('.sc-cta-pk').click(); await p.waitForTimeout(1000);
  await shot('Paket seçimi', '"Paket seçin, başlayın" açıldı. Header/Footer tekrar Ortalı logo / Bülten odaklı yapıldı.');
  const href = await p.locator('a[href*="paket=jet_premium"]').first().getAttribute('href');
  await p.locator('a[href*="paket=jet_premium"]').first().click(); await p.waitForLoadState('networkidle');
  await shot('Sipariş sayfası – Adım 1', 'Jet KOBİ Premium seçildi. Gidilen adres: '+p.url()+' — adreste demo kodu, header ve footer var; bölüm düzeni (değiştirilen/silinen bölümler) yok.');
  const pageTxt = await p.innerText('body'); console.log('order mentions layout?', /Ortalı|Bülten|duzen|düzen/i.test(pageTxt));
  // validation: continue empty
  await p.getByRole('button',{name:/Devam et/}).first().click(); await p.waitForTimeout(1000);
  await shot('Doğrulama: boş alan adı', 'Alan adı boşken "Devam et" tıklandı.');
  await p.check('input[name=alan_tur][value=var]'); await p.fill('input[name=alan]','bu bir alan adi degil'); await p.getByRole('button',{name:/Devam et/}).first().click(); await p.waitForTimeout(1000);
  await shot('Doğrulama: geçersiz alan adı', '"bu bir alan adi degil" yazıp "Devam et" tıklandı → form kabul edip 2. adıma geçti.');
  await p.locator('button:visible',{hasText:'Geri'}).first().click().catch(()=>{}); await p.waitForTimeout(800);
  await p.locator('label:visible',{hasText:'Henüz karar vermedim'}).first().click(); await p.waitForTimeout(500);
  const sideBefore = await p.locator('aside, .ds-side, [class*=side]').first().innerText().catch(()=>'');
  await p.locator('label:visible',{hasText:'İngilizce'}).first().click(); await p.locator('input[name="eklenti[]"][value=ai]').check({force:true}); await p.waitForTimeout(800);
  const sideAfter = await p.locator('aside, .ds-side, [class*=side]').first().innerText().catch(()=>'');
  console.log('SIDE CHANGED?', sideBefore!==sideAfter, '\n', sideAfter.slice(0,600));
  await shot('Adım 1 dolduruldu', '"Henüz karar vermedim", İngilizce dil (+5.550 TL) ve Yapay zekâ asistanı (+3.900 TL/yıl) seçildi.', true);
  await p.getByRole('button',{name:/Devam et/}).first().click(); await p.waitForTimeout(1500);
  await shot('Adım 2 – Bilgileriniz', 'İkinci adıma geçildi.');
  const cont2 = p.locator('form button:visible').filter({hasText:/Devam|İleri|Kontrol/});
  await cont2.first().click().catch(()=>{}); await p.waitForTimeout(1000);
  await shot('Doğrulama: boş bilgiler', 'Alanlar boşken devam denendi.');
  await p.locator('label:visible',{hasText:/^\s*Firma\s*$/}).first().click().catch(()=>{});
  await p.fill('input[name=name]','TEST - Claude Otomatik Test Ltd.');
  await p.fill('input[name=contact_name]','Claude Test');
  await p.fill('input[name=tax_office]','Tuzla');
  await p.fill('input[name=email]','cfatih@gmail');
  await p.fill('input[name=phone]','123');
  await p.fill('input[name=address]','TEST ADRESİ - gerçek sipariş değildir');
  await p.fill('input[name=city]','İstanbul');
  await p.fill('input[name=password]','abc'); await p.fill('input[name=password2]','abcd');
  await cont2.first().click().catch(()=>{}); await p.waitForTimeout(1000);
  await shot('Doğrulama: hatalı e-posta/telefon/parola', 'E-posta "cfatih@gmail", telefon "123", parola "abc"/"abcd" (uyuşmuyor) ile devam denendi.', true);
  await p.fill('input[name=email]','cfatih@gmail.com');
  await p.fill('input[name=phone]','0555 000 00 00');
  await p.fill('input[name=tax_no]','1111111111');
  await p.fill('input[name=password]',PASS); await p.fill('input[name=password2]',PASS);
  await p.fill('textarea[name=not]','BU BİR TEST SİPARİŞİDİR. Claude (yapay zekâ) tarafından site sahibinin isteğiyle sistem testi için oluşturuldu. İşleme almayın. Demo düzeni: Header Ortalı logo, Footer Bülten odaklı.');
  await shot('Adım 2 dolduruldu', 'Firma, unvan "TEST - Claude Otomatik Test Ltd.", yetkili "Claude Test", vergi dairesi Tuzla, vergi no 1111111111 (test), e-posta cfatih@gmail.com, telefon 0555 000 00 00 (sahte), adres "TEST ADRESİ", İstanbul, not alanına test açıklaması.', true);
  await cont2.first().click().catch(()=>{}); await p.waitForTimeout(1500);
  await shot('Adım 3 – Kontrol ve onay', 'Özet ekranı.', true);
  const sub = p.locator('button:visible',{hasText:'onaya gönder'});
  await sub.click().catch(()=>{}); await p.waitForTimeout(1500);
  await shot('Doğrulama: onay kutusu', 'KVKK/hizmet koşulları onayı işaretlenmeden "Siparişi onaya gönder" tıklandı.');
  fs.writeFileSync(OUT+'/pre_submit_text.txt', await p.innerText('body'));
  await p.locator('input[name=agree]').check({force:true});
  await shot('Onay kutusu işaretlendi', 'Hizmet koşulları/KVKK onaylandı. Kampanya e-postası onayı işaretlenmedi.');
  if (process.env.SUBMIT==='1') {
    await Promise.all([p.waitForLoadState('networkidle').catch(()=>{}), sub.click()]); await p.waitForTimeout(3000);
    await shot('Sipariş gönderildi', 'Sonuç sayfası: '+p.url(), true);
    fs.writeFileSync(OUT+'/result_text.txt', await p.innerText('body'));
  }
  } catch(e) { console.log('FLOW ERROR', e.message); await shot('Akış hatası', e.message.slice(0,300)); }
  fs.writeFileSync(OUT+'/log.json', JSON.stringify({log, errs, pass:PASS},null,1));
  await ctx.close(); await b.close();
  console.log('ERRS', JSON.stringify([...new Map(errs.map(e=>[e.msg,e])).values()],null,0));
})();
