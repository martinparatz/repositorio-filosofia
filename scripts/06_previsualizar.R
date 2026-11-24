# =============================================================================
# 06_previsualizar.R — ver el sitio como si estuviera publicado.
# Abrir los HTML con doble clic funciona casi siempre, pero un servidor local
# reproduce mejor GitHub Pages (rutas, carpetas, etc.).
# =============================================================================

if (!requireNamespace("servr", quietly = TRUE)) install.packages("servr")
servr::httd("sitio", port = 4321)   # luego abrir http://127.0.0.1:4321
# Para detenerlo: servr::daemon_stop()
