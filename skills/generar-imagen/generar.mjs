#!/usr/bin/env node
// Genera una imagen con FLUX (Cloudflare Workers AI) y la guarda como JPG.
// Uso: node generar.mjs --prompt "..." [--salida imagen.jpg] [--pasos 4]
// Credenciales: variables CLOUDFLARE_ACCOUNT_ID y CLOUDFLARE_API_TOKEN.
// Si no están y OmniRoute escucha en 127.0.0.1:20128, lo usa como alternativa.

import { writeFileSync, mkdirSync } from "node:fs";
import { dirname, resolve } from "node:path";

const MODELO = "@cf/black-forest-labs/flux-1-schnell";
const OMNIROUTE = "http://127.0.0.1:20128/v1/images/generations";

function leerArgs(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (!a.startsWith("--")) continue;
    const clave = a.slice(2);
    const valor = argv[i + 1] && !argv[i + 1].startsWith("--") ? argv[++i] : "true";
    args[clave] = valor;
  }
  return args;
}

function salir(mensaje) {
  console.error("ERROR: " + mensaje);
  process.exit(1);
}

// Fallo pasajero del servidor (409/5xx): se reintenta una vez.
class Pasajero extends Error {}
const esPasajero = (status) => status === 409 || status >= 500;

async function conReintento(fn) {
  try {
    return await fn();
  } catch (e) {
    if (!(e instanceof Pasajero)) throw e;
    await new Promise((r) => setTimeout(r, 3000));
    try {
      return await fn();
    } catch (e2) {
      salir(e2.message);
    }
  }
}

async function conCloudflare(prompt, pasos) {
  const cuenta = process.env.CLOUDFLARE_ACCOUNT_ID?.trim();
  const token = process.env.CLOUDFLARE_API_TOKEN?.trim();
  const url = `https://api.cloudflare.com/client/v4/accounts/${cuenta}/ai/run/${MODELO}`;
  const res = await fetch(url, {
    method: "POST",
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
    body: JSON.stringify({ prompt, steps: pasos }),
  });
  const datos = await res.json().catch(() => ({}));
  if (!res.ok || !datos?.result?.image) {
    const detalle = (datos.errors || []).map((e) => `${e.code}: ${e.message}`).join("; ");
    if (res.status === 401 || res.status === 403) {
      salir(`Cloudflare rechaza las claves (${res.status}). Vuelve a ejecutar "Guardar claves Cloudflare.cmd". ${detalle}`);
    }
    if (res.status === 429) salir("Has gastado la cuota gratis de hoy en Cloudflare. Vuelve a probar mañana.");
    const msg = `Cloudflare respondió ${res.status}. ${detalle || JSON.stringify(datos).slice(0, 300)}`;
    if (esPasajero(res.status)) throw new Pasajero(msg);
    salir(msg);
  }
  return Buffer.from(datos.result.image, "base64");
}

async function conOmniRoute(prompt) {
  const res = await fetch(OMNIROUTE, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ model: `cloudflare-ai/${MODELO}`, prompt, n: 1 }),
  });
  const datos = await res.json().catch(() => ({}));
  const b64 = datos?.data?.[0]?.b64_json;
  if (!res.ok || !b64) {
    const msg = `OmniRoute respondió ${res.status}: ${JSON.stringify(datos).slice(0, 300)}`;
    if (esPasajero(res.status)) throw new Pasajero(msg);
    salir(msg);
  }
  return Buffer.from(b64, "base64");
}

async function omniRouteDisponible() {
  try {
    const res = await fetch("http://127.0.0.1:20128/api/health", { signal: AbortSignal.timeout(2000) });
    return res.ok;
  } catch {
    return false;
  }
}

process.on("uncaughtException", (e) => salir(`No he podido conectar (${e.cause?.code || e.message}). ¿Hay internet?`));

const args = leerArgs(process.argv.slice(2));
const prompt = (args.prompt || "").trim();
if (!prompt || prompt === "true") salir('Falta el texto. Ejemplo: node generar.mjs --prompt "a glass water bottle"');

const pasos = Math.min(8, Math.max(1, parseInt(args.pasos || "4", 10) || 4));
const salida = resolve(args.salida && args.salida !== "true" ? args.salida : `imagen-${Date.now()}.jpg`);

let imagen;
if (process.env.CLOUDFLARE_ACCOUNT_ID && process.env.CLOUDFLARE_API_TOKEN) {
  imagen = await conReintento(() => conCloudflare(prompt, pasos));
} else if (await omniRouteDisponible()) {
  imagen = await conReintento(() => conOmniRoute(prompt));
} else {
  salir(
    "No encuentro las claves de Cloudflare (CLOUDFLARE_ACCOUNT_ID y CLOUDFLARE_API_TOKEN). " +
      'Ejecuta "Guardar claves Cloudflare.cmd" (ver README) y reinicia Claude.'
  );
}

mkdirSync(dirname(salida), { recursive: true });
writeFileSync(salida, imagen);
console.log(`OK ${salida} (${Math.round(imagen.length / 1024)} KB)`);
