# =============================================================================
# 03_visualizar.R — explorar los datos con gráficos.
# Cada gráfico aparece en el panel "Plots" de RStudio; al final se guardan.
# =============================================================================

# Cargar las funciones del proyecto (carpeta R/). Ejecutar con el .Rproj abierto,
# así el directorio de trabajo es la raíz del repositorio.
for (f in sort(list.files("R", pattern = "\\.R$", full.names = TRUE))) {
  suppressPackageStartupMessages(source(f, encoding = "UTF-8"))
}

catalogo <- catalogo_a_tabla()
medidas  <- medir_obras(catalogo)
terminos <- frecuencia_terminos(medidas)

g1 <- grafico_obras_por_autor(catalogo);  print(g1)
g2 <- grafico_linea_de_tiempo(catalogo);  print(g2)
g3 <- grafico_extension(medidas);         print(g3)
g4 <- grafico_terminos(terminos);         print(g4)

# Guardar como PNG en salidas/graficos/
dir.create("salidas/graficos", recursive = TRUE, showWarnings = FALSE)
guardar_grafico(g1, "salidas/graficos/obras-por-autor.png", alto = 3.5)
guardar_grafico(g2, "salidas/graficos/linea-de-tiempo.png")
guardar_grafico(g3, "salidas/graficos/extension.png")
guardar_grafico(g4, "salidas/graficos/terminos.png", alto = 6)

# Opcional: versión interactiva (pasar el mouse muestra los valores).
# Requiere install.packages("plotly").
if (requireNamespace("plotly", quietly = TRUE)) {
  interactivo <- plotly::ggplotly(
    ggplot(medidas, aes(n_palabras, fct_rev(autor), colour = autor, text = titulo)) +
      geom_point(size = 3) + tema_repositorio(),
    tooltip = c("text", "x"))
  print(interactivo)
  # htmlwidgets::saveWidget(interactivo, "salidas/graficos/extension.html")
}
