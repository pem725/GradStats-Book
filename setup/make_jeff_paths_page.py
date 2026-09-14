#!/usr/bin/env python3
"""Build SPSS-START-HERE.html - the page that asks Jeff where his files are.

    python3 setup/make_jeff_paths_page.py

WHY THIS EXISTS. The book's SPSS setup asked a reader to reason about relative
paths at two nested levels, and it cost Jeff most of a session even though he
followed the instructions. The error SPSS gives - "cannot access a file with the
given file specification" - names four possible causes and never the real one.

Telling him more carefully was not the fix. The fix is to stop asking. He pastes
the location of his folder once, and this page writes the exact line for every
dataset, absolute, with nothing left to work out. Two habits of Windows paths
are handled for him rather than explained: "Copy as path" wraps the result in
quotes, and Windows uses backslashes where SPSS wants forward slashes.

Writes into the shared Drive folder, beside the chapters he already opens.
Override with JEFF_SHARED_DIR.
"""

import html
import json
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHARED = os.environ.get(
    "JEFF_SHARED_DIR", os.path.expanduser("~/Google_SharedWithMe/Patrick & Jeff"))
OUT = os.path.join(SHARED, "SPSS-START-HERE.html")


def datasets():
    """Names and one-line recipes, straight from load_data.sps so they cannot drift."""
    txt = open(os.path.join(REPO, "setup", "load_data.sps"), encoding="utf-8").read()
    out = {}
    for m in re.finditer(r"^\*\s{3}([a-z0-9][a-z0-9-]+)\s{2,}(.+?)\s*$", txt, re.M):
        out[m.group(1)] = m.group(2)
    # Real (not simulated) data ships too, and carries no recipe line.
    for name, desc in [
        ("knox", "Ben Wright's Knox Cube Test - 35 children x 18 tapping items"),
        ("mod3data", "the real four-group course data (note: f3 codes groups 2-5)"),
        ("moddat2", "the real 10-item scale from the graduate GLM course"),
        ("gpa", "high-school and college GPAs"),
    ]:
        out.setdefault(name, desc)
    return dict(sorted(out.items()))


PAGE = """<meta charset="utf-8">
<title>SPSS: start here</title>
<style>
 :root{color-scheme:light dark}
 body{font:16px/1.55 -apple-system,Segoe UI,Roboto,sans-serif;max-width:56rem;
      margin:0 auto;padding:1.5rem 1.25rem 4rem}
 h1{font-size:1.6rem;margin:0 0 .25rem} h2{font-size:1.15rem;margin:2rem 0 .5rem}
 .sub{opacity:.75;margin:0 0 1.5rem}
 .step{border:1px solid #8883;border-radius:10px;padding:1rem 1.15rem;margin:1rem 0}
 .n{display:inline-block;min-width:1.6rem;height:1.6rem;line-height:1.6rem;
    text-align:center;border-radius:50%;background:#2563eb;color:#fff;
    font-weight:700;margin-right:.5rem}
 input[type=text]{width:100%;padding:.6rem .7rem;font:14px/1.4 ui-monospace,Menlo,Consolas,monospace;
    border:1px solid #8886;border-radius:7px;background:#8881}
 code,pre{font-family:ui-monospace,Menlo,Consolas,monospace}
 pre{background:#8881;border:1px solid #8883;border-radius:7px;padding:.7rem .8rem;
     overflow-x:auto;white-space:pre-wrap;word-break:break-all;margin:.4rem 0}
 button{font:inherit;padding:.4rem .8rem;border:1px solid #8886;border-radius:7px;
        background:#8881;cursor:pointer}
 button:hover{background:#8882}
 table{border-collapse:collapse;width:100%;margin-top:.6rem}
 td,th{border-bottom:1px solid #8883;padding:.4rem .5rem;text-align:left;
       vertical-align:top;font-size:.93rem}
 td:first-child{white-space:nowrap;font-family:ui-monospace,Menlo,Consolas,monospace}
 .ok{color:#15803d;font-weight:600} .warn{color:#b45309}
 .note{background:#2563eb14;border-left:3px solid #2563eb;padding:.7rem .9rem;
       border-radius:0 7px 7px 0;margin:1rem 0}
 @media(prefers-color-scheme:dark){.note{background:#2563eb26}}
</style>

<h1>SPSS: start here</h1>
<p class="sub">Tell it where your folder is, once. It writes every line you need.</p>

<div class="step">
<h2><span class="n">1</span>Copy the location of your data folder</h2>
<p>The folder holding the <code>.sav</code> files.</p>
<p><b>Windows:</b> hold <b>Shift</b>, right-click the folder, choose <b>Copy as path</b>.<br>
<b>Mac:</b> right-click the folder, hold <b>Option</b>, choose <b>Copy “…” as Pathname</b>.</p>
<p>Paste it here. Quotes and backslashes are fine &mdash; they get cleaned up.</p>
<input type="text" id="p" spellcheck="false"
       placeholder="C:\\Users\\jstuewig\\Dropbox\\Stats Book\\data">
<p id="status" style="margin:.6rem 0 0"></p>
</div>

<div class="step">
<h2><span class="n">2</span>Copy the line for the dataset you want</h2>
<p>Each chapter names its dataset in a note near the top. Click <b>Copy</b>, paste into
SPSS, run it. That is the whole thing &mdash; no working directory to set, nothing
relative, no macro.</p>
<table id="t"><thead><tr><th>Dataset</th><th>What it is</th><th></th></tr></thead>
<tbody></tbody></table>
</div>

<div class="note">
<b>If SPSS says it cannot access the file.</b> The path in step 1 is pointing
somewhere else. Open the folder, copy the path again, and make sure you copied the
folder that <i>contains</i> the <code>.sav</code> files rather than one above or
below it. Nothing else in these lines can be wrong &mdash; there is only one path in
each of them.
</div>

<script>
const DATA = __DATA__;
const box = document.getElementById('p'), st = document.getElementById('status');
const tb = document.querySelector('#t tbody');

// Windows "Copy as path" hands back a quoted string with backslashes. SPSS wants
// neither. Fixing it here is the difference between this working and Jeff being
// told, again, that his file specification is invalid.
function clean(s){
  s = s.trim().replace(/^["']|["']$/g, '').replace(/\\\\/g, '/').replace(/\\/+$/,'');
  return s;
}
function render(){
  const raw = box.value, p = clean(raw);
  if(!p){ st.textContent=''; }
  else if(raw !== p){ st.innerHTML = '<span class="ok">Cleaned up to:</span> <code>'+p+'</code>'; }
  else { st.innerHTML = '<span class="ok">Looks good.</span>'; }
  tb.innerHTML = '';
  for(const [name, desc] of DATA){
    const line = p ? "GET FILE='" + p + "/" + name + ".sav'." : '';
    const tr = document.createElement('tr');
    const c1 = document.createElement('td'); c1.textContent = name;
    const c2 = document.createElement('td'); c2.textContent = desc;
    const c3 = document.createElement('td');
    if(p){
      const b = document.createElement('button');
      b.textContent = 'Copy';
      b.onclick = () => { navigator.clipboard.writeText(line);
                          b.textContent='Copied'; setTimeout(()=>b.textContent='Copy',1200); };
      c3.appendChild(b);
      c3.appendChild(Object.assign(document.createElement('pre'),{textContent:line}));
    } else { c3.innerHTML = '<span class="warn">paste your folder above</span>'; }
    tr.append(c1,c2,c3); tb.appendChild(tr);
  }
}
box.addEventListener('input', render);
box.value = localStorage.getItem('jeffpath') || '';
box.addEventListener('input', () => localStorage.setItem('jeffpath', box.value));
render();
</script>
"""


def main():
    ds = datasets()
    if not os.path.isdir(SHARED):
        sys.exit(f"shared folder not found: {SHARED}")
    page = PAGE.replace("__DATA__", json.dumps([[k, v] for k, v in ds.items()]))
    with open(OUT, "w", encoding="utf-8") as fh:
        fh.write(page)
    print(f"  wrote {OUT}")
    print(f"  {len(ds)} datasets listed")


if __name__ == "__main__":
    main()
