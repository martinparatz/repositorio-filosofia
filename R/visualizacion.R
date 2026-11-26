# =============================================================================
# R/visualizacion.R
# Gráficos con ggplot2 sobre los datos de los autores y la página
# sitio/estadisticas/index.html que los muestra dentro del sitio.
# =============================================================================

library(ggplot2)
library(dplyr)
library(forcats)
library(scales)

# Un color por autor, asignado SIEMPRE en el orden del catálogo (el autor 1
# recibe el color 1, etc.). Así un autor conserva su color en todos los
# gráficos. Paleta categórica validada para daltonismo (azul, naranja,
# aguamarina, amarillo, magenta, verde, violeta, rojo).
PALETA_AUTORES <- c("#2a78d6", "#eb6834", "#1baf7a", "#eda100",
                    "#e87ba4", "#008300", "#6f52d6", "#d63b3b")

colores_autores <- function(autores) {
  niveles <- levels(factor(autores))
  if (length(niveles) > length(PALETA_AUTORES)) {
    warning("Hay más autores que colores: conviene usar facetas en vez de color.")
  }
  setNames(rep_len(PALETA_AUTORES, length(niveles)), niveles)
}

# Tema común: fondo liso, grilla tenue, tipografía sobria.
tema_repositorio <- function() {
  theme_minimal(base_size = 12) +
    theme(
      plot.title         = element_text(face = "bold", size = 14),
      plot.subtitle      = element_text(colour = "#5e5850"),
      plot.caption       = element_text(colour = "#5e5850", size = 9),
      panel.grid.minor   = element_blank(),
      panel.grid.major.y = element_blank(),
      panel.grid.major.x = element_line(colour = "#e6e0d6", linewidth = 0.3),
      axis.text          = element_text(colour = "#3a352d"),
      legend.position    = "none",
      plot.background    = element_rect(fill = "white", colour = NA)
    )
}

#' 1) Cantidad de obras por autor (barras horizontales).
grafico_obras_por_autor <- function(catalogo) {
  datos <- catalogo |> filter(existe) |> count(autor)
  ggplot(datos, aes(x = n, y = fct_rev(autor))) +
    geom_col(fill = PALETA_AUTORES[1], width = 0.6) +
    geom_text(aes(label = n), hjust = -0.3, size = 3.8) +
    scale_x_continuous(expand = expansion(mult = c(0, 0.1))) +
    labs(title = "Obras por autor", subtitle = "Guías publicadas en el repositorio",
         x = NULL, y = NULL) +
    tema_repositorio()
}

#' 2) Línea de tiempo: cuándo se escribió cada obra.
#' Un punto por obra; si la obra abarca varios años, una línea de inicio a fin.
grafico_linea_de_tiempo <- function(catalogo) {
  datos <- catalogo |> filter(existe, !is.na(anio_inicio))
  sin_fecha <- sum(catalogo$existe & is.na(catalogo$anio_inicio))
  ggplot(datos, aes(y = fct_rev(autor), colour = autor)) +
    geom_segment(aes(x = anio_inicio, xend = anio_fin, yend = fct_rev(autor)),
                 linewidth = 2, alpha = 0.35, lineend = "round") +
    geom_point(aes(x = anio_inicio), size = 3, alpha = 0.85) +
    scale_colour_manual(values = colores_autores(catalogo$autor)) +
    scale_x_continuous(breaks = seq(1650, 2050, by = 50)) +
    labs(title = "Línea de tiempo de las obras",
         subtitle = "Año de inicio (punto) y período de escritura (barra)",
         caption = if (sin_fecha > 0) paste(sin_fecha, "obra(s) sin año (selecciones o atribuidas) no se muestran.") else NULL,
         x = NULL, y = NULL) +
    tema_repositorio() +
    theme(panel.grid.major.x = element_line(colour = "#e6e0d6", linewidth = 0.3))
}

#' 3) Extensión de cada guía (palabras de texto visible), por autor.
grafico_extension <- function(medidas) {
  medianas <- medidas |> group_by(autor) |> summarise(mediana = median(n_palabras))
  ggplot(medidas, aes(x = n_palabras, y = fct_rev(autor), colour = autor)) +
    geom_point(size = 3, alpha = 0.6, position = position_jitter(height = 0.15, seed = 1)) +
    geom_point(data = medianas, aes(x = mediana), shape = 124, size = 9, colour = "#1c1a18") +
    scale_colour_manual(values = colores_autores(medidas$autor)) +
    scale_x_continuous(labels = label_number(big.mark = ".", decimal.mark = ",")) +
    labs(title = "Extensión de las guías",
         subtitle = "Palabras de texto visible por guía; la raya negra marca la mediana del autor",
         x = "Palabras", y = NULL) +
    tema_repositorio()
}

#' 4) Los términos más frecuentes de cada autor (una faceta por autor).
grafico_terminos <- function(frecuencias, n_top = 10) {
  datos <- frecuencias |>
    group_by(autor) |>
    slice_max(n, n = n_top, with_ties = FALSE) |>
    ungroup() |>
    # reorder dentro de cada faceta: truco con el nombre del autor pegado.
    mutate(termino_orden = reorder(paste(termino, autor, sep = "___"), n))
  ggplot(datos, aes(x = n, y = termino_orden, fill = autor)) +
    geom_col(width = 0.7) +
    facet_wrap(~ autor, scales = "free", ncol = 3) +
    scale_y_discrete(labels = function(x) sub("___.*$", "", x)) +
    scale_fill_manual(values = colores_autores(frecuencias$autor)) +
    labs(title = "Términos más frecuentes por autor",
         subtitle = paste("Las", n_top, "palabras más usadas en sus guías (sin palabras vacías)"),
         x = "Apariciones", y = NULL) +
    tema_repositorio() +
    theme(strip.text = element_text(face = "bold", hjust = 0))
}

#' Guarda un gráfico como PNG (ancho en pulgadas; 150 ppp alcanza para la web).
guardar_grafico <- function(grafico, ruta, ancho = 9, alto = 5) {
  ggsave(ruta, grafico, width = ancho, height = alto, dpi = 150, bg = "white")
  invisible(ruta)
}

#' Tabla HTML con un resumen por autor.
tabla_resumen_html <- function(medidas) {
  resumen <- medidas |>
    group_by(autor) |>
    summarise(
      obras    = n(),
      palabras = sum(n_palabras),
      promedio = round(mean(n_palabras)),
      desde    = suppressWarnings(min(anio_inicio, na.rm = TRUE)),
      hasta    = suppressWarnings(max(anio_fin, na.rm = TRUE))
    )
  formato <- function(x) format(x, big.mark = ".", decimal.mark = ",", trim = TRUE)
  filas <- paste0("<tr><td>", e(resumen$autor), "</td><td>", resumen$obras, "</td><td>",
                  formato(resumen$palabras), "</td><td>", formato(resumen$promedio), "</td><td>",
                  resumen$desde, " – ", resumen$hasta, "</td></tr>", collapse = "")
  paste0('<table class="tabla"><thead><tr><th>Autor</th><th>Obras</th><th>Palabras</th>',
         '<th>Promedio por guía</th><th>Período</th></tr></thead><tbody>', filas, '</tbody></table>')
}

#' Construye sitio/estadisticas/: calcula los datos, guarda los gráficos y
#' arma la página HTML con el mismo diseño que el resto del sitio.
construir_estadisticas <- function(raiz = ".", salida = file.path(raiz, "sitio"), sitio) {
  destino <- file.path(salida, "estadisticas")
  dir.create(destino, showWarnings = FALSE, recursive = TRUE)

  catalogo <- catalogo_a_tabla(raiz)
  medidas  <- medir_obras(catalogo)
  frec     <- frecuencia_terminos(medidas)
  n_autores <- n_distinct(catalogo$autor)

  graficos <- list(
    list(archivo = "obras-por-autor.png", g = grafico_obras_por_autor(catalogo), alto = 1 + 0.5 * n_autores,
         texto = "Cuántas guías tiene cada autor en el repositorio."),
    list(archivo = "linea-de-tiempo.png", g = grafico_linea_de_tiempo(catalogo), alto = 1.5 + 0.6 * n_autores,
         texto = "Cuándo se escribió cada obra, autor por autor."),
    list(archivo = "extension.png", g = grafico_extension(medidas), alto = 1.5 + 0.6 * n_autores,
         texto = "Cada punto es una guía. Sirve para detectar guías muy cortas o muy largas."),
    list(archivo = "terminos.png", g = grafico_terminos(frec), alto = 2.5 * ceiling(n_autores / 3),
         texto = "Un primer acercamiento al vocabulario de cada pensador.")
  )

  figuras <- character()
  for (gr in graficos) {
    guardar_grafico(gr$g, file.path(destino, gr$archivo), alto = gr$alto)
    figuras <- c(figuras, paste0(
      '<figure class="figura"><img src="', gr$archivo, '" alt="', e(gr$texto), '" loading="lazy">',
      '<figcaption>', e(gr$texto), '</figcaption></figure>'))
  }

  estilos <- paste0(
    "<style>.figura{margin:0 0 2.5rem}.figura img{width:100%;height:auto;border:1px solid var(--rule);background:#fff}",
    ".figura figcaption{color:var(--muted);font:.9rem/1.5 var(--sans);margin-top:.5rem}",
    ".tabla{width:100%;border-collapse:collapse;font:.95rem/1.4 var(--sans);margin-bottom:2.5rem}",
    ".tabla th,.tabla td{text-align:left;padding:.55rem .6rem;border-bottom:1px solid var(--rule)}",
    ".tabla th{color:var(--muted);font-weight:600}</style>")

  cuerpo <- paste0(
    estilos,
    '<section class="hero"><p class="kicker">Datos del repositorio</p><h1>Estadísticas</h1>',
    '<p class="lema">', nrow(medidas), ' guías de ', n_autores,
    ' autores, medidas y graficadas con R (rvest + dplyr + ggplot2).</p></section>',
    '<section class="seccion"><div class="seccion-cab"><h2>Resumen por autor</h2></div>',
    '<p class="nota">Palabras de texto visible de cada guía, sin contar código.</p>',
    tabla_resumen_html(medidas), '</section>',
    '<section class="seccion"><div class="seccion-cab"><h2>Gráficos</h2></div>',
    paste(figuras, collapse = ""), '</section>')

  miga <- '<a href="../index.html">Autores</a> / Estadísticas'
  html <- pagina(paste0("Estadísticas — ", sitio$titulo),
                 "Estadísticas y gráficos del Repositorio de Filosofía.",
                 "../", miga, cuerpo, sitio$titulo)
  escribir_texto(html, file.path(destino, "index.html"))
  message("  Estadísticas: ", length(graficos), " gráficos en ", destino)
  invisible(list(catalogo = catalogo, medidas = medidas, frecuencias = frec))
}
