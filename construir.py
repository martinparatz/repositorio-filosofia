#!/usr/bin/env python3
"""Genera el sitio estático a partir de catalogo.json y la carpeta fuentes/.

Uso:  python3 construir.py
Salida: carpeta sitio/  (es lo que se publica)

Para añadir un autor: copia sus HTML en fuentes/<slug-autor>/<slug-obra>.html,
añade su bloque en catalogo.json y vuelve a ejecutar este script.
"""
import html, json, re, shutil
from pathlib import Path

RAIZ = Path(__file__).resolve().parent
FUENTES = RAIZ / "fuentes"
SALIDA = RAIZ / "sitio"
e = html.escape

CSS = r""":root{
  --bg:#f6f2ea;--surface:#fffdf8;--ink:#1c1a18;--muted:#5e5850;--rule:#d9cfbf;
  --accent:#7a1f2b;--accent-soft:#f1e2df;
  --serif:'Cormorant Garamond',Georgia,serif;--text:'Source Serif 4',Georgia,serif;--sans:'Inter',system-ui,sans-serif;
}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]){
  --bg:#16140f;--surface:#1f1c17;--ink:#ece6da;--muted:#a59d90;--rule:#3a352d;--accent:#e08a8f;--accent-soft:#3a2224;}}
:root[data-theme="dark"]{--bg:#16140f;--surface:#1f1c17;--ink:#ece6da;--muted:#a59d90;--rule:#3a352d;--accent:#e08a8f;--accent-soft:#3a2224;}
*{box-sizing:border-box}
html{-webkit-text-size-adjust:100%}
body{margin:0;background:var(--bg);color:var(--ink);font:1.0625rem/1.6 var(--text)}
a{color:inherit}
.wrap{max-width:1080px;margin:0 auto;padding:0 16px}
header.top{border-bottom:1px solid var(--rule)}
header.top .wrap{display:flex;align-items:center;justify-content:space-between;gap:1rem;padding-block:.9rem}
.marca{font:600 1.15rem/1 var(--serif);letter-spacing:.02em;text-decoration:none}
.miga{font:500 .8rem/1 var(--sans);color:var(--muted);text-transform:uppercase;letter-spacing:.08em}
.miga a{text-decoration:none}.miga a:hover{color:var(--accent)}
.hero{padding:clamp(2.5rem,7vw,5rem) 0 2rem}
.kicker{font:600 .75rem/1 var(--sans);text-transform:uppercase;letter-spacing:.14em;color:var(--accent);margin:0 0 1rem}
h1{font:500 clamp(2.4rem,1.6rem + 4vw,4.4rem)/1.02 var(--serif);margin:0 0 1rem;letter-spacing:-.01em}
.lema{max-width:44rem;color:var(--muted);font-size:1.15rem;margin:0}
.buscar{margin:2rem 0 0;max-width:32rem}
.buscar input{width:100%;font:1rem var(--sans);padding:.8rem 1rem;border:1px solid var(--rule);background:var(--surface);color:var(--ink);border-radius:2px}
.buscar input:focus{outline:2px solid var(--accent);outline-offset:1px}
h2{font:500 1.9rem/1.1 var(--serif);margin:0}
.seccion{padding:2rem 0;border-top:1px solid var(--rule)}
.seccion-cab{display:flex;flex-wrap:wrap;align-items:baseline;gap:.4rem 1rem;margin-bottom:.4rem}
.fechas{font:500 .85rem var(--sans);color:var(--muted)}
.nota{color:var(--muted);margin:.2rem 0 1.4rem;font-style:italic}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(250px,1fr));border-top:1px solid var(--rule);border-left:1px solid var(--rule)}
.card{background:var(--surface);border-right:1px solid var(--rule);border-bottom:1px solid var(--rule);padding:1.3rem 1.3rem 1.5rem;text-decoration:none;display:flex;flex-direction:column;gap:.45rem;transition:background .15s}
.card:hover,.card:focus-visible{background:var(--accent-soft)}
.card .anio{font:600 .72rem/1 var(--sans);letter-spacing:.1em;text-transform:uppercase;color:var(--accent)}
.card h3{font:600 1.4rem/1.15 var(--serif);margin:0}
.card p{margin:0;color:var(--muted);font-size:.95rem;line-height:1.5}
.autor-card{display:grid;grid-template-columns:auto 1fr;gap:1.4rem;align-items:start;background:var(--surface);border:1px solid var(--rule);padding:1.6rem;text-decoration:none;transition:border-color .15s}
.autor-card:hover{border-color:var(--accent)}
.inicial{width:4.2rem;height:4.2rem;display:grid;place-items:center;font:500 2.4rem/1 var(--serif);color:var(--bg);background:var(--accent)}
.autor-card h3{font:500 1.9rem/1.05 var(--serif);margin:0 0 .3rem}
.autor-card .meta{font:500 .82rem var(--sans);color:var(--muted);margin:0 0 .6rem}
.autor-card p{margin:0;color:var(--muted)}
.autores{display:grid;gap:1rem}
.vacio{display:none;color:var(--muted);padding:1rem 0}
footer{border-top:1px solid var(--rule);margin-top:3rem;padding:1.6rem 0 2.4rem;color:var(--muted);font:.85rem/1.5 var(--sans)}
.tema{font:500 .8rem var(--sans);background:none;border:1px solid var(--rule);color:var(--ink);padding:.4rem .7rem;cursor:pointer;border-radius:2px}
[hidden]{display:none!important}
@media (max-width:520px){.miga{display:none}.autor-card{grid-template-columns:1fr}.inicial{width:3.2rem;height:3.2rem;font-size:1.8rem}}
"""

JS_TEMA = """<script>
(function(){var b=document.getElementById('tema');if(!b)return;var r=document.documentElement;
try{var t=localStorage.getItem('tema');if(t)r.dataset.theme=t;}catch(e){}
b.onclick=function(){var d=r.dataset.theme?r.dataset.theme==='dark':matchMedia('(prefers-color-scheme:dark)').matches;
r.dataset.theme=d?'light':'dark';try{localStorage.setItem('tema',r.dataset.theme);}catch(e){}};})();
</script>"""

JS_BUSCAR = """<script>
(function(){var i=document.getElementById('q');if(!i)return;
var norm=function(s){return s.normalize('NFD').replace(/[\\u0300-\\u036f]/g,'').toLowerCase();};
i.addEventListener('input',function(){var q=norm(i.value.trim()),n=0;
document.querySelectorAll('[data-buscar]').forEach(function(c){var ok=!q||norm(c.dataset.buscar).indexOf(q)>-1;c.hidden=!ok;if(ok)n++;});
document.querySelectorAll('.seccion[data-grupo]').forEach(function(s){s.hidden=!s.querySelector('[data-buscar]:not([hidden])');});
var v=document.getElementById('vacio');if(v)v.style.display=n?'none':'block';});})();
</script>"""

FUENTES_WEB = ('<link rel="preconnect" href="https://fonts.googleapis.com">'
               '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>'
               '<link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,400;0,500;0,600;1,400'
               '&family=Inter:wght@400;500;600&family=Source+Serif+4:ital,opsz,wght@0,8..60,400;1,8..60,400&display=swap" rel="stylesheet">')


def pagina(titulo, descripcion, raiz, miga, cuerpo, pie):
    return f"""<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{e(titulo)}</title>
<meta name="description" content="{e(descripcion)}">
{FUENTES_WEB}
<link rel="stylesheet" href="{raiz}estilo.css">
</head>
<body>
<header class="top"><div class="wrap">
<a class="marca" href="{raiz}index.html">{e(pie)}</a>
<div style="display:flex;gap:1rem;align-items:center"><span class="miga">{miga}</span><button class="tema" id="tema" type="button" aria-label="Cambiar entre tema claro y oscuro">Claro / Oscuro</button></div>
</div></header>
<main class="wrap">
{cuerpo}
</main>
<footer><div class="wrap">{e(pie)} · Guías elaboradas con NotebookLM a partir de las obras originales.</div></footer>
{JS_TEMA}
{JS_BUSCAR}
</body>
</html>
"""


def barra_volver(autor, sitio_titulo):
    # Barra flotante discreta que se inserta en cada guía para volver al micrositio.
    return (
        '<nav id="rf-volver" aria-label="Navegación del repositorio" style="position:fixed;left:16px;bottom:16px;z-index:2147483647;'
        'display:flex;gap:.5rem;font:500 13px/1 system-ui,-apple-system,sans-serif;">'
        f'<a href="index.html" style="background:#1c1a18;color:#f6f2ea;text-decoration:none;padding:9px 13px;border-radius:999px;'
        f'box-shadow:0 2px 10px rgba(0,0,0,.25)">← {e(autor["nombre"].split()[-1])}</a>'
        f'<a href="../index.html" style="background:#1c1a18;color:#f6f2ea;text-decoration:none;padding:9px 13px;border-radius:999px;'
        f'box-shadow:0 2px 10px rgba(0,0,0,.25)" title="{e(sitio_titulo)}">Inicio</a></nav>'
    )


def tarjeta_obra(o, href, autor=None):
    extra = f" · {autor}" if autor else ""
    buscar = f'{o["titulo"]} {o["anio"]} {o["descripcion"]} {autor or ""}'
    return (f'<a class="card" href="{href}" data-buscar="{e(buscar)}">'
            f'<span class="anio">{e(o["anio"])}{e(extra)}</span>'
            f'<h3>{e(o["titulo"])}</h3><p>{e(o["descripcion"])}</p></a>')


def main():
    cat = json.loads((RAIZ / "catalogo.json").read_text(encoding="utf-8"))
    sitio = cat["sitio"]
    if SALIDA.exists():
        shutil.rmtree(SALIDA)
    SALIDA.mkdir()
    (SALIDA / "estilo.css").write_text(CSS, encoding="utf-8")
    (SALIDA / ".nojekyll").write_text("")

    tarjetas_autores, todas = [], []
    for a in cat["autores"]:
        dest = SALIDA / a["slug"]
        dest.mkdir()
        n = 0
        secciones = []
        for p in a["periodos"]:
            cards = []
            for o in p["obras"]:
                src = FUENTES / a["slug"] / f'{o["slug"]}.html'
                if not src.exists():
                    print(f"  ! falta {src.relative_to(RAIZ)} — se omite")
                    continue
                doc = src.read_text(encoding="utf-8")
                doc = re.sub(r"(<body[^>]*>)", lambda m: m.group(1) + barra_volver(a, sitio["titulo"]), doc, count=1, flags=re.I)
                (dest / f'{o["slug"]}.html').write_text(doc, encoding="utf-8")
                cards.append(tarjeta_obra(o, f'{o["slug"]}.html'))
                todas.append(tarjeta_obra(o, f'{a["slug"]}/{o["slug"]}.html', a["nombre"]))
                n += 1
            if cards:
                secciones.append(
                    f'<section class="seccion" data-grupo><div class="seccion-cab"><h2>{e(p["nombre"])}</h2>'
                    f'<span class="fechas">{e(p.get("fechas",""))}</span></div>'
                    f'<p class="nota">{e(p.get("nota",""))}</p><div class="grid">{"".join(cards)}</div></section>')
        cuerpo = (f'<section class="hero"><p class="kicker">{e(a["fechas"])} · {e(a.get("origen",""))}</p>'
                  f'<h1>{e(a["nombre"])}</h1><p class="lema">{e(a["resumen"])}</p>'
                  f'<div class="buscar"><input id="q" type="search" placeholder="Buscar entre {n} obras…" aria-label="Buscar obras"></div></section>'
                  + "".join(secciones) + '<p class="vacio" id="vacio">Ninguna obra coincide con la búsqueda.</p>')
        miga = f'<a href="../index.html">Autores</a> / {e(a["nombre"].split()[-1])}'
        html_autor = pagina(f'{a["nombre"]} — {sitio["titulo"]}', a["resumen"], "../", miga, cuerpo, sitio["titulo"])
        if a.get("acento"):
            html_autor = html_autor.replace("</head>", f'<style>:root[data-theme="light"]{{--accent:{a["acento"]}}}@media (prefers-color-scheme:light){{:root:not([data-theme="dark"]){{--accent:{a["acento"]}}}}}</style>\n</head>')
        (dest / "index.html").write_text(html_autor, encoding="utf-8")
        tarjetas_autores.append(
            f'<a class="autor-card" href="{a["slug"]}/index.html" data-buscar="{e(a["nombre"])}">'
            f'<span class="inicial">{e(a["nombre"].split()[-1][0])}</span><div><h3>{e(a["nombre"])}</h3>'
            f'<p class="meta">{e(a["fechas"])} · {n} obras</p><p>{e(a["resumen"])}</p></div></a>')
        print(f"  {a['nombre']}: {n} obras")

    cuerpo = (f'<section class="hero"><p class="kicker">Biblioteca de guías interactivas</p>'
              f'<h1>{e(sitio["titulo"])}</h1><p class="lema">{e(sitio["lema"])}</p>'
              f'<div class="buscar"><input id="q" type="search" placeholder="Buscar un autor o una obra…" aria-label="Buscar"></div></section>'
              f'<section class="seccion" data-grupo><div class="seccion-cab"><h2>Autores</h2></div><p class="nota">Cada autor tiene su propio micrositio con sus obras ordenadas por período.</p>'
              f'<div class="autores">{"".join(tarjetas_autores)}</div></section>'
              f'<section class="seccion" data-grupo><div class="seccion-cab"><h2>Todas las obras</h2><span class="fechas">{len(todas)}</span></div>'
              f'<p class="nota">El catálogo completo del repositorio.</p><div class="grid">{"".join(todas)}</div></section>'
              '<p class="vacio" id="vacio">Nada coincide con la búsqueda.</p>')
    (SALIDA / "index.html").write_text(pagina(sitio["titulo"], sitio["lema"], "", "Inicio", cuerpo, sitio["titulo"]), encoding="utf-8")
    print(f"Listo: {SALIDA}")


if __name__ == "__main__":
    main()
