# =============================================================================
# 04_construir_sitio.R — generar la carpeta sitio/ (lo que se publica).
# =============================================================================

# Cargar las funciones del proyecto (carpeta R/). Ejecutar con el .Rproj abierto,
# así el directorio de trabajo es la raíz del repositorio.
for (f in sort(list.files("R", pattern = "\\.R$", full.names = TRUE))) {
  suppressPackageStartupMessages(source(f, encoding = "UTF-8"))
}

# Con estadísticas (versión completa en R):
construir_sitio(raiz = ".", con_estadisticas = TRUE)

# Sin estadísticas: el resultado es idéntico, byte a byte, al de construir.py.
# construir_sitio(raiz = ".", con_estadisticas = FALSE)

# Abrir la portada en el navegador:
browseURL("sitio/index.html")
