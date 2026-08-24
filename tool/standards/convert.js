// convert.js — Build compact growth-standards JSON assets from WHO/CDC raw files.
// Usage: node convert.js   (run from tool\standards)
const fs = require('fs');
const path = require('path');
const XLSX = require('xlsx');

const RAW = path.join(__dirname, 'raw');
const OUT = path.join(__dirname, '..', '..', 'assets', 'standards');

const r1 = (v) => Math.round(v * 10) / 10;
const r6 = (v) => Math.round(v * 1e6) / 1e6;

// ---------------------------------------------------------------- WHO xlsx ---
// Returns array of {x,l,m,s} sorted by x ascending.
function parseWhoXlsx(filename) {
  const wb = XLSX.readFile(path.join(RAW, filename));
  const ws = wb.Sheets[wb.SheetNames[0]];
  const rows = XLSX.utils.sheet_to_json(ws, { header: 1 });

  // Find header row: trimmed string cells include exactly "L","M","S" (ci).
  let hIdx = -1, cL = -1, cM = -1, cS = -1;
  for (let i = 0; i < rows.length; i++) {
    const cells = (rows[i] || []).map((c) =>
      String(c == null ? '' : c).trim().toLowerCase()
    );
    const iL = cells.indexOf('l');
    const iM = cells.indexOf('m');
    const iS = cells.indexOf('s');
    if (iL >= 0 && iM >= 0 && iS >= 0) {
      hIdx = i; cL = iL; cM = iM; cS = iS;
      break;
    }
  }
  if (hIdx < 0) throw new Error('No L/M/S header row found in ' + filename);

  const out = [];
  for (let i = hIdx + 1; i < rows.length; i++) {
    const row = rows[i];
    if (!row) continue;
    const x = Number(row[0]);
    if (!Number.isFinite(x)) continue;
    const L = Number(row[cL]);
    const M = Number(row[cM]);
    const S = Number(row[cS]);
    if (![L, M, S].every(Number.isFinite)) continue;
    out.push({ x: r1(x), l: r6(L), m: r6(M), s: r6(S) });
  }
  out.sort((a, b) => a.x - b.x);
  return out;
}

// Merge a 0-2y file (keep months <= 23) with a 2-5y file (keep months >= 24).
function mergeWho(file02, file25) {
  const a = parseWhoXlsx(file02).filter((r) => r.x <= 23);
  const b = parseWhoXlsx(file25).filter((r) => r.x >= 24);
  return a.concat(b).sort((x, y) => x.x - y.x);
}

// ---------------------------------------------------------------- CDC csv ----
// Returns {boys:[{x,l,m,s}...], girls:[...]} sorted by x ascending.
function parseCdcCsv(filename) {
  const text = fs.readFileSync(path.join(RAW, filename), 'utf8');
  const lines = text.split(/\r?\n/).filter((l) => l.trim().length > 0);
  const header = lines[0].split(',').map((h) => h.trim().toLowerCase());
  const iSex = header.indexOf('sex');
  const iL = header.indexOf('l');
  const iM = header.indexOf('m');
  const iS = header.indexOf('s');
  const iX = 1; // Agemos / Length / Stature — always column index 1
  if (iSex < 0 || iL < 0 || iM < 0 || iS < 0) {
    throw new Error('Unexpected CDC header in ' + filename + ': ' + lines[0]);
  }
  const boys = [];
  const girls = [];
  for (let i = 1; i < lines.length; i++) {
    const c = lines[i].split(',');
    const sex = Number(c[iSex]);
    const x = Number(c[iX]);
    const L = Number(c[iL]);
    const M = Number(c[iM]);
    const S = Number(c[iS]);
    if (!Number.isFinite(x) || ![L, M, S].every(Number.isFinite)) continue;
    const rec = { x: r1(x), l: r6(L), m: r6(M), s: r6(S) };
    if (sex === 1) boys.push(rec);
    else if (sex === 2) girls.push(rec);
  }
  boys.sort((a, b) => a.x - b.x);
  girls.sort((a, b) => a.x - b.x);
  return { boys, girls };
}

// ------------------------------------------------------------- packaging -----
function toColumnar(rows) {
  return {
    x: rows.map((r) => r.x),
    l: rows.map((r) => r.l),
    m: rows.map((r) => r.m),
    s: rows.map((r) => r.s),
  };
}
const pack = (boysRows, girlsRows) => ({
  boys: toColumnar(boysRows),
  girls: toColumnar(girlsRows),
});

console.log('Parsing WHO 2006 ...');
const who2006 = {
  wfa: pack(parseWhoXlsx('who06_wfa_boys.xlsx'), parseWhoXlsx('who06_wfa_girls.xlsx')),
  lhfa: pack(
    mergeWho('who06_lhfa_boys_0_2.xlsx', 'who06_lhfa_boys_2_5.xlsx'),
    mergeWho('who06_lhfa_girls_0_2.xlsx', 'who06_lhfa_girls_2_5.xlsx')
  ),
  wfl: pack(parseWhoXlsx('who06_wfl_boys.xlsx'), parseWhoXlsx('who06_wfl_girls.xlsx')),
  wfh: pack(parseWhoXlsx('who06_wfh_boys.xlsx'), parseWhoXlsx('who06_wfh_girls.xlsx')),
  bfa: pack(
    mergeWho('who06_bfa_boys_0_2.xlsx', 'who06_bfa_boys_2_5.xlsx'),
    mergeWho('who06_bfa_girls_0_2.xlsx', 'who06_bfa_girls_2_5.xlsx')
  ),
  hcfa: pack(parseWhoXlsx('who06_hcfa_boys.xlsx'), parseWhoXlsx('who06_hcfa_girls.xlsx')),
};

console.log('Parsing WHO 2007 ...');
const who2007 = {
  bfa: pack(parseWhoXlsx('who07_bfa_boys.xlsx'), parseWhoXlsx('who07_bfa_girls.xlsx')),
  hfa: pack(parseWhoXlsx('who07_hfa_boys.xlsx'), parseWhoXlsx('who07_hfa_girls.xlsx')),
  wfa: pack(parseWhoXlsx('who07_wfa_boys.xlsx'), parseWhoXlsx('who07_wfa_girls.xlsx')),
};

console.log('Parsing CDC 2000 ...');
const cdc2000 = {
  wtage: (() => { const d = parseCdcCsv('cdc_wtage.csv'); return pack(d.boys, d.girls); })(),
  statage: (() => { const d = parseCdcCsv('cdc_statage.csv'); return pack(d.boys, d.girls); })(),
  bmiage: (() => { const d = parseCdcCsv('cdc_bmiagerev.csv'); return pack(d.boys, d.girls); })(),
  wtageinf: (() => { const d = parseCdcCsv('cdc_wtageinf.csv'); return pack(d.boys, d.girls); })(),
  lenageinf: (() => { const d = parseCdcCsv('cdc_lenageinf.csv'); return pack(d.boys, d.girls); })(),
  wtleninf: (() => { const d = parseCdcCsv('cdc_wtleninf.csv'); return pack(d.boys, d.girls); })(),
  hcageinf: (() => { const d = parseCdcCsv('cdc_hcageinf.csv'); return pack(d.boys, d.girls); })(),
  wtstat: (() => { const d = parseCdcCsv('cdc_wtstat.csv'); return pack(d.boys, d.girls); })(),
};

// ------------------------------------------------------------------ write ----
fs.mkdirSync(OUT, { recursive: true });
const outputs = [
  ['who2006.json', who2006],
  ['who2007.json', who2007],
  ['cdc2000.json', cdc2000],
];
for (const [name, data] of outputs) {
  const json = JSON.stringify(data);
  fs.writeFileSync(path.join(OUT, name), json);
  console.log('Wrote ' + name + ' (' + Buffer.byteLength(json) + ' bytes)');
}

// ---------------------------------------------------------------- report -----
console.log('\n=== PER-TABLE REPORT ===');
function reportTable(setName, key, t) {
  for (const sex of ['boys', 'girls']) {
    const d = t[sex];
    const n = d.x.length;
    console.log(
      setName + '.' + key + '.' + sex +
      ': rows=' + n +
      ' x[' + d.x[0] + ' .. ' + d.x[n - 1] + ']' +
      ' m[first]=' + d.m[0] + ' m[last]=' + d.m[n - 1]
    );
  }
}
for (const k of Object.keys(who2006)) reportTable('who2006', k, who2006[k]);
for (const k of Object.keys(who2007)) reportTable('who2007', k, who2007[k]);
for (const k of Object.keys(cdc2000)) reportTable('cdc2000', k, cdc2000[k]);

// ------------------------------------------------------------- verification --
console.log('\n=== VERIFICATION ===');
let failures = 0;
function check(name, cond, detail) {
  console.log((cond ? 'PASS' : 'FAIL') + '  ' + name + (detail ? '  [' + detail + ']' : ''));
  if (!cond) failures++;
}
const approx = (a, b, tol) => Math.abs(a - b) <= tol;

let d = who2006.wfa.boys;
check('who06 wfa boys rows==61', d.x.length === 61, 'rows=' + d.x.length);
check('who06 wfa boys m[0]~3.3464', approx(d.m[0], 3.3464, 0.01), 'm[0]=' + d.m[0]);
check('who06 wfa boys m[12]~9.6479', approx(d.m[12], 9.6479, 0.01), 'm[12]=' + d.m[12]);

d = who2006.lhfa.boys;
check('who06 lhfa boys rows==61', d.x.length === 61, 'rows=' + d.x.length);
check('who06 lhfa boys m[0]~49.8842', approx(d.m[0], 49.8842, 0.05), 'm[0]=' + d.m[0]);
check('who06 lhfa boys m[24]~87.1', approx(d.m[24], 87.1, 0.3), 'm[24]=' + d.m[24]);

d = who2006.hcfa.boys;
check('who06 hcfa boys rows==61', d.x.length === 61, 'rows=' + d.x.length);
check('who06 hcfa boys m[0]~34.5', approx(d.m[0], 34.5, 0.1), 'm[0]=' + d.m[0]);

d = who2006.wfl.boys;
check('who06 wfl boys first x~45.0', approx(d.x[0], 45.0, 0.01), 'x[0]=' + d.x[0]);
check('who06 wfl boys rows 130-140', d.x.length >= 130 && d.x.length <= 140, 'rows=' + d.x.length);

d = who2006.bfa.boys;
check('who06 bfa boys rows==61', d.x.length === 61, 'rows=' + d.x.length);
check('who06 bfa boys m[0]~13.4', approx(d.m[0], 13.4, 0.2), 'm[0]=' + d.m[0]);

d = who2007.hfa.boys;
check('who07 hfa boys rows==168', d.x.length === 168, 'rows=' + d.x.length);
check('who07 hfa boys m[0]~110.0', approx(d.m[0], 110.0, 1), 'm[0]=' + d.m[0]);

d = who2007.bfa.boys;
check('who07 bfa boys rows==168', d.x.length === 168, 'rows=' + d.x.length);
check('who07 bfa boys m[0]~15.3', approx(d.m[0], 15.3, 0.3), 'm[0]=' + d.m[0]);

d = who2007.wfa.boys;
check('who07 wfa boys rows==60', d.x.length === 60, 'rows=' + d.x.length);
check('who07 wfa boys m[0]~18.3 (weight, not height)', approx(d.m[0], 18.3, 0.5), 'm[0]=' + d.m[0]);

d = cdc2000.wtage.boys;
check('cdc wtage boys rows 215-220', d.x.length >= 215 && d.x.length <= 220, 'rows=' + d.x.length);
// Current cdc.gov wtage.csv includes integer-month endpoint rows (24 and 240)
// in addition to half-month points, so first x is 24 (older revisions started
// at 24.5). Accept either; m[0] check below confirms the value is right.
check('cdc wtage boys first x~24.5', approx(d.x[0], 24.5, 0.5), 'x[0]=' + d.x[0]);
check('cdc wtage boys m[0]~12.6', approx(d.m[0], 12.6, 0.3), 'm[0]=' + d.m[0]);

d = cdc2000.lenageinf.boys;
check('cdc lenageinf boys rows~37', d.x.length >= 35 && d.x.length <= 39, 'rows=' + d.x.length);
check('cdc lenageinf boys m[0]~49.99', approx(d.m[0], 49.99, 0.1), 'm[0]=' + d.m[0]);

console.log('\n' + (failures === 0 ? 'ALL CHECKS PASSED' : failures + ' CHECK(S) FAILED'));
process.exit(failures === 0 ? 0 : 1);
