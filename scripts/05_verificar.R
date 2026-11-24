# =============================================================================
# 05_verificar.R — controles de calidad antes de publicar.
#   1) ¿Están todas las obras del catálogo en fuentes/?
#   2) ¿Hay archivos en fuentes/ que el catálogo no menciona?
#   3) ¿Todos los enlaces internos del sitio apuntan a archivos que existen?
#   4) (Si hay Python) ¿El sitio de R es idéntico al de construir.py?
# =============================================================================

# Cargar las funciones del proyecto (carpeta R/). Ejecutar con el .Rproj abierto,
# así el directorio de trabajo es la raíz del repositorio.
for (f in sort(list.files("R", pattern = "\\.R$", full.names = TRUE))) {
  suppressPackageStartupMessages(source(f, encoding = "UTF-8"))
}

catalogo <- catalogo_a_tabla()

# 1) Obras del catálogo sin archivo
faltantes <- catalogo |> filter(!existe)
if (nrow(faltantes) == 0) message("OK: todas las obras tienen su HTML.") else print(faltantes |> select(autor_slug, obra_slug))

# 2) Archivos huérfanos (están en fuentes/ pero no en el catálogo)
en_disco <- list.files("fuentes", pattern = "\\.html$", recursive = TRUE)
en_catalogo <- file.path(catalogo$autor_slug, paste0(catalogo$obra_slug, ".html"))
huerfanos <- setdiff(en_disco, en_catalogo)
if (length(huerfanos) == 0) message("OK: no hay archivos huérfanos.") else print(huerfanos)

# 3) Enlaces rotos dentro del sitio (solo páginas generadas, no las guías)
construir_sitio(con_estadisticas = TRUE)
paginas <- c("sitio/index.html", list.files("sitio", pattern = "^index\\.html$", recursive = TRUE, full.names = TRUE))
rotos <- purrr::map_dfr(unique(paginas), function(pag) {
  nodos <- rvest::html_elements(rvest::read_html(pag), "a, link[rel=stylesheet], img")
  enlaces <- c(rvest::html_attr(nodos, "href"), rvest::html_attr(nodos, "src"))
  enlaces <- enlaces[!is.na(enlaces) & !grepl("^(https?:|#|mailto:)", enlaces)]
  tibble::tibble(pagina = pag, enlace = enlaces,
                 existe = file.exists(file.path(dirname(pag), enlaces)))
}) |> dplyr::filter(!existe)
if (nrow(rotos) == 0) message("OK: ningún enlace interno roto.") else print(rotos)

# 4) Comparar con la versión de Python (si está instalada)
python <- Sys.which(c("python3", "python"))
python <- python[python != ""][1]
if (!is.na(python)) {
  tmp <- tempfile("sitio_py_")
  system2(python, "construir.py", stdout = FALSE)
  file.rename("sitio", tmp)
  construir_sitio(con_estadisticas = FALSE)
  a <- list.files(tmp, recursive = TRUE, all.files = TRUE)
  b <- list.files("sitio", recursive = TRUE, all.files = TRUE)
  iguales <- identical(sort(a), sort(b)) &&
    all(tools::md5sum(file.path(tmp, a)) == tools::md5sum(file.path("sitio", a)))
  message(if (iguales) "OK: el sitio de R es idéntico al de Python." else "ATENCIÓN: hay diferencias con Python.")
  unlink(tmp, recursive = TRUE)
  construir_sitio(con_estadisticas = TRUE)   # dejar la versión completa
} else {
  message("Python no está instalado: se saltea la comparación (no es obligatoria).")
}
