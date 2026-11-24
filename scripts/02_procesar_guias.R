# =============================================================================
# 02_procesar_guias.R — recolectar y procesar el texto de cada guía HTML.
# Resultado: datos/obras.csv y datos/terminos.csv (tablas listas para analizar).
# =============================================================================

# Cargar las funciones del proyecto (carpeta R/). Ejecutar con el .Rproj abierto,
# así el directorio de trabajo es la raíz del repositorio.
for (f in sort(list.files("R", pattern = "\\.R$", full.names = TRUE))) {
  suppressPackageStartupMessages(source(f, encoding = "UTF-8"))
}

catalogo <- catalogo_a_tabla()

# Probar primero con UNA guía, para entender qué devuelve extraer_guia().
una <- extraer_guia("fuentes/nietzsche/aurora.html")
una$h1
una$secciones[[1]]            # títulos de las secciones (h2)
substr(una$texto, 1, 500)     # primeros 500 caracteres del texto limpio

# Ahora todas (tarda unos segundos).
medidas <- medir_obras(catalogo)
medidas |> select(autor, titulo, n_secciones, n_parrafos, n_palabras, kb)

terminos <- frecuencia_terminos(medidas)
terminos |> group_by(autor) |> slice_max(n, n = 5)

# Guardar en CSV (sin la columna de texto completo ni la lista de secciones).
dir.create("datos", showWarnings = FALSE)
medidas |>
  select(-texto, -secciones) |>
  mutate(autor = as.character(autor)) |>
  readr::write_csv("datos/obras.csv")
readr::write_csv(terminos, "datos/terminos.csv")
message("Guardado: datos/obras.csv (", nrow(medidas), " filas) y datos/terminos.csv")
