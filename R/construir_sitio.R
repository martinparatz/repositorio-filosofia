# =============================================================================
# R/construir_sitio.R
# La función principal: lee catalogo.json, copia cada guía de fuentes/ a
# sitio/ (con la barra «← Autor / Inicio»), y arma la portada y un
# micrositio por autor. Es la traducción a R de construir.py.
# =============================================================================

library(jsonlite)
library(stringr)

#' Construye el sitio estático completo.
#'
#' @param raiz             Carpeta del proyecto (donde están catalogo.json y fuentes/).
#' @param salida           Carpeta donde se genera el sitio (se borra y se rehace).
#' @param con_estadisticas Si es TRUE, agrega la página sitio/estadisticas/ con
#'                         gráficos (ver R/visualizacion.R). Con FALSE el resultado
#'                         es idéntico, byte a byte, al de construir.py.
#' @return Invisible: la lista de autores con la cantidad de obras publicadas.
construir_sitio <- function(raiz = ".", salida = file.path(raiz, "sitio"),
                            con_estadisticas = TRUE) {
  fuentes <- file.path(raiz, "fuentes")

  # 1) Leer el catálogo. simplifyVector = FALSE deja el JSON como listas
  #    anidadas (igual que los diccionarios de Python): autores -> períodos -> obras.
  cat_json <- fromJSON(file.path(raiz, "catalogo.json"), simplifyVector = FALSE)
  sitio <- cat_json$sitio

  # 2) Empezar de cero: borrar la salida anterior y crearla vacía.
  if (dir.exists(salida)) unlink(salida, recursive = TRUE)
  dir.create(salida, recursive = TRUE)
  file.copy(file.path(raiz, "plantillas", "estilo.css"), file.path(salida, "estilo.css"))
  escribir_texto("", file.path(salida, ".nojekyll"))  # GitHub Pages: no usar Jekyll

  tarjetas_autores <- character()
  todas <- character()
  resumen <- list()

  # 3) Un micrositio por autor.
  for (a in cat_json$autores) {
    destino <- file.path(salida, a$slug)
    dir.create(destino)
    n <- 0
    secciones <- character()

    for (p in a$periodos) {
      tarjetas <- character()
      for (o in p$obras) {
        origen <- file.path(fuentes, a$slug, paste0(o$slug, ".html"))
        if (!file.exists(origen)) {
          message("  ! falta fuentes/", a$slug, "/", o$slug, ".html — se omite")
          next
        }
        # Copiar la guía insertando la barra justo después de <body ...>.
        doc <- leer_texto(origen)
        doc <- str_replace(doc, regex("(<body[^>]*>)", ignore_case = TRUE),
                           function(m) paste0(m, barra_volver(a, sitio$titulo)))
        escribir_texto(doc, file.path(destino, paste0(o$slug, ".html")))

        tarjetas <- c(tarjetas, tarjeta_obra(o, paste0(o$slug, ".html")))
        todas    <- c(todas, tarjeta_obra(o, paste0(a$slug, "/", o$slug, ".html"), a$nombre))
        n <- n + 1
      }
      if (length(tarjetas) > 0) secciones <- c(secciones, seccion_periodo(p, tarjetas))
    }

    cuerpo <- paste0(
      '<section class="hero"><p class="kicker">', e(a$fechas), ' · ', e(obtener(a, "origen")), '</p>',
      '<h1>', e(a$nombre), '</h1><p class="lema">', e(a$resumen), '</p>',
      '<div class="buscar"><input id="q" type="search" placeholder="Buscar entre ', n,
      ' obras…" aria-label="Buscar obras"></div></section>',
      paste(secciones, collapse = ""),
      '<p class="vacio" id="vacio">Ninguna obra coincide con la búsqueda.</p>')
    miga <- paste0('<a href="../index.html">Autores</a> / ', e(ultima_palabra(a$nombre)))
    html_autor <- pagina(paste0(a$nombre, " — ", sitio$titulo), a$resumen, "../", miga, cuerpo, sitio$titulo)
    html_autor <- aplicar_acento(html_autor, a$acento)
    escribir_texto(html_autor, file.path(destino, "index.html"))

    tarjetas_autores <- c(tarjetas_autores, tarjeta_autor(a, n))
    resumen[[a$slug]] <- n
    message("  ", a$nombre, ": ", n, " obras")
  }

  # 4) Página de estadísticas (opcional, solo existe en la versión R).
  enlace_estadisticas <- ""
  if (con_estadisticas) {
    construir_estadisticas(raiz = raiz, salida = salida, sitio = sitio)
    enlace_estadisticas <- ' <a href="estadisticas/index.html">Ver estadísticas del repositorio →</a>'
  }

  # 5) Portada general.
  cuerpo <- paste0(
    '<section class="hero"><p class="kicker">Biblioteca de guías interactivas</p>',
    '<h1>', e(sitio$titulo), '</h1><p class="lema">', e(sitio$lema), '</p>',
    '<div class="buscar"><input id="q" type="search" placeholder="Buscar un autor o una obra…" aria-label="Buscar"></div></section>',
    '<section class="seccion" data-grupo><div class="seccion-cab"><h2>Autores</h2></div>',
    '<p class="nota">Cada autor tiene su propio micrositio con sus obras ordenadas por período.', enlace_estadisticas, '</p>',
    '<div class="autores">', paste(tarjetas_autores, collapse = ""), '</div></section>',
    '<section class="seccion" data-grupo><div class="seccion-cab"><h2>Todas las obras</h2><span class="fechas">', length(todas), '</span></div>',
    '<p class="nota">El catálogo completo del repositorio.</p><div class="grid">', paste(todas, collapse = ""), '</div></section>',
    '<p class="vacio" id="vacio">Nada coincide con la búsqueda.</p>')
  escribir_texto(pagina(sitio$titulo, sitio$lema, "", "Inicio", cuerpo, sitio$titulo),
                 file.path(salida, "index.html"))

  message("Listo: ", normalizePath(salida))
  invisible(resumen)
}
