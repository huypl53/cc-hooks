#!/usr/bin/env node
import { createServer } from "node:http";
import { readFileSync, writeFileSync, mkdirSync, readdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { randomUUID } from "node:crypto";

const __dirname = dirname(fileURLToPath(import.meta.url));
const PORT = parseInt(process.env.CC_HOOKS_PORT || "49152", 10);
const DATA_DIR = join(__dirname, "data");
mkdirSync(DATA_DIR, { recursive: true });

const sseClients = new Set();

function trimValue(val, maxLen = 120) {
  if (typeof val === "string") {
    if (val.length <= maxLen) return val;
    const headLen = Math.floor(maxLen * 0.65);
    const tailLen = maxLen - headLen - 3;
    return val.slice(0, headLen) + "..." + val.slice(-tailLen);
  }
  if (Array.isArray(val)) {
    if (val.length <= 3) return val.map((v) => trimValue(v, maxLen));
    return [
      ...val.slice(0, 2).map((v) => trimValue(v, maxLen)),
      `... +${val.length - 2} more`,
    ];
  }
  if (val && typeof val === "object") {
    return trimObject(val, maxLen);
  }
  return val;
}

function trimObject(obj, maxLen = 120, depth = 0) {
  if (depth > 3) return "{...}";
  const out = {};
  const keys = Object.keys(obj);
  for (const k of keys) {
    out[k] = trimValue(obj[k], maxLen);
  }
  return out;
}

function buildTrimmed(full) {
  return trimObject(full, 120, 0);
}

function broadcast(event) {
  const data = `data: ${JSON.stringify(event)}\n\n`;
  for (const res of sseClients) {
    res.write(data);
  }
}

function serveFile(res, filePath, contentType) {
  try {
    const content = readFileSync(filePath, "utf-8");
    res.writeHead(200, { "Content-Type": contentType });
    res.end(content);
  } catch {
    res.writeHead(404);
    res.end("Not found");
  }
}

function handleIngest(req, res) {
  let body = "";
  req.on("data", (chunk) => (body += chunk));
  req.on("end", () => {
    try {
      const payload = JSON.parse(body);
      const id = randomUUID();
      const ts = Date.now();
      const record = { id, ts, payload };
      writeFileSync(join(DATA_DIR, `${id}.json`), JSON.stringify(record, null, 2));
      const trimmed = { id, ts, payload: buildTrimmed(payload) };
      broadcast(trimmed);
      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ ok: true, id }));
    } catch (e) {
      res.writeHead(400);
      res.end(JSON.stringify({ error: e.message }));
    }
  });
}

function handleSSE(req, res) {
  res.writeHead(200, {
    "Content-Type": "text/event-stream",
    "Cache-Control": "no-cache",
    Connection: "keep-alive",
  });
  res.write(":\n\n");
  sseClients.add(res);
  req.on("close", () => sseClients.delete(res));
}

function handleDetail(res, id) {
  const filePath = join(DATA_DIR, `${id}.json`);
  try {
    const content = readFileSync(filePath, "utf-8");
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(content);
  } catch {
    res.writeHead(404);
    res.end(JSON.stringify({ error: "not found" }));
  }
}

function handleHistory(res, limit = 50) {
  try {
    const files = readdirSync(DATA_DIR).filter((f) => f.endsWith(".json"));
    const events = files.map((f) => {
      const record = JSON.parse(readFileSync(join(DATA_DIR, f), "utf-8"));
      return { id: record.id, ts: record.ts, payload: buildTrimmed(record.payload) };
    });
    events.sort((a, b) => a.ts - b.ts);
    const sliced = events.slice(-limit);
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify(sliced));
  } catch (e) {
    res.writeHead(500);
    res.end(JSON.stringify({ error: e.message }));
  }
}

const server = createServer((req, res) => {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET,POST,OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") {
    res.writeHead(204);
    return res.end();
  }

  const url = new URL(req.url, `http://localhost:${PORT}`);

  if (req.method === "POST" && url.pathname === "/ingest") {
    return handleIngest(req, res);
  }
  if (req.method === "GET" && url.pathname === "/events") {
    return handleSSE(req, res);
  }
  if (req.method === "GET" && url.pathname.startsWith("/detail/")) {
    const id = url.pathname.slice("/detail/".length);
    return handleDetail(res, id);
  }
  if (req.method === "GET" && url.pathname === "/history") {
    const limit = parseInt(url.searchParams.get("limit") || "50", 10);
    return handleHistory(res, limit);
  }
  if (req.method === "GET" && (url.pathname === "/" || url.pathname === "/index.html")) {
    return serveFile(res, join(__dirname, "ui.html"), "text/html");
  }

  res.writeHead(404);
  res.end("Not found");
});

server.listen(PORT, () => {
  console.log(`cc-hooks server listening on http://localhost:${PORT}`);
  console.log(`Data dir: ${DATA_DIR}`);
});
