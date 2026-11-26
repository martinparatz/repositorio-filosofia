# =============================================================================
# guia-r/renderizar_docx.R — genera guia-rstudio.docx a partir de la guía .qmd
#
# Lo más simple es abrir guia-rstudio.qmd en RStudio y apretar "Render"
# (usa Quarto y produce HTML y Word). Este script es una alternativa que solo
# necesita pandoc (incluido en RStudio): pega el código de cada archivo en los
# bloques {r, file="..."} y convierte a Word.
# Uso (con el proyecto abierto):  source("guia-r/renderizar_docx.R")
# =============================================================================

carpeta <- "guia-r"
lineas  <- readLines(file.path(carpeta, "guia-rstudio.qmd"), encoding = "UTF-8")
salida  <- character()
for (linea in lineas) {
  archivo <- regmatches(linea, regexec('^```\\{r, file="([^"]+)"\\}', linea))[[1]]
  if (length(archivo) == 2) {
    codigo <- readLines(file.path(carpeta, archivo[2]), encoding = "UTF-8")
    salida <- c(salida, "```r", codigo)
  } else {
    salida <- c(salida, sub("^```\\{r[^}]*\\}", "```r", linea))
  }
}
temporal <- file.path(carpeta, "_guia_docx.md")
writeLines(salida, temporal, useBytes = TRUE)
rmarkdown::pandoc_convert(
  "_guia_docx.md", to = "docx", output = "guia-rstudio.docx", wd = carpeta,
  options = c("--from=markdown", "--toc", "--number-sections", "--resource-path=.")
)
if (!isTRUE(getOption("guia.conservar_md"))) unlink(temporal)
message("Listo: guia-r/guia-rstudio.docx")
