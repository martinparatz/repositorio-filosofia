# =============================================================================
# 00_instalar_paquetes.R — se corre UNA sola vez por computadora.
# Instala los paquetes que usa el proyecto (solo los que falten).
# =============================================================================

paquetes <- c(
  "jsonlite",  # leer catalogo.json
  "glue",      # plantillas de texto con {llaves}
  "stringr",   # expresiones regulares y manejo de texto
  "rvest",     # leer y recorrer HTML (web scraping)
  "xml2",      # base de rvest: modificar el árbol HTML
  "dplyr",     # transformar tablas (filter, mutate, summarise...)
  "tidyr",     # ordenar tablas (unnest, pivot...)
  "purrr",     # aplicar una función a cada elemento (map)
  "forcats",   # ordenar factores (categorías) en los gráficos
  "ggplot2",   # gráficos
  "scales",    # formato de números en los ejes
  "readr"      # guardar y leer CSV
)
opcionales <- c("plotly", "servr", "renv", "quarto")  # interactividad, servidor local, entorno reproducible, informes

faltan <- setdiff(paquetes, rownames(installed.packages()))
if (length(faltan) > 0) install.packages(faltan) else message("Paquetes básicos: todo instalado.")

# Para instalar también los opcionales, descomentá la línea siguiente:
# install.packages(setdiff(opcionales, rownames(installed.packages())))
