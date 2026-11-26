#!/usr/bin/env Rscript
# =============================================================================
# construir.R — genera la carpeta sitio/ desde R (equivalente a construir.py)
#
# Uso desde RStudio: abrir repositorio-filosofia.Rproj y apretar "Source"
#                    (o Ctrl/Cmd + Shift + S) con este archivo abierto.
# Uso desde la terminal:   Rscript construir.R
#                          Rscript construir.R --sin-estadisticas
#
# Con --sin-estadisticas el resultado es idéntico al de python3 construir.py.
# =============================================================================

# Cargar todas las funciones de la carpeta R/ (en orden alfabético).
for (archivo in sort(list.files("R", pattern = "\\.R$", full.names = TRUE))) {
  suppressPackageStartupMessages(source(archivo, encoding = "UTF-8"))
}

argumentos <- commandArgs(trailingOnly = TRUE)
construir_sitio(raiz = ".", con_estadisticas = !("--sin-estadisticas" %in% argumentos))
