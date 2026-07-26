#!/usr/bin/env python3
"""scripts/pm-dashboard-render.py - client project-frontier dashboard renderer.

The client (project-side) realization of the `/pm-dashboard` render contract
(docs/pack/PM-DASHBOARD-SPEC.md). It authors the presentation (CSS + hash
router + per-view render functions) as versioned string constants, assembles
the COMPLETE `#state` (the session layer + every backed section + a live git
read), and refuses to emit a board that fails its own complete DATA floor.

This is the client's OWN copy: it ships in the project template
(project-template/scripts/) and a project operation (`/pm-dashboard`) invokes
it. It shares no code with, and imports nothing from, any pack-side renderer;
the two surfaces are separate by design. stdlib-only.

Two modes (argparse):
  build  [--repo-root R] [--spec P]  collect fresh state -> author/reuse the
      shell -> inject `#state` -> run `verify` INLINE, ATOMICALLY (render into a
      temp path, verify it, rename into dashboard.html ONLY on PASS; delete the
      temp on FAIL) so a failed build leaves NO hollow board on disk.
  verify [--repo-root R] [--spec P]  the COMPLETE DATA floor: re-derive the
      expected board INDEPENDENTLY from the live tree (re-reading disk, not
      trusting build's in-memory objects), parse the produced dashboard.html
      `#state`, and assert the session layer, every backed section, the
      parse/encoding invariants, and the render-token smoke. Exit non-zero
      with a per-shortfall list on any miss.

`--repo-root` defaults to the script's git toplevel; `--spec` defaults to
docs/pack/PM-DASHBOARD-SPEC.md - parameters, not hardcoded. Enumerated sets are
drawn from git-tracked files (`git ls-files`), never a raw FS walk; O(lines)/
O(one dir), no whole-tree walk; verify is SKIP-lenient off a git work tree.
"""
import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

# ---------- layout constants ----------
SPEC_REL_DEFAULT = "docs/pack/PM-DASHBOARD-SPEC.md"
APPROVALS_REL = "docs/project/dashboard-approvals"
DASHBOARD_NAME = "dashboard.html"
SHELL_NAME = "dashboard-shell.html"

# The state element is injected by REPLACING this exact placeholder (targeted,
# single-count) - NOT a global token replace, which would also clobber the JS's
# own defensive sentinel guard `indexOf('__PM_DASHBOARD_STATE__')` (gap 1).
STATE_SENTINEL = "__PM_DASHBOARD_STATE__"
STATE_PLACEHOLDER = ">" + STATE_SENTINEL + "</script>"

# ---------- backlog (TD) vocabulary ----------
# KNOWN GAP(polish): TD-TBD - TD-entry schema regexes hardcoded, not spec-driven.
# Scoped PRECISELY to the schema regex / format-string set below - the title
# regex, the id regex, the backlog-path regex, and the `TD-%03d` id format
# string: these are retargeted inline for the client project's TD data model
# rather than read from PM-DASHBOARD-SPEC.md at build. They are compiled `re`
# objects and a `%`-format string consumed with capture-group / format semantics
# across the collection layer; spec-driving them would require compiling
# doc-sourced regex strings at runtime (a new parse-abort / ReDoS surface and a
# doc<->code coupling the pack engine does not have), so a straight retarget is
# the correct disposition now and spec-parameterization is the deferred polish.
# NOT part of this gap: the layout path constants above (SPEC_REL_DEFAULT /
# APPROVALS_REL / DASHBOARD_NAME / SHELL_NAME). Hardcoding them (retargeted to the
# client tree, never spec-driven) is INTENTIONAL parity with the pack engine's own
# hardcoded-path design - the correct steady state, not deferred tech debt.
NON_TERMINAL = {"Open", "Unblocked", "Deferred"}
STATUS_TOKEN = {"Open": "pending", "Unblocked": "unblocked", "Deferred": "deferred",
                "Resolved": "done", "Deprecated": "deprecated", "Cancelled": "cancelled"}
STATUS_VOCAB = set(STATUS_TOKEN)  # fallback if docs/project/backlog/_rules.md cannot be read
NEWEST_RESOLVED_N = 10
BODY_MIN, SHINGLE, JACCARD_MIN = 40, 20, 0.30

# ---------- render-surface smoke tokens (measured against the authored shell) ----------
# The render surface is exactly these 10 nav route tokens + 11 p* render
# functions. Do NOT add a `rulings` token or a 12th nav token - it would
# false-fail (Rulings is spec-optional + UNIMPLEMENTED in the render layer).
NAV_ROUTE_TOKENS = ["landing", "frontier", "grand-plan", "archive", "methodology",
                    "rules", "deps", "changelog", "metrics", "help"]
RENDER_FN_TOKENS = ["pLanding", "pFrontier", "pGrand", "pTD", "pArchive",
                    "pMethodology", "pRules", "pDeps", "pChangelog", "pMetrics", "pHelp"]

_STATUS_RE = re.compile(r"^Status:\s*(\w+)", re.M)
_RESOLVED_RE = re.compile(r"^Resolution:\s*(.+)$", re.M)
_DATE_RE = re.compile(r"(20\d\d-\d\d-\d\d)")
_TITLE_RE = re.compile(r"^\*\*TD-\d+\s*[-\u2014]\s*(.+?)\*\*", re.M)
_TD_ID_RE = re.compile(r"TD-(\d+)")
_META_FIELD_RE = re.compile(r"^(Type|Marker|Status|Target|Blockers|Unblocks|Resolution|"
                            r"Position|File/Symbol|References|Source|Disposition):")


# ============================================================================
# Presentation authored as committed source (adapted from the reference shell).
# The CSS + JS (hash router + the 11 p* render functions) are versioned +
# diff-able. All static glyphs are HTML numeric entities (ASCII-safe, gap 3);
# this source file carries ZERO non-ASCII bytes.
# ============================================================================
CSS = r"""
*{box-sizing:border-box}
:root{
 --bg:#f4f6f9;--surface:#fff;--surface-2:#eef1f6;--surface-3:#e6eaf1;--line:#dbe1ea;
 --ink:#172231;--ink-mid:#546072;--ink-faint:#8b95a4;
 --accent:#0e7488;--accent-ink:#0a5768;--accent-soft:#dceef1;
 --done:#1f9558;--done-soft:#e0f0e6;--active:#b26f0c;--active-soft:#f7ebd7;
 --pending:#96a0af;--pending-soft:#edf0f4;--blocker:#c0473c;--blocker-soft:#f7e3e0;
 --gate:#6a51c0;--gate-soft:#ebe6f8;
 --radius:10px;--fs:15px}
@media (prefers-color-scheme:dark){:root{
 --bg:#0d1219;--surface:#151c26;--surface-2:#1a2230;--surface-3:#202a39;--line:#28323f;
 --ink:#e6ecf3;--ink-mid:#9aa5b4;--ink-faint:#6b7583;
 --accent:#3cbdcf;--accent-ink:#8fdbe7;--accent-soft:#123039;
 --done:#43c489;--done-soft:#123026;--active:#e2a83f;--active-soft:#33270f;
 --pending:#6b7583;--pending-soft:#1c2431;--blocker:#e5786c;--blocker-soft:#331d1a;
 --gate:#a08ee6;--gate-soft:#241d3a}}
:root[data-theme="dark"]{
 --bg:#0d1219;--surface:#151c26;--surface-2:#1a2230;--surface-3:#202a39;--line:#28323f;
 --ink:#e6ecf3;--ink-mid:#9aa5b4;--ink-faint:#6b7583;
 --accent:#3cbdcf;--accent-ink:#8fdbe7;--accent-soft:#123039;
 --done:#43c489;--done-soft:#123026;--active:#e2a83f;--active-soft:#33270f;
 --pending:#6b7583;--pending-soft:#1c2431;--blocker:#e5786c;--blocker-soft:#331d1a;
 --gate:#a08ee6;--gate-soft:#241d3a}
:root[data-theme="light"]{
 --bg:#f4f6f9;--surface:#fff;--surface-2:#eef1f6;--surface-3:#e6eaf1;--line:#dbe1ea;
 --ink:#172231;--ink-mid:#546072;--ink-faint:#8b95a4;
 --accent:#0e7488;--accent-ink:#0a5768;--accent-soft:#dceef1;
 --done:#1f9558;--done-soft:#e0f0e6;--active:#b26f0c;--active-soft:#f7ebd7;
 --pending:#96a0af;--pending-soft:#edf0f4;--blocker:#c0473c;--blocker-soft:#f7e3e0;
 --gate:#6a51c0;--gate-soft:#ebe6f8}
html,body{margin:0;padding:0}
body{background:var(--bg);color:var(--ink);font:var(--fs)/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif}
.app{display:flex;min-height:100vh;background:var(--bg)}
a{color:var(--accent);text-decoration:none}
a:hover{text-decoration:underline}
aside{width:248px;min-width:248px;position:sticky;top:0;height:100vh;overflow:auto;background:var(--surface);border-right:1px solid var(--line);padding:18px 14px}
.brand{font-weight:700;font-size:1.05rem;color:var(--ink);margin-bottom:2px}
.brand .v{display:block;font-size:.72rem;color:var(--ink-mid);font-weight:500;margin-top:2px}
.navgroup{margin-top:18px}
.navgroup h4{font-size:.68rem;text-transform:uppercase;letter-spacing:.06em;color:var(--ink-faint);margin:0 0 6px 4px}
.navgroup a{display:flex;align-items:center;gap:7px;padding:5px 8px;border-radius:7px;color:var(--ink-mid);font-size:.86rem}
.navgroup a:hover{background:var(--surface-2);text-decoration:none}
.navgroup a.on{background:var(--accent-soft);color:var(--accent-ink);font-weight:600}
.dot{width:8px;height:8px;border-radius:50%;flex:none;background:var(--pending)}
.dot.done{background:var(--done)}.dot.active{background:var(--active)}.dot.pending{background:var(--pending)}
.dot.unblocked{background:var(--pending)}.dot.blocker{background:var(--blocker)}
.dot.deferred,.dot.deprecated,.dot.cancelled{background:var(--ink-faint)}
main{flex:1;max-width:900px;margin:0 auto;padding:30px 34px 80px}
.eyebrow{font-size:.72rem;text-transform:uppercase;letter-spacing:.08em;color:var(--accent-ink);font-weight:700}
h1{font-size:1.9rem;margin:.1em 0 .3em}
h2{font-size:1.15rem;margin:1.6em 0 .5em}
.lede{color:var(--ink-mid);margin:0 0 4px}
.card{background:var(--surface);border:1px solid var(--line);border-radius:var(--radius);padding:16px 18px;margin:12px 0}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(150px,1fr));gap:12px}
.tile{background:var(--surface);border:1px solid var(--line);border-radius:var(--radius);padding:14px 16px}
.tile .k{font-size:.7rem;text-transform:uppercase;letter-spacing:.05em;color:var(--ink-faint)}
.tile .v{font-size:1.5rem;font-weight:700;margin-top:3px}
.tile .s{font-size:.76rem;color:var(--ink-mid)}
.kv{display:grid;grid-template-columns:170px 1fr;gap:6px 14px;font-size:.9rem}
.kv .k{color:var(--ink-mid)}
.pill{display:inline-block;padding:1px 9px;border-radius:999px;font-size:.72rem;font-weight:600;white-space:nowrap}
.pill.done{background:var(--done-soft);color:var(--done)}
.pill.active{background:var(--active-soft);color:var(--active)}
.pill.pending{background:var(--pending-soft);color:var(--ink-mid)}
.pill.unblocked{background:var(--pending-soft);color:var(--pending)}
.pill.blocker{background:var(--blocker-soft);color:var(--blocker)}
.pill.neutral{background:var(--pending-soft);color:var(--ink-faint)}
.pill.accent{background:var(--accent-soft);color:var(--accent-ink)}
.pill.gate{background:var(--gate-soft);color:var(--gate)}
.chip{display:inline-block;padding:1px 7px;border-radius:6px;font-size:.68rem;font-weight:600;background:var(--accent-soft);color:var(--accent-ink);margin-left:5px}
.chip.gate{background:var(--gate-soft);color:var(--gate)}
.chip.here{background:var(--active-soft);color:var(--active)}
.chip.fresh{background:var(--done-soft);color:var(--done)}
.chip.behind{background:var(--surface-3);color:var(--ink-mid)}
.chip.live{background:var(--active-soft);color:var(--active)}
.row{display:flex;gap:10px;align-items:flex-start;padding:9px 0;border-top:1px solid var(--line)}
.row:first-child{border-top:0}
.row .idx{color:var(--ink-faint);font-variant-numeric:tabular-nums;min-width:22px}
.row .main{flex:1;min-width:0}
.row .ttl{font-weight:600}
.row .note{color:var(--ink-mid);font-size:.83rem}
.bar{height:8px;border-radius:5px;background:var(--surface-3);overflow:hidden;margin:6px 0}
.bar>i{display:block;height:100%;background:var(--done)}
.mono{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:.82em}
.muted{color:var(--ink-mid)}.faint{color:var(--ink-faint)}
.disc{font-size:.76rem;color:var(--ink-faint);border-top:1px solid var(--line);margin-top:22px;padding-top:10px}
.filter{width:100%;padding:8px 11px;border:1px solid var(--line);border-radius:8px;background:var(--surface);color:var(--ink);margin:8px 0 4px}
.proj{border:2px dashed var(--gate);border-radius:var(--radius);padding:14px 16px;margin:12px 0}
.proj h3{margin:0 0 6px;color:var(--gate)}
.step{display:flex;gap:9px;align-items:baseline;padding:4px 0}
.box{display:inline-flex;width:16px;height:16px;border:1.5px solid var(--ink-faint);border-radius:4px;align-items:center;justify-content:center;font-size:.7rem;flex:none}
.box.done{background:var(--done-soft);border-color:var(--done);color:var(--done)}
.sec{margin-top:14px}
.menu-btn{display:none}
#scrim{display:none}
@media(max-width:760px){
 aside{position:fixed;left:0;top:0;z-index:40;transform:translateX(-100%);transition:transform .2s}
 body.nav-open aside{transform:none}
 body.nav-open #scrim{display:block;position:fixed;inset:0;background:rgba(0,0,0,.4);z-index:30}
 main{padding:16px 16px 60px}
 .menu-btn{display:inline-flex;position:sticky;top:8px;z-index:20;margin-bottom:8px;padding:7px 12px;border:1px solid var(--line);border-radius:8px;background:var(--surface);color:var(--ink);cursor:pointer}
 .kv{grid-template-columns:1fr}
}
"""

JS = r"""
const S=(()=>{try{const t=document.getElementById('state').textContent;
 if(!t||t.indexOf('__PM_DASHBOARD_STATE__')>-1)return{};return JSON.parse(t);}catch(e){return{};}})();
const E=s=>String(s==null?'':s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const LBL={done:['Resolved','done'],active:['Active','active'],pending:['Open','pending'],
 unblocked:['Unblocked','unblocked'],blocker:['Blocked','blocker'],
 deferred:['Deferred','neutral'],deprecated:['Deprecated','neutral'],cancelled:['Cancelled','neutral']};
const pill=st=>{const m=LBL[st]||[st,'pending'];return `<span class="pill ${m[1]}">${E(m[0])}</span>`;};
const dot=st=>`<span class="dot ${st}"></span>`;
const idHash=id=>'#'+id.toLowerCase();
const td=id=>S.tds&&S.tds[id]||{id:id,num:0,title:id,status:'pending',tier:'minimal'};
const has=v=>v!=null&&v!=='';
function bar(done,total){const p=total?Math.round(100*done/total):0;
 return `<div class="bar"><i style="width:${p}%"></i></div><span class="faint">${done} / ${total} &#183; ${p}%</span>`;}

/* ---------- sidebar ---------- */
function sidebar(){
 const g=[];
 g.push(`<div class="brand">&#9670; Project frontier<span class="v">v${E(S.version||'?')}${S.qualifier?' &#183; '+E(S.qualifier):''}</span></div>`);
 g.push(`<div class="navgroup"><h4>Frontier</h4>
  <a href="#landing" data-r="landing">Landing</a>
  <a href="#frontier" data-r="frontier">Frontier</a>
  <a href="#grand-plan" data-r="grand-plan">Grand plan</a></div>`);
 const mo=(S.motion||[]);const act=new Set(S.active||[]);
 g.push(`<div class="navgroup"><h4>Work items &#183; ${mo.length}</h4>`+
  mo.map(id=>{const r=td(id);const st=act.has(id)?'active':r.status;
   return `<a href="${idHash(id)}" data-r="${id.toLowerCase()}">${dot(st)}<span>${E(id)}</span>${act.has(id)?'<span class="chip here">here</span>':''}</a>`;}).join('')+`</div>`);
 g.push(`<div class="navgroup"><h4>Reference</h4>
  <a href="#archive" data-r="archive">Archive &#183; All TDs</a>
  <a href="#methodology" data-r="methodology">Methodology</a>
  <a href="#rules" data-r="rules">Project rules</a>
  <a href="#deps" data-r="deps">Dependencies</a>
  <a href="#changelog" data-r="changelog">Recently landed</a>
  <a href="#metrics" data-r="metrics">Metrics</a>
  <a href="#help" data-r="help">Help &amp; commands</a></div>`);
 return g.join('');
}

/* ---------- pages ---------- */
function pLanding(){
 const c=S.counts||{},m=S.metrics||{};
 return `<div class="eyebrow">Project frontier</div><h1>Landing</h1>
 <p class="lede">A live, at-a-glance mirror of project work &#8212; what is in motion, everything in play, and each backlog item's pipeline.</p>
 <div class="grid" style="margin-top:14px">
  <div class="tile"><div class="k">Version</div><div class="v">v${E(S.version||'?')}</div><div class="s">${E(S.qualifier||'')} &#183; ${E(S.date||'')}</div></div>
  <div class="tile"><div class="k">Open items</div><div class="v">${c.open||0}</div><div class="s">of ${c.total||0} total</div></div>
  <div class="tile"><div class="k">Resolved</div><div class="v">${m.resolved||0}</div><div class="s">${m.pct||0}% of total</div></div>
  <div class="tile"><div class="k">Boundary</div><div class="v mono">${E((S.boundary||'&#8212;'))}</div><div class="s">${S.boundaryFresh?'&#10003; fresh':'&#8634; behind'}</div></div>
 </div>
 <div class="grid" style="margin-top:6px">
  ${['frontier|Frontier|the running window + in-flight view','grand-plan|Grand plan|everything in play',
     'archive|Archive|the permanent TD index','methodology|Methodology|how work moves',
     'rules|Project rules|standing rules','help|Help &amp; commands|project commands',
     'metrics|Metrics|toward launch'].map(x=>{const[r,t,d]=x.split('|');
     return `<a class="tile" href="#${r}"><div class="v" style="font-size:1.05rem">${t}</div><div class="s">${d}</div></a>`;}).join('')}
 </div>
 <h2>Where we are now</h2>${sessionBand()}
 <div class="card"><strong>In flight now</strong>${
  (S.active||[]).length?(S.active||[]).map(id=>{const r=td(id);
   return `<div class="row"><div class="main"><a class="ttl" href="${idHash(id)}">${E(id)} &#8212; ${E(r.title)}</a> ${pill('active')} ${S.inflight&&S.inflight.dirty?'<span class="chip live">editing now</span>':'<span class="chip">idle</span>'}</div></div>`;}).join('')
   :'<div class="muted">No active items.</div>'}</div>
 <div class="card"><strong>Recently resolved</strong>${recentResolved(5)}</div>
 <div class="disc">Never a source of truth; snapshot at boundary ${E(S.boundary||'&#8212;')}; republished on change.</div>`;
}

function sessionBand(){
 const p=S.parallelization||{};
 const agents=S.agentsRunning||[];
 return `<div class="card">
  <div class="kv">
   <div class="k">Active TDs</div><div>${(S.active||[]).length?(S.active||[]).map(id=>`<a href="${idHash(id)}">${E(id)}</a>`).join(', ')+' '+pill('active'):'<span class="muted">none</span>'}</div>
   <div class="k">Running agents</div><div>${agents.length?agents.map(a=>`<span class="chip">${E(a.role)}</span> ${E(a.name)}`).join('<br>'):'No agents running.'}</div>
   <div class="k">Cycle position</div><div>${has(S.cyclePosition)?E(S.cyclePosition):'<span class="muted">&#8212;</span>'}</div>
   <div class="k">Parallelization</div><div><strong>${E(p.mode||'idle')}</strong>${p.note?' &#8212; '+E(p.note):''}</div>
   <div class="k">Wave</div><div>${has(S.wave)?E(S.wave):'<span class="muted">&#8212;</span>'}</div>
   <div class="k">Boundary commit</div><div><span class="mono">${E(S.boundary||'&#8212;')}</span> ${S.boundaryFresh?'<span class="chip fresh">&#10003; fresh</span>':'<span class="chip behind">&#8634; behind</span>'}</div>
  </div></div>`;
}

function pFrontier(){
 const inf=S.inflight||{};const mo=S.motion||[];const act=new Set(S.active||[]);
 let h=`<div class="eyebrow">In motion &#183; ${mo.length}</div><h1>Frontier ${inf.dirty?'<span class="chip live">editing now</span>':''}</h1>
 <p class="lede">The merged running-window + in-flight view.</p>
 <h2>Live session-state band</h2>${sessionBand()}
 <h2>Running window</h2><div class="card">`;
 h+=mo.length?mo.map((id,i)=>{const r=td(id);const st=act.has(id)?'active':r.status;
   return `<div class="row"><div class="idx">${i+1}</div><div class="main">
    <a class="ttl" href="${idHash(id)}">${E(id)} &#8212; ${E(r.title)}</a> ${act.has(id)?'<span class="chip here">you are here</span>':''} ${inf.dirty&&act.has(id)?'<span class="chip live">in progress</span>':''}
    <div class="note">${E((r.type||'').slice(0,90))}</div></div><div>${pill(st)}</div></div>`;}).join(''):'<div class="muted">Window empty.</div>';
 h+='</div>';
 const wt=inf.worktrees||{};
 h+=`<h2>In-flight worktrees</h2><div class="card"><div class="kv">
  <div class="k">Linked worktrees</div><div>${wt.all||0} total &#183; ${(wt.scoped||[]).length} in-scope</div>
  <div class="k">Main tree</div><div>${inf.dirty?'<span class="chip live">dirty &#183; '+(inf.files||[]).length+' files</span>':'clean'}</div></div>`;
 h+=(wt.scoped||[]).map(w=>`<div class="row"><div class="main"><span class="mono">${E(w.branch||'')}</span></div><div>${pill('active')}</div></div>`).join('')||'<div class="muted" style="margin-top:6px">No in-scope linked worktrees.</div>';
 h+='</div>';
 const ag=S.agentsRunning||[];
 h+=`<h2>Running agents</h2><div class="card">${ag.length?ag.map(a=>`<div class="row"><div class="main"><span class="chip">${E(a.role)}</span> <span class="mono">${E(a.name)}</span></div></div>`).join(''):'<div class="muted">No agents running.</div>'}</div>`;
 h+=`<h2>Decisions &amp; directives</h2><div class="card">${(S.pendingDecisions||[]).length?(S.pendingDecisions||[]).map(d=>`<div class="row"><div class="main">${E(d)}</div></div>`).join(''):'<div class="muted">None on record.</div>'}</div>`;
 h+=`<div class="disc">Mirrors docs/project/pm-session-state.json.</div>`;
 return h;
}

function pGrand(){
 const p=S.parallelization||{};const plans=S.plans||{};const mo=S.motion||[];
 const planned=mo.filter(id=>plans[id]);const awaiting=mo.filter(id=>!plans[id]);
 let h=`<div class="eyebrow">Everything in play &#183; ${E(p.mode||'idle')}</div><h1>Grand plan</h1>
 <div class="card"><strong>Sequencing:</strong> <strong>${E(p.mode||'idle')}</strong>${p.note?' &#8212; '+E(p.note):''}</div>
 <h2>Planned &#183; ${planned.length}</h2>`;
 h+=planned.map(id=>{const r=td(id),pl=plans[id];const pr=pl.progress||{};
  return `<div class="card"><a class="ttl" href="${idHash(id)}">${E(id)} &#8212; ${E(r.title)}</a> ${pill(S.active.includes(id)?'active':r.status)} <span class="chip">${E(pl.sizeTier||'')}</span>
   ${bar(pr.done||0,pr.total||0)}
   <div class="sec">${(pl.evidence||[]).slice(0,8).map(ev=>`<div class="step"><span class="box done">&#10003;</span><span><span class="mono chip">${E(ev.sha)}</span> ${E(ev.subject)}</span></div>`).join('')}</div></div>`;}).join('')||'<div class="muted">No planned cards.</div>';
 h+=`<h2>Awaiting planning &#183; ${awaiting.length}</h2><div class="card">${awaiting.map(id=>{const r=td(id);return `<div class="row"><div class="main"><a href="${idHash(id)}">${E(id)} &#8212; ${E(r.title)}</a></div><div>${pill(S.active.includes(id)?'active':r.status)}</div></div>`;}).join('')||'<div class="muted">None.</div>'}</div>
 <div class="disc">Reflects the snapshot; the full index lives on the Archive.</div>`;
 return h;
}

const GROUPS=[['active','Active'],['pending','Open'],['unblocked','Unblocked'],['deferred','Deferred'],['done','Resolved'],['deprecated','Deprecated'],['cancelled','Cancelled']];
function pArchive(){
 const all=Object.values(S.tds||{});
 let h=`<div class="eyebrow">Permanent index &#183; ${all.length} items</div><h1>Archive &#183; All TDs</h1>
 <div class="card"><strong>Recently resolved</strong>${recentResolved(5)}</div>
 <input class="filter" id="flt" placeholder="Filter by id or title&#8230;" oninput="ARCH_FILTER(this.value)">
 <div id="arch">`;
 for(const[st,lab] of GROUPS){
  const rows=all.filter(r=>r.status===st).sort(
   st==='done'
    ? (a,b)=>(b.resolved_date||'').localeCompare(a.resolved_date||'')||b.num-a.num
    : (a,b)=>b.num-a.num);
  if(!rows.length)continue;
  h+=`<h2>${lab} &#183; ${rows.length}</h2><div class="card">`+rows.map(r=>
   `<div class="row af" data-f="${E((r.id+' '+r.title).toLowerCase())}"><div class="main">
    <a class="ttl" href="${idHash(r.id)}">${E(r.id)} &#8212; ${E(r.title)}</a> ${r.tier==='full'&&(S.plans||{})[r.id]?'<span class="chip">deep</span>':''} ${(S.active||[]).includes(r.id)?'<span class="chip here">here</span>':''}
    <div class="note">${E(r.snippet||'')}</div></div><div>${pill(r.status)}</div></div>`).join('')+`</div>`;
 }
 h+='</div>';return h;
}
window.ARCH_FILTER=v=>{v=(v||'').toLowerCase();document.querySelectorAll('#arch .af').forEach(el=>{el.style.display=el.dataset.f.indexOf(v)>-1?'':'none';});};

function recentResolved(n){
 const rs=Object.values(S.tds||{}).filter(r=>r.status==='done').sort((a,b)=>(b.resolved_date||'').localeCompare(a.resolved_date||'')||b.num-a.num).slice(0,n);
 return rs.length?rs.map(r=>`<div class="row"><div class="main"><a href="${idHash(r.id)}">${E(r.id)} &#8212; ${E(r.title)}</a></div><div>${pill('done')}</div></div>`).join(''):'<div class="muted">None.</div>';
}

function pTD(id){
 const r=td(id);const pl=(S.plans||{})[id];const isAct=(S.active||[]).includes(id);
 const st=isAct?'active':r.status;
 const dec=(S.pendingDecisions||[]).filter(d=>d.indexOf(id)>-1||d.indexOf(id.replace('TD-0','TD-'))>-1);
 let h=`<div class="eyebrow"><a href="#archive">Archive</a> &#8250; ${E(id)} &#183; ${LBL[st]?LBL[st][0]:st}</div><h1>${E(r.title)}</h1>`;
 if(r.type)h+=`<p class="lede">${E(r.type)}</p>`;
 if(pl){const pr=pl.progress||{};
  h+=`<div class="card"><div class="grid">
   <div class="tile"><div class="k">Status</div><div class="v" style="font-size:1rem">${pill(st)}</div></div>
   <div class="tile"><div class="k">Commits landed</div><div class="v">${(pl.evidence||[]).length}</div></div>
   <div class="tile"><div class="k">Size</div><div class="v" style="font-size:1rem">${E(pl.sizeTier||'')}</div></div>
  </div>${bar(pr.done||0,pr.total||0)}</div>
  <h2>Waves &amp; commits</h2><div class="card">${(pl.evidence||[]).map(ev=>`<div class="step"><span class="box done">&#10003;</span><span><span class="mono chip">${E(ev.sha)}</span> ${E(ev.subject)}</span></div>`).join('')||'<div class="muted">No landed commits yet.</div>'}</div>`;
 }else{
  h+=`<h2>Where we are</h2><div class="card"><div class="kv">
   <div class="k">Type</div><div>${E(r.type||'&#8212;')}</div>
   <div class="k">Target</div><div>${E(r.target||'&#8212;')}</div>
   <div class="k">Blockers</div><div>${E(r.blockers||'&#8212;')}</div>
   <div class="k">Unblocks</div><div>${E(r.unblocks||'&#8212;')}</div></div></div>`;
 }
 if(r.body)h+=`<h2>Detail</h2><div class="card">${E(r.body)}</div>`;
 else if(r.snippet)h+=`<div class="card">${E(r.snippet)}</div>`;
 h+=`<h2>Decisions on record</h2><div class="card">${dec.length?dec.map(d=>`<div class="row"><div class="main">${E(d)}</div></div>`).join(''):'<div class="muted">None touching this TD.</div>'}</div>`;
 return h;
}

function pMethodology(){
 let h=`<div class="eyebrow">How work moves</div><h1>Methodology</h1>
 <div class="card"><strong>Deterministic flow</strong><div class="muted">docs-researcher &#8594; architect &#8594; adversarial architect &#8594; reconciliation (if findings) &#8594; developer design review &#8594; planner &#8594; adversarial planner &#8594; reconciliation (if findings) &#8594; developer gate &#8594; parallel worktree coder waves.</div></div>
 <div class="card"><strong>Lightweight flow</strong><div class="muted">(optional researcher) &#8594; architect &#8594; planner &#8594; coder + bounded review/fix cycle.</div></div>
 <h2>Agent roster</h2><div class="card">`;
 h+=(S.agents||[]).map(a=>`<div class="row"><div class="main"><span class="mono">${E(a.name)}</span> ${a.cls==='RW'?'<span class="pill accent">RW</span>':'<span class="pill pending">RO</span>'}<div class="note">${E(a.role)}</div></div></div>`).join('')||'<div class="muted">No roster.</div>';
 h+='</div>';return h;
}

function pRules(){
 const rs=S.rules||[];const groups={};rs.forEach(r=>{(groups[r.group]=groups[r.group]||[]).push(r);});
 let h=`<div class="eyebrow">Standing rules &#183; ${rs.length}</div><h1>Project rules</h1><p class="lede">A live mirror of CLAUDE.md &#167; Project rules.</p>`;
 for(const g in groups){h+=`<h2>${E(g)}</h2>`+groups[g].map(r=>
  `<div class="card" id="rules-${E(r.anchor)}"><strong>${E(r.title)}</strong>${r.anchor?` <span class="chip">${E(r.anchor)}</span>`:''}<div class="muted" style="margin-top:5px">${E(r.body)}</div></div>`).join('');}
 return h;
}

function pDeps(){
 const act=new Set(S.active||[]);const edges=[];
 (Object.values(S.tds||{})).forEach(r=>{if(!r.blockers)return;const low=r.blockers.toLowerCase();
  if(/no blocker|none|n\/a/.test(low))return;
  const tos=(r.blockers.match(/TD-\d+/g)||[]).filter(t=>t!==r.id);
  if(tos.length)edges.push({from:r.id,num:r.num,to:[...new Set(tos)],why:r.blockers,st:act.has(r.id)?'active':r.status});});
 let h=`<div class="eyebrow">Sequencing</div><h1>Dependencies</h1><p class="lede">Best-effort from each TD's Blockers: prose.</p>`;
 if(!edges.length)return h+'<div class="card muted">No prerequisite edges parsed from Blockers prose.</div>';
 const SECTIONS=[['Open &amp; queued',['pending','unblocked','deferred','active']],
  ['Resolved',['done']],
  ['Deprecated &amp; superseded',['deprecated','cancelled']]];
 SECTIONS.forEach(sec=>{const label=sec[0],toks=sec[1];
  const rows=edges.filter(e=>toks.indexOf(e.st)>-1).sort((a,b)=>a.num-b.num||(a.from<b.from?-1:a.from>b.from?1:0));
  if(!rows.length)return;
  h+=`<h2>${label} &#183; ${rows.length}</h2>`;
  h+=rows.map(e=>`<div class="card"><a class="ttl" href="${idHash(e.from)}">${E(e.from)}</a> ${pill(e.st)} <span class="muted">waits on</span> ${e.to.map(t=>`<a href="${idHash(t)}">${E(t)}</a>`).join(', ')}<div class="note">${E(e.why.slice(0,200))}</div></div>`).join('');});
 return h;
}

function pChangelog(){
 let h=`<div class="eyebrow">Newest first</div><h1>Recently landed</h1>`;
 h+=(S.changelog||[]).map(c=>`<div class="card"><strong>${E(c.version)}</strong> <span class="chip">${E(c.date)}</span>
  <div class="sec">${(c.items||[]).map(it=>`<div class="step"><span class="box done">&#10003;</span><span>${E(it)}</span></div>`).join('')||'<div class="muted">&#8212;</div>'}</div></div>`).join('');
 return h;
}

function pMetrics(){
 const c=S.counts||{},m=S.metrics||{};
 return `<div class="eyebrow">Toward launch</div><h1>Metrics</h1>
 <div class="card"><strong>Resolution progress</strong>${bar(m.resolved||0,m.total||0)}
  <div class="kv" style="margin-top:8px"><div class="k">Open / unblocked</div><div>${(c.open||0)+(c.unblocked||0)}</div>
  <div class="k">Deferred</div><div>${c.deferred||0}</div>
  <div class="k">Running window</div><div>${(S.motion||[]).length}</div></div></div>
 <div class="card"><strong>Repo context</strong><div class="kv" style="margin-top:6px">
  <div class="k">Total items</div><div>${c.total||0}</div>
  <div class="k">Running window</div><div>${(S.motion||[]).length}</div>
  <div class="k">Branch</div><div class="mono">${E((S.repo&&S.repo.branch||'').replace(/^worktree-agent-.*/,'&#8212;'))}</div></div></div>`;
}

function pHelp(){
 const cmds=(S.help&&S.help.commands)||[];
 let h=`<div class="eyebrow">Project commands</div><h1>Help &amp; commands</h1>
 <div class="card"><strong>Project commands</strong><div class="sec">${cmds.map(c=>`<div class="step"><span class="box">&#183;</span><span class="mono">${E(c)}</span></div>`).join('')||'<div class="muted">&#8212;</div>'}</div></div>
 <div class="proj"><h3>Pack commands &#8212; separate surface</h3><div class="muted">Pack self-management commands are a separate surface from this project's own commands.</div></div>`;
 return h;
}

/* ---------- router ---------- */
function route(){
 const raw=(location.hash||'#landing').slice(1);
 const[seg,anchor]=raw.split('/');
 let html;
 if(/^td-\d+$/.test(seg)){html=pTD('TD-'+seg.split('-')[1].padStart(3,'0'));}
 else switch(seg){
  case'':case'landing':html=pLanding();break;
  case'frontier':html=pFrontier();break;
  case'grand-plan':html=pGrand();break;
  case'archive':html=pArchive();break;
  case'methodology':html=pMethodology();break;
  case'rules':html=pRules();break;
  case'deps':html=pDeps();break;
  case'changelog':html=pChangelog();break;
  case'metrics':html=pMetrics();break;
  case'help':html=pHelp();break;
  default:html=pLanding();
 }
 document.getElementById('main').innerHTML=html;
 document.querySelectorAll('.navgroup a').forEach(a=>a.classList.toggle('on',a.getAttribute('href')==='#'+seg));
 window.scrollTo(0,0);
 if(anchor){const el=document.getElementById(seg+'-'+anchor)||document.getElementById(anchor);if(el)el.scrollIntoView();}
 document.body.classList.remove('nav-open');
}
document.getElementById('side').innerHTML=sidebar();
window.addEventListener('hashchange',route);
route();
"""


def build_shell(sha):
    """Author the state-independent shell from the committed CSS/JS constants.

    The inert `<script id="state">__PM_DASHBOARD_STATE__</script>` placeholder
    is replaced (targeted, single-count) by the serialized state at inject time;
    the JS's own `indexOf('__PM_DASHBOARD_STATE__')` guard uses a DIFFERENT
    lexical context and MUST survive (gap 1). All static glyphs are numeric
    entities so the output is pure ASCII (gap 3).
    """
    prov = ("<!-- pm-dashboard shell &#183; spec: " + SPEC_REL_DEFAULT + " &#183; "
            "spec-sha: " + sha + " -->")
    return (
        "<!DOCTYPE html>\n" + prov + "\n"
        '<html lang="en"><head><meta charset="utf-8">'
        '<meta name="viewport" content="width=device-width, initial-scale=1">'
        "<title>Project frontier &#8212; dashboard</title>\n"
        "<style>" + CSS + "</style></head>\n"
        "<body>"
        '<button class="menu-btn" onclick="document.body.classList.toggle(\'nav-open\')">&#9776; Menu</button>'
        '<div id="scrim" onclick="document.body.classList.remove(\'nav-open\')"></div>'
        '<div class="app"><aside id="side"></aside>'
        '<main id="main"></main></div>\n'
        '<script type="application/json" id="state">' + STATE_SENTINEL + '</script>\n'
        "<script>" + JS + "</script>\n"
        "</body></html>\n"
    )


# ============================================================================
# Collection layer - parsers, all parameterized on `root` (never a global).
# Enumerated sets are drawn from git-tracked files (`git ls-files`), never a raw
# FS walk (bounded, git-tracked candidate set). Fail-closed on a broken
# git ls-files.
# ============================================================================
def normalize(t):
    return " ".join((t or "").lower().split())


def collapse_ws(t):
    return " ".join((t or "").split())


def git(root, *args):
    return subprocess.run(["git", "-C", str(root), *args],
                          capture_output=True, text=True)


def is_git_worktree(root):
    """True iff `root` is inside a git work tree (verify is SKIP-lenient off one)."""
    out = git(root, "rev-parse", "--is-inside-work-tree")
    return out.returncode == 0 and out.stdout.strip() == "true"


def _field_block(text, name):
    lines = text.splitlines()
    hdr = re.compile(r"^[A-Za-z][A-Za-z/ _-]*:")
    start = re.compile(r"^" + re.escape(name) + r":\s?(.*)$")
    out, cap = [], False
    for ln in lines:
        if not cap:
            m = start.match(ln)
            if m:
                cap = True
                if m.group(1):
                    out.append(m.group(1))
        else:
            if hdr.match(ln) and not ln.startswith((" ", "\t")):
                break
            out.append(ln)
    return "\n".join(out).strip()


def _first_line(t):
    t = (t or "").strip()
    return t.splitlines()[0].strip() if t else ""


def substantive_src(text):
    desc = _field_block(text, "Description")
    ctx = _field_block(text, "Context")
    primary = (desc + " " + ctx).strip()
    if len(normalize(primary)) >= BODY_MIN:
        return primary
    kept = []
    for ln in text.splitlines():
        if ln.startswith("<!--") or ln.startswith("**TD-"):
            continue
        if _META_FIELD_RE.match(ln):
            continue
        if ln[:1] in (" ", "\t"):
            continue
        if ln.strip():
            kept.append(ln.strip())
    return " ".join(kept).strip()


def tracked_td_files(root):
    out = git(root, "ls-files", "docs/project/backlog/")
    if out.returncode != 0:
        raise SystemExit("git ls-files docs/project/backlog/ failed (fail-closed)")
    return sorted(Path(root) / rel.strip() for rel in out.stdout.splitlines()
                  if re.match(r"^docs/project/backlog/TD-\d+\.md$", rel.strip()))


def parse_backlog(root):
    records, failures = {}, []
    for path in tracked_td_files(root):
        td_id = path.stem
        num = int(_TD_ID_RE.match(td_id).group(1))
        text = path.read_text(encoding="utf-8")
        sm = _STATUS_RE.search(text)
        if not sm:
            failures.append(td_id)
            continue
        status = sm.group(1)
        rm = _RESOLVED_RE.search(text)
        rdate = None
        if rm:
            dm = _DATE_RE.search(rm.group(1))
            rdate = dm.group(1) if dm else ""
        tm = _TITLE_RE.search(text)
        title = tm.group(1).strip() if tm else td_id
        src = substantive_src(text)
        cs = collapse_ws(src)
        snippet = cs[:min(160, max(1, len(cs) - 1))] if cs else ""
        records[td_id] = {
            "id": td_id, "num": num, "status": status,
            "token": STATUS_TOKEN.get(status, status.lower()),
            "resolved_date": rdate, "title": title,
            "type": _first_line(_field_block(text, "Type")),
            "target": _first_line(_field_block(text, "Target")),
            "blockers": _first_line(_field_block(text, "Blockers")),
            "unblocks": _first_line(_field_block(text, "Unblocks")),
            "src": src, "snippet": snippet,
        }
    return records, failures


def compute_e_full(records):
    non_terminal = {r["id"] for r in records.values() if r["status"] in NON_TERMINAL}
    resolved = [r for r in records.values() if r["status"] == "Resolved"]
    resolved.sort(key=lambda r: (r["resolved_date"] or "", r["num"]), reverse=True)
    newest = {r["id"] for r in resolved[:NEWEST_RESOLVED_N]}
    return non_terminal | newest


def git_landings_map(root, limit=4000):
    """ONE `git log` pass -> {TD-NNN: [{sha,subject}, ...]} for feat/fix landings.

    A single-subprocess scan (NOT a subprocess-per-TD) so the plans floor stays
    O(one subprocess) - cheap per invocation. Buckets every TD-id found in each
    feat/fix subject to normalized `TD-NNN` (>=3-digit) keys.
    """
    out = git(root, "log", "--oneline", "-n", str(limit), "--format=%h %s")
    landings = {}
    if out.returncode != 0:
        return landings
    for line in out.stdout.splitlines():
        parts = line.split(None, 1)
        if len(parts) != 2:
            continue
        sha, subject = parts
        low = subject.lower()
        if not (low.startswith("feat") or low.startswith("fix")):
            continue
        for num in set(re.findall(r"td-(\d+)", low)):
            td_id = "TD-%03d" % int(num)
            landings.setdefault(td_id, []).append({"sha": sha, "subject": subject})
    return landings


def _cw(t):
    return set(re.findall(r"[a-z0-9]{3,}", normalize(t)))


def source_anchored_ok(body, title, snippet, src):
    """HEURISTIC (N4) - a presence floor, NOT a semantic-depth guarantee.

    Accepts a body only if it is >=BODY_MIN normalized chars, is not a bare
    title/snippet echo, and shares a shingle or a >=JACCARD_MIN word overlap
    with the live TD source. Strictly better than no check; defeatable in
    principle (a crafted echo could pass), so named a heuristic.
    """
    nb = normalize(body)
    if len(nb) < BODY_MIN:
        return False
    if nb in (normalize(title), normalize(snippet)):
        return False
    nsrc = normalize(src)
    if any(nb[i:i + SHINGLE] in nsrc for i in range(0, max(0, len(nb) - SHINGLE) + 1)):
        return True
    wb, ws = _cw(body), _cw(src)
    return bool(wb and ws and len(wb & ws) / len(wb | ws) >= JACCARD_MIN)


def collect_version(root):
    readme_path = Path(root) / "README.md"
    if not readme_path.exists():
        return None, None, None
    readme = readme_path.read_text(encoding="utf-8")
    in_table = False
    for ln in readme.splitlines():
        if re.match(r"^\|\s*Version\s*\|\s*Date\b", ln):
            in_table = True
            continue
        if not in_table:
            continue
        if re.match(r"^\|\s*:?-+", ln):
            continue
        cells = [c.strip() for c in ln.strip().strip("|").split("|")]
        if len(cells) < 2:
            break
        vm = re.match(r"v(\d+\.\d+(?:\.\d+)?)\s*(?:\(([^)]+)\))?", cells[0])
        if not vm:
            break
        return vm.group(1), (vm.group(2) or None), (cells[1] or None)
    return None, None, None


def load_session(root):
    p = Path(root) / "docs/project/pm-session-state.json"
    if not p.exists():
        return {}
    return json.loads(p.read_text(encoding="utf-8"))


def derived_active(session, records):
    prose = " ".join(session.get("active", []) or [])
    result = set()
    for m in _TD_ID_RE.findall(prose):
        for cand in ("TD-" + m, "TD-%03d" % int(m)):
            if cand in records and records[cand]["status"] in NON_TERMINAL:
                result.add(cand)
    return result


def norm_id(tok):
    m = _TD_ID_RE.match(tok.strip())
    return "TD-%03d" % int(m.group(1)) if m else tok.strip()


def parse_parallelization(val):
    """Leading-token mode + remainder note - NEVER the raw blob as the mode.

    The regex uses `\\W*` (any non-word separators, incl. an em-dash) so the
    source stays pure ASCII while still splitting `serial - note` prose.
    """
    val = (val or "").strip()
    if not val:
        return {"mode": "idle", "note": ""}
    m = re.match(r"^([A-Za-z]+)\W*(.*)$", val, re.S)
    if m and m.group(1).lower() in {"serial", "parallel", "interleaved", "none", "idle"}:
        return {"mode": m.group(1).lower(), "note": collapse_ws(m.group(2))}
    return {"mode": "none", "note": collapse_ws(val)}


def parse_agents(in_flight):
    """Parse real spawn rows from in_flight_agents; sentinel 'none...' -> empty."""
    rows = []
    for entry in (in_flight or []):
        e = str(entry).strip()
        low = e.lower()
        if low.startswith(("none", "no agents", "n/a")) or "none live" in low:
            continue
        m = re.match(r"^([a-z0-9]+)-([a-z0-9]+)-([a-z0-9-]+)", e)
        if m:
            rows.append({"name": e.split()[0], "role": m.group(1)})
    return rows


def git_status_files(root):
    out = git(root, "status", "--porcelain")
    files = []
    for ln in out.stdout.splitlines():
        path = ln[3:].strip()
        # Exclude the render's own footprint so a fresh render never shows itself
        # as in-flight churn (O1).
        if path.startswith(APPROVALS_REL + "/"):
            continue
        files.append({"x": ln[:2].strip(), "path": path})
    return files


def worktrees(root, branch):
    out = git(root, "worktree", "list", "--porcelain")
    wts, cur = [], {}
    for ln in out.stdout.splitlines():
        if ln.startswith("worktree "):
            cur = {"path": ln.split(" ", 1)[1]}
        elif ln.startswith("branch "):
            cur["branch"] = ln.split("refs/heads/")[-1]
        elif ln == "":
            if cur:
                wts.append(cur)
                cur = {}
    if cur:
        wts.append(cur)
    root_name = Path(root).name
    scoped = [w for w in wts if w.get("branch") == branch
              and not w["path"].endswith(root_name)]
    return {"all": len(wts), "scoped": scoped}


def boundary_fresh(root, boundary):
    if not boundary:
        return None
    head = git(root, "rev-parse", "HEAD").stdout.strip()
    if not head:
        return None
    resolved = git(root, "rev-parse", boundary).stdout.strip()
    if resolved.startswith(head[:7]) or boundary == head[:7]:
        return True
    anc = git(root, "merge-base", "--is-ancestor", boundary, "HEAD").returncode == 0
    if not anc:
        return False
    cnt = git(root, "rev-list", "--count", boundary + "..HEAD").stdout.strip()
    return anc and cnt.isdigit() and int(cnt) <= 2


def _section_bounds(lines, header):
    start = end = None
    for i, ln in enumerate(lines):
        if ln.startswith(header) and start is None:
            start = i
        elif start is not None and ln.startswith("## ") and i > start and not ln.startswith(header):
            end = i
            break
    return start, (end if end is not None else len(lines))


def parse_rules(root):
    """POPULATED rule objects (title + anchor + group + body) from
    CLAUDE.md section '## Project rules' - NEVER index stubs (B4)."""
    p = Path(root) / "CLAUDE.md"
    if not p.exists():
        return []
    lines = p.read_text(encoding="utf-8").splitlines()
    s, e = _section_bounds(lines, "## Project rules")
    if s is None:
        return []
    rules, group = [], "General"
    i = s + 1
    while i < e:
        ln = lines[i]
        if ln.startswith("### "):
            group = ln[4:].strip()
            i += 1
            continue
        if ln.startswith("- **"):
            block = [ln]
            i += 1
            while i < e and not lines[i].startswith("- **") and not lines[i].startswith("### "):
                block.append(lines[i])
                i += 1
            text = "\n".join(block)
            tm = re.match(r"^- \*\*(.+?)\*\*", text, re.S)
            title = collapse_ws(tm.group(1)) if tm else "(rule)"
            rm = re.search(r"\[rationale:\s*([a-z0-9-]+)\]", text)
            anchor = rm.group(1) if rm else re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")[:48]
            body = collapse_ws(re.sub(r"^- \*\*.+?\*\*", "", text, flags=re.S))
            body = re.sub(r"\[roles:[^\]]*\]|\[rationale:[^\]]*\]", "", body).strip()
            rules.append({"title": title, "anchor": anchor, "group": group,
                          "body": body[:600]})
            continue
        i += 1
    return rules


# The client changelog tree is one file per event, named `YYYY-MM-DD-<slug>.md`
# (date-first for lexical sort), each opening with an H3 heading
# `### YYYY-MM-DD - <kind> - <title>` and carrying a narrative (`**Summary**:`
# or `**Scope**:`) plus optional `**Files ...**:` / bullet lines. One panel per
# entry, newest first (date-descending filename order).
_CL_HEAD_RE = re.compile(r"^###\s+(20\d\d-\d\d-\d\d)\s+[-\u2014]\s+(.+)$")
_CL_FIELD_RE = re.compile(r"^\*\*([A-Za-z][A-Za-z ()0-9/]*?)\*\*\s*:\s*(.*)$")


def parse_changelog(root):
    cldir = Path(root) / "docs/project/changelog"
    panels = []
    if not cldir.exists():
        return panels
    files = sorted((p for p in cldir.glob("*.md") if not p.name.startswith("_")),
                   key=lambda p: p.name, reverse=True)
    for p in files:
        lines = p.read_text(encoding="utf-8").splitlines()
        title, date = p.stem, ""
        for ln in lines:
            m = _CL_HEAD_RE.match(ln)
            if m:
                date, title = m.group(1), collapse_ws(m.group(2))
                break
        items = []
        for ln in lines:
            if ln.startswith((">", "###", "<!--")):
                continue
            s = ln.strip()
            if not s:
                continue
            fm = _CL_FIELD_RE.match(s)
            if fm and fm.group(2):
                items.append(collapse_ws(fm.group(1) + ": " + fm.group(2))[:220])
            elif s.startswith("- "):
                items.append(collapse_ws(s[2:])[:220])
            elif items and (ln.startswith(("  ", "\t"))):
                items[-1] = (items[-1] + " " + collapse_ws(s))[:320]
        panels.append({"version": title, "date": date, "items": items[:60]})
    return panels


def parse_agents_roster(root):
    """Roster rows from the client PM-CHAT.md profile-assignment table
    (`| `<agent>` | <profile> |`): profile 'Write-capable ...' -> RW, else RO;
    the profile text is the role. Presence-driven: empty when no table exists."""
    p = Path(root) / "docs/pack/PM-CHAT.md"
    if not p.exists():
        return []
    text = p.read_text(encoding="utf-8")
    rows = []
    for m in re.finditer(r"^\|\s*`([a-z][\w-]*)`\s*\|\s*"
                         r"(Read-only|Write-capable[^|]*?)\s*\|", text, re.M):
        profile = collapse_ws(m.group(2))
        cls = "RW" if profile.lower().startswith("write-capable") else "RO"
        rows.append({"name": m.group(1), "cls": cls, "role": profile[:180]})
    return rows


def parse_help(root):
    """POPULATED help commands from docs/pack/HELP-FRAGMENT.md verb tables.

    Extracts the leading code-span of every markdown table row (the verb/script
    column). Returns {'commands': [...]}; empty when no help source exists (B8
    is presence-conditional: assert populated ONLY when a source is present).
    """
    p = Path(root) / "docs/pack/HELP-FRAGMENT.md"
    if not p.exists():
        return {"commands": []}
    text = p.read_text(encoding="utf-8")
    cmds = []
    for m in re.finditer(r"^\|\s*`([^`]+)`\s*\|", text, re.M):
        tok = m.group(1).strip()
        if tok and tok not in cmds:
            cmds.append(tok)
    return {"commands": cmds[:80]}


def help_source_present(root):
    return (Path(root) / "docs/pack/HELP-FRAGMENT.md").exists()


def status_vocab(root):
    """The legal Status vocabulary - parsed from docs/project/backlog/_rules.md
    when present, else the STATUS_VOCAB fallback constant."""
    p = Path(root) / "docs/project/backlog/_rules.md"
    if not p.exists():
        return set(STATUS_VOCAB)
    vocab = set()
    for m in re.finditer(r"^- `(\w+)`\s+[-\u2014]", p.read_text(encoding="utf-8"), re.M):
        vocab.add(m.group(1))
    return vocab or set(STATUS_VOCAB)


# ============================================================================
# Assembler - the COMPLETE #state (session layer + every backed section + a
# live git read). Independent of any prior render (re-reads disk).
# ============================================================================
def assemble_state(root, spec_rel):
    records, failures = parse_backlog(root)
    if failures:
        raise SystemExit("FAIL parse-coverage (unparseable Status): " + ", ".join(failures))
    session = load_session(root)
    e_full = compute_e_full(records)
    da = derived_active(session, records)
    e_full |= da  # derived-active are non-terminal already; be explicit

    # Counts by backlog Status TOKEN (O11: status-based; the derived-active
    # overlay is presentation and NEVER a count bucket - gap 2).
    tok = {}
    for r in records.values():
        tok[r["token"]] = tok.get(r["token"], 0) + 1
    counts = {
        "open": tok.get("pending", 0), "unblocked": tok.get("unblocked", 0),
        "deferred": tok.get("deferred", 0), "resolved": tok.get("done", 0),
        "deprecated": tok.get("deprecated", 0), "cancelled": tok.get("cancelled", 0),
        "total": len(records),
    }

    tds = {}
    for td_id, r in records.items():
        tier = "full" if td_id in e_full else "minimal"
        rec = {"id": r["id"], "num": r["num"], "title": r["title"],
               "status": "active" if td_id in da else r["token"],
               "backlogStatus": r["token"], "tier": tier, "snippet": r["snippet"],
               "type": r["type"], "target": r["target"],
               "blockers": r["blockers"], "unblocks": r["unblocks"]}
        if tier == "full":
            rec["body"] = collapse_ws(r["src"])[:600]
        # Emit the (already-parsed) resolution date on Resolved records ONLY, on
        # BOTH tiers - the Archive Resolved group spans every resolved TD. It is
        # the sort key the recentResolved + pArchive Resolved-group comparators
        # read for recency ordering (spec 7.1 Landing + 7.5 Archive). Normalize
        # None -> "" so the client sort key is always a string, mirroring the
        # server key `r["resolved_date"] or ""` used by compute_e_full.
        if r["status"] == "Resolved":
            rec["resolved_date"] = r["resolved_date"] or ""
        tds[td_id] = rec

    # plans{} - committed-history floor: every derived-active / newest-10 TD
    # with real git-log feat/fix landings gets a card (B3).
    resolved = [r for r in records.values() if r["status"] == "Resolved"]
    resolved.sort(key=lambda r: (r["resolved_date"] or "", r["num"]), reverse=True)
    newest = {r["id"] for r in resolved[:NEWEST_RESOLVED_N]}
    landings = git_landings_map(root)
    plans = {}
    for td_id in sorted(da | newest):
        shas = landings.get(td_id, [])
        if shas:
            plans[td_id] = {"sizeTier": "large" if len(shas) > 6 else "small",
                            "progress": {"done": len(shas), "total": len(shas)},
                            "evidence": shas}

    version, qualifier, date = collect_version(root)
    branch = git(root, "rev-parse", "--abbrev-ref", "HEAD").stdout.strip()

    active_ids = sorted(da, key=lambda x: int(_TD_ID_RE.match(x).group(1)))
    queue = [norm_id(q) for q in session.get("queue", [])]
    motion = active_ids + [q for q in queue if q not in active_ids]
    boundary = session.get("boundary_commit")
    wave = session.get("wave")
    if isinstance(wave, str):
        wave = collapse_ws(wave)

    state = {
        "version": version, "qualifier": qualifier, "date": date,
        "counts": counts,
        "metrics": {"resolved": counts["resolved"], "total": counts["total"],
                    "pct": round(100 * counts["resolved"] / counts["total"]) if counts["total"] else 0},
        "boundary": boundary, "boundaryFresh": boundary_fresh(root, boundary),
        "active": active_ids, "activeNotes": session.get("active", []),
        "motion": motion, "queue": queue,
        "parallelization": parse_parallelization(session.get("parallelization")),
        "wave": wave, "cyclePosition": session.get("cycle_position"),
        "inFlightAgentsRaw": session.get("in_flight_agents", []),
        "agentsRunning": parse_agents(session.get("in_flight_agents", [])),
        "pendingDecisions": session.get("pending_decisions", []),
        "inflight": {"files": git_status_files(root), "worktrees": worktrees(root, branch)},
        "tds": tds, "plans": plans,
        "rules": parse_rules(root), "changelog": parse_changelog(root),
        "agents": parse_agents_roster(root), "help": parse_help(root),
        "repo": {"branch": branch},
    }
    state["inflight"]["dirty"] = len(state["inflight"]["files"]) > 0
    aux = {"records": records, "e_full": e_full, "da": da, "newest": newest,
           "landings": landings, "vocab": status_vocab(root),
           "help_present": help_source_present(root)}
    return state, aux


def serialize(state):
    # ensure_ascii=True => every non-ASCII char becomes a JSON \uXXXX escape
    # (charset-independent: JSON.parse decodes it regardless of how the page
    # bytes are decoded - gap 3). The trailing `<` -> `<` replace means a
    # `</script` in ANY value cannot close the state <script> element early
    # (gap 1). Output is therefore pure ASCII.
    return json.dumps(state, sort_keys=True, ensure_ascii=True,
                      separators=(",", ":")).replace("<", "\\u003c")


def spec_sha(root, spec_rel):
    out = git(root, "hash-object", spec_rel)
    return out.stdout.strip()


def inject_state(shell, state_txt):
    """Replace ONLY the state element's placeholder (targeted, single-count).

    A GLOBAL token replace would also clobber the JS boot-guard's own
    `indexOf('__PM_DASHBOARD_STATE__')` literal -> SyntaxError -> blank board.
    The single-count assertion + the surviving-sentinel assertion enforce gap 1.
    """
    n = shell.count(STATE_PLACEHOLDER)
    if n != 1:
        raise SystemExit("state placeholder count=%d (expected 1)" % n)
    html = shell.replace(STATE_PLACEHOLDER, ">" + state_txt + "</script>")
    if STATE_SENTINEL not in html:
        raise SystemExit("JS sentinel literal must survive injection (gap 1)")
    return html


# ============================================================================
# build - atomic (temp -> inline verify -> rename-on-PASS / delete-on-FAIL).
# A failed build leaves NO hollow board on disk (S2).
# ============================================================================
def do_build(root, spec_rel):
    state, _aux = assemble_state(root, spec_rel)
    sha = spec_sha(root, spec_rel)
    fresh_shell = build_shell(sha)
    approvals = Path(root) / APPROVALS_REL
    approvals.mkdir(parents=True, exist_ok=True)
    shell_path = approvals / SHELL_NAME
    reuse_shell = shell_path.exists() and shell_path.read_text(encoding="utf-8") == fresh_shell

    state_txt = serialize(state)
    html = inject_state(fresh_shell, state_txt)

    # Render into a temp file in the target dir, verify THAT artifact, and only
    # rename it into place on PASS.
    fd, tmp = tempfile.mkstemp(dir=str(approvals), prefix=".dashboard-", suffix=".tmp")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            fh.write(html)
        shortfalls = verify_floor(root, spec_rel, html_path=Path(tmp))
        if shortfalls:
            os.remove(tmp)
            sys.stderr.write("BUILD ABORTED - verify floor failed; no board written:\n")
            for s in shortfalls:
                sys.stderr.write("  - " + s + "\n")
            return 1
        os.replace(tmp, str(approvals / DASHBOARD_NAME))
    except BaseException:
        if os.path.exists(tmp):
            os.remove(tmp)
        raise

    # Shell is written/reused ONLY after the board passes (no partial artifact on
    # a failed build). Reuse a byte-identical existing shell (git-stable).
    if not reuse_shell:
        shell_path.write_text(fresh_shell, encoding="utf-8")

    print("RENDER OK")
    print("  spec-sha           : " + sha)
    print("  TDs total          : %d" % state["counts"]["total"])
    n_full = sum(1 for r in state["tds"].values() if r["tier"] == "full")
    print("  tier:full (E_full) : %d" % n_full)
    print("  active             : %s" % state["active"])
    print("  motion window      : %s" % state["motion"])
    print("  queue              : %s" % state["queue"])
    print("  rules / changelog  : %d / %d panels" % (len(state["rules"]), len(state["changelog"])))
    print("  agents / help cmds : %d / %d" % (len(state["agents"]), len(state["help"]["commands"])))
    print("  plans records      : %d" % len(state["plans"]))
    print("  shell              : %s" % ("reused" if reuse_shell else "regenerated"))
    print("  dashboard.html     : %d bytes" % (approvals / DASHBOARD_NAME).stat().st_size)
    return 0


# ============================================================================
# verify - THE COMPLETE DATA FLOOR. Re-derive the expected board INDEPENDENTLY
# from the live tree (re-reading disk, not trusting build's in-memory objects),
# parse the produced dashboard.html #state, assert Group A / B / C + the
# render-token smoke. Returns a list of shortfall strings ([] == PASS).
# ============================================================================
_STATE_EL_RE = re.compile(
    r'<script type="application/json" id="state">(.*?)</script>', re.S)


def extract_produced_state(html):
    m = _STATE_EL_RE.search(html)
    if not m:
        return None
    # The state text has every `<` escaped to `<`; json.loads decodes that
    # escape natively, so no pre-substitution is needed. Fail-closed on a
    # malformed body: a broken-escaping regression leaves an unescaped
    # `</script>` in the body, and the non-greedy _STATE_EL_RE then truncates
    # group(1) mid-JSON. Catch the parse error and return None so BOTH `verify`
    # and `build`'s inline verify surface the clean "state element JSON not
    # parseable" shortfall (plus the C1 breakout shortfall) instead of an
    # uncaught traceback (SHOULD-2a).
    try:
        return json.loads(m.group(1))
    except (json.JSONDecodeError, ValueError):
        return None


def _nonascii_count(text):
    return sum(1 for ch in text if not (ch == "\t" or ch == "\n" or ch == "\r"
                                        or 0x20 <= ord(ch) <= 0x7E))


def verify_floor(root, spec_rel, html_path=None):
    errs = []
    if not is_git_worktree(root):
        # SKIP-lenient off a git work tree (fresh clone / not a repo).
        return errs
    if html_path is None:
        html_path = Path(root) / APPROVALS_REL / DASHBOARD_NAME
    if not Path(html_path).exists():
        return ["no produced dashboard.html to verify at " + str(html_path)]
    raw = Path(html_path).read_text(encoding="utf-8")

    # --- Group C gap 3: the produced dashboard.html MUST be pure ASCII (T-C3) ---
    na = _nonascii_count(raw)
    if na:
        errs.append("C3 ASCII-safe: dashboard.html carries %d non-ASCII byte(s)" % na)

    # --- Group C gap 1: injection sentinel survival + no </script breakout (T-C1) ---
    sentinel_total = raw.count(STATE_SENTINEL)
    if sentinel_total != 1:
        errs.append("C1 injection: sentinel '%s' count=%d in dashboard.html "
                    "(expected exactly 1, surviving in the JS guard)"
                    % (STATE_SENTINEL, sentinel_total))
    m_state = _STATE_EL_RE.search(raw)
    if m_state is None:
        errs.append("C1 injection: no state <script> element found")
    else:
        state_body = m_state.group(1)
        if STATE_SENTINEL in state_body:
            errs.append("C1 injection: un-injected sentinel remains inside the state element")
        # Catches the `</scriptX` (no immediate `>`) variant, which the
        # non-greedy _STATE_EL_RE does NOT consume as the close so it survives
        # in group(1). The exact `</script>` breakout is caught by the raw-span
        # scan below (SHOULD-2b), which does not depend on group(1).
        if "</script" in state_body.lower():
            errs.append("C1 injection: raw '</script' inside the state element (breakout risk; "
                        "'<' must be escaped to \\u003c)")

    # SHOULD-2b: the exact `</script>` breakout truncates the non-greedy
    # _STATE_EL_RE at the FIRST `</script>`, so the injected close never reaches
    # state_body above and the designed gap-1 assertion would silently miss it.
    # Scan the RAW span from the state element's opening tag to the JS block
    # opener directly: a well-formed board has EXACTLY ONE `</script` there (the
    # legitimate state close); >1 means `<` was not escaped to < and a
    # body `</script>` closed the element early (breakout). This fires cleanly
    # on a broken-escaping regression rather than relying on a downstream crash.
    open_tag = '<script type="application/json" id="state">'
    oi = raw.find(open_tag)
    if oi != -1:
        after = raw[oi + len(open_tag):]
        js_open = after.find("\n<script>")
        span = after if js_open == -1 else after[:js_open]
        n_close = span.lower().count("</script")
        if n_close != 1:
            errs.append("C1 injection: state element span has %d '</script' "
                        "(expected exactly 1 legitimate close; a body-embedded "
                        "'</script>' means '<' was not escaped to \\u003c - breakout)"
                        % n_close)

    produced = extract_produced_state(raw)
    if produced is None:
        errs.append("state element JSON not parseable")
        return errs

    # --- independently re-derive the expected board from the live tree ---
    expected, aux = assemble_state(root, spec_rel)
    records, e_full = aux["records"], aux["e_full"]
    da, newest, landings, vocab = aux["da"], aux["newest"], aux["landings"], aux["vocab"]

    def g(d, k):
        return d.get(k) if isinstance(d, dict) else None

    # ================= Group A - the 9-field session layer =================
    # Presence-conditional: assert only when the source carries content, and
    # bite on absence-of-backing (declare-verify-backing).
    if expected.get("boundary"):  # A1
        if g(produced, "boundary") != expected["boundary"]:
            errs.append("A1 boundary: produced=%r expected=%r"
                        % (g(produced, "boundary"), expected["boundary"]))
    if expected.get("active"):  # A2 (OPTION-2's exact bug)
        if list(g(produced, "active") or []) != expected["active"]:
            errs.append("A2 active: produced=%r expected=%r (non-terminal ids from active prose)"
                        % (g(produced, "active"), expected["active"]))
    if expected.get("inFlightAgentsRaw") and expected.get("agentsRunning"):  # A3
        if list(g(produced, "inFlightAgentsRaw") or []) != expected["inFlightAgentsRaw"]:
            errs.append("A3 inFlightAgentsRaw: not carried verbatim")
        if not (g(produced, "agentsRunning") or []):
            errs.append("A3 agentsRunning: empty despite real in_flight_agents rows")
    if expected.get("queue"):  # A4
        if set(g(produced, "queue") or []) != set(expected["queue"]):
            errs.append("A4 queue: produced=%r expected=%r"
                        % (g(produced, "queue"), expected["queue"]))
    if expected.get("parallelization", {}).get("mode") not in (None, "idle"):  # A5
        pp = g(produced, "parallelization") or {}
        if pp != expected["parallelization"]:
            errs.append("A5 parallelization: produced=%r expected=%r"
                        % (pp, expected["parallelization"]))
        elif not re.match(r"^[a-z]+$", str(pp.get("mode", ""))):
            errs.append("A5 parallelization: mode %r is not a leading token (raw-blob-as-mode)"
                        % pp.get("mode"))
    if expected.get("wave"):  # A6
        if not g(produced, "wave"):
            errs.append("A6 wave: empty despite snapshot wave prose")
    if expected.get("cyclePosition"):  # A7
        if not g(produced, "cyclePosition"):
            errs.append("A7 cyclePosition: empty despite snapshot cycle_position")
    if expected.get("pendingDecisions"):  # A8
        if list(g(produced, "pendingDecisions") or []) != expected["pendingDecisions"]:
            errs.append("A8 pendingDecisions: produced != snapshot pending_decisions")
    # A9 motion = active ++ (queue - active)
    exp_motion = expected["active"] + [q for q in expected["queue"] if q not in expected["active"]]
    if list(g(produced, "motion") or []) != exp_motion:
        errs.append("A9 motion: produced=%r expected=%r" % (g(produced, "motion"), exp_motion))

    # ================= Group B - every backed section =================
    ptds = g(produced, "tds") or {}
    tracked = set(records.keys())
    if set(ptds.keys()) != tracked:  # B1 total-accountability
        dropped = tracked - set(ptds.keys())
        phantom = set(ptds.keys()) - tracked
        errs.append("B1 tds total-accountability: dropped=%s phantom=%s"
                    % (sorted(dropped)[:5], sorted(phantom)[:5]))
    for td_id, r in records.items():  # B1 status-vocab closure
        if r["status"] not in vocab:
            errs.append("B1 status-vocab: %s has off-vocab Status %r" % (td_id, r["status"]))
            break
    # B2 |E_full| tier:full with source-anchored bodies (heuristic)
    full_ids = {i for i, r in ptds.items() if isinstance(r, dict) and r.get("tier") == "full"}
    if full_ids != set(e_full):
        errs.append("B2 tier:full set != E_full (%d vs %d)" % (len(full_ids), len(e_full)))
    for i in sorted(full_ids & set(records.keys())):
        r = records[i]
        body = ptds[i].get("body", "")
        if not source_anchored_ok(body, r["title"], r["snippet"], r["src"]):
            errs.append("B2 %s: tier:full body not source-anchored (echo/hollow)" % i)
            break
    # B3 plans floor - every (da | newest) TD with real landings appears in plans
    pplans = g(produced, "plans") or {}
    for td_id in sorted(da | newest):
        if landings.get(td_id) and td_id not in pplans:
            errs.append("B3 plans floor: %s has git-log landings but no plans record" % td_id)
            break
    # B4 rules populated (title+anchor+body), count matches, NOT index stubs
    prules = g(produced, "rules") or []
    if len(prules) != len(expected["rules"]):
        errs.append("B4 rules: count produced=%d expected=%d" % (len(prules), len(expected["rules"])))
    elif expected["rules"] and not all(
            isinstance(r, dict) and r.get("title") and ("anchor" in r) and ("body" in r)
            for r in prules):
        errs.append("B4 rules: emitted as index stubs / missing title|anchor|body (not populated)")
    # B5 changelog panels match the re-derived set (round-trip). The client
    # changelog is one date-slug entry per file (no mandatory version panel), so
    # the floor asserts the produced panel set equals the independently re-derived
    # panel set - a dropped or mangled entry bites here.
    pcl = g(produced, "changelog") or []
    if len(pcl) != len(expected["changelog"]):
        errs.append("B5 changelog: panel count produced=%d expected=%d"
                    % (len(pcl), len(expected["changelog"])))
    elif [c.get("version") for c in pcl] != [c["version"] for c in expected["changelog"]]:
        errs.append("B5 changelog: panel set/order != re-derived set "
                    "(an entry dropped or mis-parsed)")
    # B6 agents == live roster
    pagents = g(produced, "agents") or []
    if len(pagents) != len(expected["agents"]):
        errs.append("B6 agents: count produced=%d expected roster=%d"
                    % (len(pagents), len(expected["agents"])))
    elif expected["agents"] and not all(
            isinstance(a, dict) and a.get("name") and a.get("cls") in ("RO", "RW") and a.get("role")
            for a in pagents):
        errs.append("B6 agents: a roster row missing name|cls(RO/RW)|role")
    # B7 metrics tally
    if g(produced, "metrics") != expected["metrics"]:
        errs.append("B7 metrics: produced=%r expected=%r"
                    % (g(produced, "metrics"), expected["metrics"]))
    # B8 help populated when a source exists
    if aux["help_present"]:
        phelp = g(produced, "help") or {}
        if not (phelp.get("commands")):
            errs.append("B8 help: empty commands despite a live HELP-FRAGMENT source")
    # B9 inflight STRUCTURE present (values NOT asserted - R4 best-effort)
    pinf = g(produced, "inflight")
    if not (isinstance(pinf, dict) and "files" in pinf and "worktrees" in pinf):
        errs.append("B9 inflight: block missing 'files'/'worktrees' keys (structure)")
    # B11 version/qualifier/date floor (SHOULD-1). These come from the README
    # version table (collect_version) and render on the sidebar brand + the
    # Landing "Version" tile; a README-format regression that breaks the parse
    # would silently render "v?" while verify passed. Presence-conditional
    # (declare-verify-backing): assert equality ONLY when the README table backs
    # a version, and bite on a mismatch - same reliably-backed-SSOT class as B7
    # metrics. (Numbered B11 to avoid colliding with the design's B10 carve-out
    # label below.)
    if expected.get("version"):
        for vk in ("version", "qualifier", "date"):
            if g(produced, vk) != expected.get(vk):
                errs.append("B11 %s: produced=%r expected=%r (README version-table backed)"
                            % (vk, g(produced, vk), expected.get(vk)))

    # B12 resolved_date on every Resolved record - feeds the recency ordering
    # (spec 7.1 Landing "Recently resolved" + 7.5 Archive Resolved group/spotlight).
    # Bites when the sort key is dropped or mis-emitted - the exact datum whose
    # absence buried a just-resolved TD deep in the Archive. Keys on the
    # re-derived `records` and the produced `ptds`; O(resolved count), dict
    # lookups only, no subprocess/tree walk (cheap per invocation);
    # break on the first shortfall (one representative, matching the B1/B2 style).
    for td_id, r in records.items():
        if r["status"] != "Resolved":
            continue
        got = (ptds.get(td_id) or {}).get("resolved_date")
        if got != (r["resolved_date"] or ""):
            errs.append("B12 %s: resolved_date produced=%r expected=%r "
                        "(recency sort key dropped/mismatched)"
                        % (td_id, got, r["resolved_date"] or ""))
            break

    # B10 Level-1-only carve-out (design SS3.2 B10), made EXPLICIT here (SHOULD-3)
    # so a future reader cannot mistake it for an accidental omission: `deps`,
    # `methodology`, and `rulings` are DELIBERATELY not floored at Level 2.
    # `deps`/`methodology` are JS render-time derivations from already-floored
    # upstream data (deps from each TD's Blockers prose via the B1 `tds` set;
    # the methodology roster from `agents` via B6), so a dedicated assertion
    # would be redundant. `rulings` is spec-optional and UNIMPLEMENTED in the
    # render layer (no `#state` key, no nav token - see NAV_ROUTE_TOKENS / EEB-R1),
    # so a hard Level-2 assertion would over-constrain an optional surface.

    # ================= Group C gap 2 - status-token counts (T-C2) =================
    pcounts = g(produced, "counts") or {}
    if pcounts != expected["counts"]:
        errs.append("C2 counts: produced=%r expected=%r (active overlay must not re-bucket)"
                    % (pcounts, expected["counts"]))
    else:
        bucket_sum = sum(pcounts.get(k, 0) for k in
                         ("open", "unblocked", "deferred", "resolved", "deprecated", "cancelled"))
        if bucket_sum != pcounts.get("total"):
            errs.append("C2 counts: status buckets sum %d != total %d (double-count?)"
                        % (bucket_sum, pcounts.get("total")))

    # ================= render-token smoke (M1) =================
    # String-presence only (NO JS engine): catches a WHOLESALE-dropped route /
    # render function (its token vanishes), NOT a subtly-broken-but-present one.
    for t in NAV_ROUTE_TOKENS:
        if ('data-r="' + t + '"') not in raw:
            errs.append("SMOKE: nav route token data-r=%r missing from produced shell" % t)
    for fn in RENDER_FN_TOKENS:
        if ("function " + fn) not in raw:
            errs.append("SMOKE: render function %r missing from produced shell" % fn)
    if "getElementById('state')" not in raw:
        errs.append("SMOKE: getElementById('state') boot missing")
    if "replace(/[&<>\"']/g" not in raw:
        errs.append("SMOKE: E= escape helper missing")
    # Resolved-comparator smoke (OI-4): the two resolved surfaces (recentResolved
    # + the pArchive Resolved group) MUST sort by resolved_date (date-desc then
    # num-desc), NOT pure num-desc. String-presence only (NO JS engine): catches
    # a WHOLESALE revert to num-sort (the exact regression this floor closes); it
    # CANNOT catch a subtle mis-key (present but wrong) - that stays diff-review
    # per the verify-boundary. Expect exactly 2 occurrences (one per resolved
    # comparator); < 2 means a surface reverted.
    resolved_cmp = "(b.resolved_date||'').localeCompare(a.resolved_date||'')"
    n_cmp = raw.count(resolved_cmp)
    if n_cmp < 2:
        errs.append("SMOKE: resolved comparator (date-desc localeCompare on "
                    "resolved_date) appears %d time(s) in the produced shell "
                    "(expected 2: recentResolved + pArchive Resolved group; a "
                    "surface reverted to pure num-sort?)" % n_cmp)

    return errs


def do_verify(root, spec_rel):
    errs = verify_floor(root, spec_rel)
    if errs:
        sys.stderr.write("VERIFY FAILED - %d floor shortfall(s):\n" % len(errs))
        for s in errs:
            sys.stderr.write("  - " + s + "\n")
        return 1
    print("VERIFY OK - complete DATA floor clean")
    return 0


# ============================================================================
def main(argv=None):
    ap = argparse.ArgumentParser(
        prog="pm-dashboard-render.py",
        description="Client project-frontier dashboard renderer (build/verify).")
    sub = ap.add_subparsers(dest="mode", required=True)
    default_root = None
    top = subprocess.run(["git", "rev-parse", "--show-toplevel"],
                         cwd=str(Path(__file__).resolve().parent),
                         capture_output=True, text=True)
    if top.returncode == 0 and top.stdout.strip():
        default_root = top.stdout.strip()
    for name in ("build", "verify"):
        sp = sub.add_parser(name)
        sp.add_argument("--repo-root", default=default_root,
                        help="target tree (default: the script's git toplevel)")
        sp.add_argument("--spec", default=SPEC_REL_DEFAULT,
                        help="spec path relative to --repo-root (for spec-sha provenance)")
    args = ap.parse_args(argv)
    if not args.repo_root:
        sys.stderr.write("--repo-root is required (no git toplevel could be derived)\n")
        return 2
    root = Path(args.repo_root).resolve()
    if args.mode == "build":
        return do_build(root, args.spec)
    return do_verify(root, args.spec)


if __name__ == "__main__":
    sys.exit(main())
