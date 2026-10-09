---
name: generar-imagen
description: Genera imágenes gratis con FLUX (Cloudflare Workers AI) y las guarda como JPG. Usar cuando el usuario pida "genera una imagen", "hazme una foto de…", "crea una ilustración", "imagen de producto", "boceto", "mockup", "fondo para…" o cualquier imagen nueva a partir de un texto. No sirve para editar fotos existentes ni para poner texto legible dentro de la imagen.
---

# Generar imagen (FLUX gratis)

Genera una imagen cuadrada de 1024×1024 a partir de un texto con el script `generar.mjs` de esta carpeta.

## Pasos

1. **Escribir el prompt en inglés**, aunque el usuario hable en otro idioma. Describir:
   - el sujeto y el material,
   - el encuadre (primer plano, plano general, cenital),
   - la luz (natural de ventana, estudio suave, atardecer),
   - el fondo y el estilo (foto de producto, ilustración plana, acuarela, 3D).
   Ser concreto: "a clear glass water bottle with a brushed steel cap on a white marble counter, soft window light, minimalist product photo" funciona mejor que "a bottle".
2. **Ejecutar** (sustituir `<carpeta-de-esta-skill>` por el directorio base de la skill):
   ```bash
   node "<carpeta-de-esta-skill>/generar.mjs" --prompt "<prompt en inglés>" --salida "<nombre-descriptivo>.jpg"
   ```
   - Guardar en la carpeta de trabajo actual con un nombre que diga qué es (`botella-agua.jpg`, no `imagen1.jpg`).
   - `--pasos 8` da algo más de detalle (por defecto son 4; el máximo es 8) y gasta el doble de cuota.
   - Para varias versiones, lanzar el comando varias veces con nombres distintos (`-v1`, `-v2`…).
3. **Comprobar el resultado**: abrir el JPG con la herramienta de leer archivos y mirar si cumple lo pedido. Si algo sale mal (manos raras, objeto deformado), reformular el prompt y repetir una vez.
4. **Entregar**: enseñar la imagen al usuario y decirle dónde está guardada.

## Límites (decírselos al usuario si importan)

- Solo hace imágenes cuadradas de 1024×1024. Para otro formato, recortar después.
- El texto dentro de la imagen sale mal. Para carteles con texto, generar el fondo y poner el texto aparte.
- Calidad de boceto o de banco de imágenes: no presentarla como foto real de un cliente o producto concreto.
- La cuota gratis de Cloudflare da para unas 170 imágenes al día con 4 pasos (unas 100 con 8). Se renueva a medianoche UTC (1:00 o 2:00 en España).

## Errores

- `No encuentro las claves de Cloudflare` → el usuario debe ejecutar `Guardar claves Cloudflare.cmd` (incluido en el paquete que instaló) y reiniciar Claude.
- `Cloudflare rechaza las claves (401/403)` → el token está mal copiado o le falta el permiso "Workers AI". Crear otro con la plantilla "Workers AI" y guardarlo de nuevo.
- `cuota gratis de hoy` → esperar al día siguiente.
- `node: command not found` → falta Node.js: `winget install OpenJS.NodeJS.LTS` y reiniciar Claude.
