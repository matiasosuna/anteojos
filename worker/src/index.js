// Recibe una foto de los anteojos y devuelve una descripción corta hecha por Gemini.
// POST /describir  (body: image/jpeg, header Authorization: Bearer <APP_TOKEN>)

// Primero el rápido: con los anteojos importa la demora. El 3.8 en plan gratis tarda mucho.
const MODELOS = ["gemini-2.5-flash", "gemini-2.5-flash-lite", "gemini-3.8-flash"];
const PROMPT =
  "Esta foto la sacaron unos anteojos inteligentes desde los ojos de quien los usa. " +
  "Decí en una o dos frases cortas qué tiene delante, en español rioplatense neutro " +
  "(voseo, tono natural, sin lunfardo ni exagerar). " +
  "Si hay texto en otro idioma, traducilo. Sin markdown: se va a leer en voz alta.";

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.method !== "POST" || url.pathname !== "/describir") {
      return json({ error: "no encontrado" }, 404);
    }
    if (request.headers.get("Authorization") !== `Bearer ${env.APP_TOKEN}`) {
      return json({ error: "no autorizado" }, 401);
    }

    const bytes = new Uint8Array(await request.arrayBuffer());
    if (bytes.length === 0 || bytes.length > 8_000_000) {
      return json({ error: "foto vacía o muy grande" }, 400);
    }
    const foto = base64(bytes);

    for (const modelo of MODELOS) {
      try {
        const texto = await describir(modelo, foto, env.GEMINI_API_KEY);
        if (texto) return json({ texto, modelo });
      } catch (e) {
        console.log(`${modelo} falló: ${e.message}`);
      }
    }
    return json({ error: "Gemini no respondió, probá de nuevo en un rato" }, 503);
  },
};

async function describir(modelo, foto, clave) {
  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${modelo}:generateContent`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-goog-api-key": clave },
      body: JSON.stringify({
        contents: [
          {
            parts: [
              { inline_data: { mime_type: "image/jpeg", data: foto } },
              { text: PROMPT },
            ],
          },
        ],
        // Sin "pensar" en los 2.5: responde en pocos segundos.
        ...(modelo.startsWith("gemini-2.5")
          ? { generationConfig: { thinkingConfig: { thinkingBudget: 0 } } }
          : {}),
      }),
      signal: AbortSignal.timeout(20_000),
    }
  );
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  const data = await res.json();
  return data.candidates?.[0]?.content?.parts?.map((p) => p.text ?? "").join("").trim();
}

function base64(bytes) {
  let s = "";
  for (let i = 0; i < bytes.length; i += 0x8000) {
    s += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  }
  return btoa(s);
}

function json(obj, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8" },
  });
}
