# =============================================================================
# R/plantillas.R
# "Moldes" de HTML. Cada función recibe datos y devuelve un texto HTML.
# Usamos glue(): todo lo que está entre {llaves} se reemplaza por el valor
# de esa expresión de R. Es como pegar los datos dentro de un formulario.
# =============================================================================

library(glue)

#' Página HTML completa (portada general, micrositio de autor o estadísticas).
#'
#' @param titulo      Texto de la pestaña del navegador (<title>).
#' @param descripcion Texto para buscadores (<meta name="description">).
#' @param raiz        Camino relativo hasta la raíz del sitio: "" en la portada,
#'                    "../" dentro de la carpeta de un autor.
#' @param miga        "Miga de pan" (HTML ya armado): dónde estoy.
#' @param cuerpo      Contenido principal (HTML ya armado).
#' @param pie         Nombre del sitio, para la marca y el pie de página.
pagina <- function(titulo, descripcion, raiz, miga, cuerpo, pie) {
  fuentes_web <- leer_plantilla("fuentes-web.html")
  js_tema     <- leer_plantilla("tema.js")
  js_buscar   <- leer_plantilla("buscar.js")
  # .trim = FALSE: que glue no toque los saltos de línea ni la sangría.
  as.character(glue('<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{e(titulo)}</title>
<meta name="description" content="{e(descripcion)}">
{fuentes_web}
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
{js_tema}
{js_buscar}
</body>
</html>
', .trim = FALSE))
}

#' Barra flotante que se inserta en cada guía para volver al autor o al inicio.
barra_volver <- function(autor, sitio_titulo) {
  estilo_boton <- paste0(
    "background:#1c1a18;color:#f6f2ea;text-decoration:none;padding:9px 13px;",
    "border-radius:999px;box-shadow:0 2px 10px rgba(0,0,0,.25)")
  paste0(
    '<nav id="rf-volver" aria-label="Navegación del repositorio" style="position:fixed;left:16px;bottom:16px;z-index:2147483647;',
    'display:flex;gap:.5rem;font:500 13px/1 system-ui,-apple-system,sans-serif;">',
    '<a href="index.html" style="', estilo_boton, '">← ', e(ultima_palabra(autor$nombre)), '</a>',
    '<a href="../index.html" style="', estilo_boton, '" title="', e(sitio_titulo), '">Inicio</a></nav>')
}

#' Tarjeta de una obra (un rectángulo clickeable en la grilla).
#'
#' @param o     Lista con titulo, anio y descripcion de la obra.
#' @param href  Enlace a la guía.
#' @param autor Nombre del autor (solo en la portada general), o NULL.
tarjeta_obra <- function(o, href, autor = NULL) {
  extra  <- if (is.null(autor)) "" else paste0(" · ", autor)
  # data-buscar: el texto donde busca el buscador de la página.
  buscar <- paste0(o$titulo, " ", o$anio, " ", o$descripcion, " ", if (is.null(autor)) "" else autor)
  glue('<a class="card" href="{href}" data-buscar="{e(buscar)}">',
       '<span class="anio">{e(o$anio)}{e(extra)}</span>',
       '<h3>{e(o$titulo)}</h3><p>{e(o$descripcion)}</p></a>')
}

#' Bloque de un período: título, fechas, nota y la grilla de tarjetas.
seccion_periodo <- function(p, tarjetas) {
  glue('<section class="seccion" data-grupo><div class="seccion-cab"><h2>{e(p$nombre)}</h2>',
       '<span class="fechas">{e(obtener(p, "fechas"))}</span></div>',
       '<p class="nota">{e(obtener(p, "nota"))}</p><div class="grid">{paste(tarjetas, collapse = "")}</div></section>')
}

#' Tarjeta grande de un autor en la portada.
tarjeta_autor <- function(a, n_obras) {
  glue('<a class="autor-card" href="{a$slug}/index.html" data-buscar="{e(a$nombre)}">',
       '<span class="inicial">{e(substr(ultima_palabra(a$nombre), 1, 1))}</span><div><h3>{e(a$nombre)}</h3>',
       '<p class="meta">{e(a$fechas)} · {n_obras} obras</p><p>{e(a$resumen)}</p></div></a>')
}

#' Inserta en el <head> el color de acento propio del autor (solo tema claro).
aplicar_acento <- function(html, acento) {
  if (is.null(acento) || acento == "") return(html)
  estilo <- paste0('<style>:root[data-theme="light"]{--accent:', acento, '}',
                   '@media (prefers-color-scheme:light){:root:not([data-theme="dark"]){--accent:', acento, '}}</style>\n</head>')
  gsub("</head>", estilo, html, fixed = TRUE)
}
