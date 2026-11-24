# =============================================================================
# R/utilidades.R
# Funciones pequeñas que usan todos los demás archivos: leer y escribir texto
# en UTF-8 sin sorpresas, y "escapar" texto para meterlo dentro de HTML.
# =============================================================================

#' Escapa texto para insertarlo en HTML de forma segura.
#'
#' Reemplaza los cinco caracteres que tienen significado especial en HTML.
#' Es el equivalente exacto de html.escape() de Python (con quote = TRUE),
#' así el sitio que genera R es idéntico al que genera construir.py.
#'
#' @param x Texto (o vector de textos). NULL se trata como "".
#' @return Texto escapado.
#' @examples
#' e("Ser & tiempo <1927>")   # "Ser &amp; tiempo &lt;1927&gt;"
e <- function(x) {
  if (is.null(x)) x <- ""
  x <- as.character(x)
  x <- gsub("&", "&amp;", x, fixed = TRUE)   # ¡el & siempre primero!
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub("\"", "&quot;", x, fixed = TRUE)
  x <- gsub("'", "&#x27;", x, fixed = TRUE)
  x
}

#' Devuelve el valor de una lista o un valor por defecto si no existe.
#' Equivale a dic.get("clave", "") en Python.
obtener <- function(lista, clave, por_defecto = "") {
  valor <- lista[[clave]]
  if (is.null(valor)) por_defecto else valor
}

#' Última palabra de un nombre: "Friedrich Nietzsche" -> "Nietzsche".
ultima_palabra <- function(nombre) {
  palabras <- strsplit(trimws(nombre), "\\s+")[[1]]
  palabras[length(palabras)]
}

#' Lee un archivo de texto completo, tal cual está (sin perder saltos de línea).
leer_texto <- function(ruta) {
  tamanio <- file.info(ruta)$size
  texto <- readChar(ruta, tamanio, useBytes = TRUE)
  Encoding(texto) <- "UTF-8"
  texto
}

#' Escribe texto en un archivo en UTF-8, byte a byte, sin agregar nada.
#' (writeLines() agrega un salto de línea final; acá no queremos eso.)
escribir_texto <- function(texto, ruta) {
  writeBin(charToRaw(enc2utf8(as.character(texto))), ruta)
  invisible(ruta)
}

#' Lee un fragmento de plantilla (CSS, JS, HTML) y le quita el salto final,
#' para poder pegarlo dentro de otra plantilla.
leer_plantilla <- function(nombre, carpeta = "plantillas") {
  sub("\n$", "", leer_texto(file.path(carpeta, nombre)))
}
