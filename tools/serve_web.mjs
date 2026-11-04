import { createServer } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import { resolve, extname, sep } from 'node:path';
const root = resolve('apps/backoffice/build/web');
const mime = { '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json',
  '.css': 'text/css', '.png': 'image/png', '.ico': 'image/x-icon', '.wasm': 'application/wasm',
  '.svg': 'image/svg+xml' };
createServer(async (req, res) => {
  try {
    const pathname = decodeURIComponent(new URL(req.url, 'http://127.0.0.1').pathname);
    let file = resolve(root, `.${pathname}`);
    if (file !== root && !file.startsWith(root + sep)) {
      res.writeHead(403).end(); return;
    }
    if ((await stat(file)).isDirectory()) file = resolve(file, 'index.html');
    const data = await readFile(file);
    res.writeHead(200, { 'Content-Type': mime[extname(file)] ?? 'application/octet-stream',
      'Cache-Control': 'no-store' });
    res.end(data);
  } catch { res.writeHead(404).end('Not found'); }
}).listen(5173, '127.0.0.1', () => console.log('Frizeraj: http://127.0.0.1:5173'));
