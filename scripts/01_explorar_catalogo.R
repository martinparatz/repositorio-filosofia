# =============================================================================
# 01_explorar_catalogo.R — mirar los datos ANTES de construir nada.
# Lee catalogo.json, lo pasa a una tabla y responde preguntas simples.
# =============================================================================

# Cargar las funciones del proyecto (carpeta R/). Ejecutar con el .Rproj abierto,
# así el directorio de trabajo es la raíz del repositorio.
for (f in sort(list.files("R", pattern = "\\.R$", full.names = TRUE))) {
  suppressPackageStartupMessages(source(f, encoding = "UTF-8"))
}

# 1. El JSON "crudo", como listas anidadas: autores -> períodos -> obras.
crudo <- jsonlite::fromJSON("catalogo.json", simplifyVector = FALSE)
names(crudo)                          # "sitio" "autores"
length(crudo$autores)                 # cuántos autores hay
crudo$autores[[1]]$nombre             # el primero
str(crudo$autores[[1]]$periodos[[1]], max.level = 2)

# 2. La misma información como tabla ordenada (una fila por obra).
catalogo <- catalogo_a_tabla()
catalogo                               # en RStudio también: View(catalogo)

# 3. Preguntas típicas con dplyr.
catalogo |> count(autor)                               # obras por autor
catalogo |> count(autor, periodo, orden_periodo) |> arrange(autor, orden_periodo)
catalogo |> filter(!existe)                            # ¿falta algún archivo en fuentes/?
catalogo |> filter(is.na(anio_inicio)) |> select(autor, titulo, anio)  # obras sin año
catalogo |> filter(str_detect(str_to_lower(titulo), "verdad"))         # buscar por título
