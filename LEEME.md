# Repositorio de Filosofía — sitio estático

## Estructura
```
sitio-filosofia/
├── catalogo.json      ← autores, períodos y obras (lo único que se edita a mano)
├── construir.py       ← genera la carpeta sitio/ (python3 construir.py)
├── fuentes/
│   └── nietzsche/     ← HTML originales de NotebookLM, uno por obra (<slug-obra>.html)
└── sitio/             ← RESULTADO: esto es lo que se publica
    ├── index.html     ← portada general: autores + catálogo completo + buscador
    ├── estilo.css
    └── nietzsche/
        ├── index.html ← micrositio del autor: obras por período + buscador
        └── <obra>.html← cada guía, con botones flotantes «← Autor» e «Inicio»
```
Las URLs quedan así: `/nietzsche/`, `/nietzsche/aurora.html`, `/platon/republica.html`…

## Construir con R / RStudio
También se puede generar el sitio desde R: abrir `repositorio-filosofia.Rproj` en RStudio y correr
`scripts/04_construir_sitio.R`, o desde la terminal `Rscript construir.R`. Con `--sin-estadisticas`
el resultado es idéntico al de `construir.py`; sin esa opción agrega `sitio/estadisticas/` con gráficos.
La guía completa (arquitectura, procesamiento con rvest, gráficos con ggplot2, publicación) está en
`guia-r/guia-rstudio.qmd` (también en `.docx` y `.pdf`).

## Añadir un autor nuevo (p. ej. Platón)
1. Crear `fuentes/platon/` y copiar ahí sus HTML con nombres simples: `la-republica.html`, `fedon.html`…
2. En `catalogo.json`, copiar el bloque de Nietzsche dentro de `"autores"` y cambiar slug, nombre, fechas,
   resumen, color de acento y la lista de períodos/obras (el `slug` de cada obra = nombre del archivo sin .html).
3. Ejecutar `python3 construir.py` (o `Rscript construir.R`) y volver a publicar la carpeta `sitio/`.

## Publicar gratis
- **GitHub Pages** (recomendado): repositorio público con la carpeta `sitio/` publicada; cada cambio queda versionado.
- **Netlify Drop**: arrastrar la carpeta `sitio/` a https://app.netlify.com/drop — online en un minuto.
- **Cloudflare Pages**: igual que Netlify, también gratis.
