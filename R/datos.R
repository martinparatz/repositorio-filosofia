# =============================================================================
# R/datos.R
# Recolección y procesamiento de datos:
#   - catalogo_a_tabla(): pasa catalogo.json (anidado) a una tabla "tidy",
#     una fila por obra.
#   - extraer_guia(): abre una guía HTML con rvest y saca título, secciones,
#     y texto limpio.
#   - medir_obras(): aplica extraer_guia() a todas las obras y calcula métricas.
#   - frecuencia_terminos(): cuenta las palabras más usadas por autor.
# =============================================================================

library(dplyr)
library(purrr)
library(tidyr)
library(stringr)
library(rvest)
library(xml2)
library(jsonlite)

#' Convierte el catálogo anidado en una tabla con una fila por obra.
#'
#' Columnas: autor_slug, autor, acento, periodo, orden_periodo, obra_slug,
#' titulo, anio (texto original), anio_inicio y anio_fin (números o NA),
#' descripcion, archivo (ruta a la fuente) y existe (¿está el archivo?).
catalogo_a_tabla <- function(raiz = ".") {
  cat_json <- fromJSON(file.path(raiz, "catalogo.json"), simplifyVector = FALSE)

  filas <- map_dfr(cat_json$autores, function(a) {
    map_dfr(seq_along(a$periodos), function(i) {
      p <- a$periodos[[i]]
      map_dfr(p$obras, function(o) {
        tibble(
          autor_slug    = a$slug,
          autor         = a$nombre,
          acento        = obtener(a, "acento", NA_character_),
          periodo       = p$nombre,
          orden_periodo = i,
          obra_slug     = o$slug,
          titulo        = o$titulo,
          anio          = o$anio,
          descripcion   = o$descripcion
        )
      })
    })
  })

  filas |>
    mutate(
      # "1872 – 1875" -> inicio 1872, fin 1875; "1870s" -> 1870; "Selección" -> NA
      anio_inicio = as.integer(str_extract(anio, "\\d{4}")),
      anio_fin    = as.integer(coalesce(str_extract(anio, "(?<=–\\s?)\\d{4}"), str_extract(anio, "\\d{4}"))),
      archivo     = file.path(raiz, "fuentes", autor_slug, paste0(obra_slug, ".html")),
      existe      = file.exists(archivo),
      # El orden del catálogo es el que se respeta en los gráficos.
      autor       = factor(autor, levels = unique(autor))
    )
}

#' Extrae la información útil de una guía HTML de NotebookLM.
#'
#' Quita <script> y <style> (código, no texto de la guía) y devuelve:
#' título de la pestaña, h1, cantidad de secciones h2/h3, cantidad de
#' párrafos y el texto plano completo.
extraer_guia <- function(archivo) {
  doc <- read_html(archivo, encoding = "UTF-8")
  xml_remove(html_elements(doc, "script, style, noscript, template"))

  h2 <- html_text2(html_elements(doc, "h2"))
  h3 <- html_text2(html_elements(doc, "h3"))
  # Algunos títulos son plantillas de JavaScript (p. ej. "${item.title}"): afuera.
  h3 <- h3[!str_detect(h3, fixed("${"))]

  tibble(
    titulo_pagina = html_text2(html_element(doc, "title")),
    h1            = str_squish(html_text2(html_element(doc, "h1"))),
    n_secciones   = length(h2),
    n_subsecciones = length(h3),
    n_parrafos    = length(html_elements(doc, "p")),
    secciones     = list(str_squish(h2)),
    texto         = html_text2(html_element(doc, "body"))
  )
}

#' Mide todas las obras del catálogo (las que tienen archivo).
#'
#' @return La tabla del catálogo + columnas de extraer_guia() + n_palabras
#'         y kb (tamaño del archivo en kilobytes).
medir_obras <- function(catalogo) {
  catalogo |>
    filter(existe) |>
    mutate(info = map(archivo, extraer_guia)) |>
    unnest(info) |>
    mutate(
      n_palabras = str_count(texto, "\\p{L}+"),
      kb         = round(file.size(archivo) / 1024, 1)
    )
}

# Palabras vacías del español (artículos, preposiciones, etc.) más palabras
# que aparecen en todas las guías por su formato y no por su contenido.
PALABRAS_VACIAS <- c(
  "a", "al", "algo", "algunas", "algunos", "ante", "antes", "aquí", "así", "aun", "aunque",
  "bajo", "bien", "cada", "como", "con", "contra", "cual", "cuales", "cuando", "de", "del",
  "desde", "donde", "dos", "durante", "e", "el", "ella", "ellas", "ello", "ellos", "en",
  "entre", "era", "es", "esa", "esas", "ese", "eso", "esos", "esta", "está", "estas", "este",
  "esto", "estos", "fue", "ha", "hace", "hacia", "han", "hasta", "hay", "la", "las", "le",
  "les", "lo", "los", "más", "mas", "me", "mi", "mismo", "misma", "muy", "ni", "no", "nos",
  "o", "otra", "otras", "otro", "otros", "para", "pero", "poco", "por", "porque", "puede",
  "que", "qué", "se", "sea", "según", "ser", "si", "sí", "sin", "sino", "sobre", "son", "su",
  "sus", "tal", "también", "tan", "tanto", "te", "tiene", "toda", "todas", "todo", "todos",
  "tras", "u", "un", "una", "uno", "unos", "unas", "y", "ya", "sólo", "solo", "cómo",
  "cuál", "través", "parte", "forma", "modo", "vez", "sus", "obra", "guía", "texto",
  "capítulo", "sección", "pregunta", "respuesta", "correcta", "incorrecta", "ver",
  "clic", "filtrar", "todas", "mostrar", "nota", "notas", "pueden", "cuyo", "cuya", "dice",
  "frente", "mientras", "dentro", "siempre", "nunca", "ahora", "luego", "pues", "allí"
)

#' Frecuencia de términos por autor.
#'
#' Pasa el texto a minúsculas, lo corta en palabras, descarta palabras vacías
#' y palabras cortas, y cuenta. Devuelve formato largo: autor, termino, n.
#'
#' @param medidas Resultado de medir_obras().
#' @param min_letras Largo mínimo de una palabra para contarla.
frecuencia_terminos <- function(medidas, min_letras = 4) {
  medidas |>
    select(autor, obra_slug, texto) |>
    mutate(
      termino  = str_extract_all(str_to_lower(texto), "\\p{L}+"),
      apellido = str_to_lower(map_chr(as.character(autor), ultima_palabra))
    ) |>
    select(-texto) |>
    unnest(termino) |>
    filter(str_length(termino) >= min_letras, !termino %in% PALABRAS_VACIAS) |>
    # El apellido del autor aparece en todas sus guías: no aporta, lo sacamos.
    filter(termino != apellido) |>
    count(autor, termino, sort = TRUE)
}
