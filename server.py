"""HTTP server that serves the Flutter web build AND proxies API requests
to the Plane backend, solving CORS issues for web app testing."""

import http.server
import http.client
import json
import os
import ssl

BUILD_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'build', 'web')
API_PATH_PREFIX = '/api/'
CORS_HEADERS = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'X-Api-Key, Content-Type, Authorization, X-Plane-Base-Url',
    'Access-Control-Max-Age': '86400',
}

# Track the Plane server base URL (set when user configures in app)
plane_base_url = None


class ProxyHandler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {
        **http.server.SimpleHTTPRequestHandler.extensions_map,
        '.js': 'application/javascript',
        '.wasm': 'application/wasm',
        '.json': 'application/json',
        '.mjs': 'application/javascript',
    }

    def do_OPTIONS(self):
        """Handle CORS preflight requests."""
        self.send_response(204)
        self.end_headers()

    def do_GET(self):
        if self.path.startswith(API_PATH_PREFIX):
            self._proxy_request('GET')
        else:
            super().do_GET()

    def do_POST(self):
        if self.path.startswith(API_PATH_PREFIX):
            self._proxy_request('POST')
        else:
            super().do_POST()

    def do_PUT(self):
        if self.path.startswith(API_PATH_PREFIX):
            self._proxy_request('PUT')
        else:
            super().do_PUT()

    def do_PATCH(self):
        if self.path.startswith(API_PATH_PREFIX):
            self._proxy_request('PATCH')
        else:
            super().do_PATCH()

    def do_DELETE(self):
        if self.path.startswith(API_PATH_PREFIX):
            self._proxy_request('DELETE')
        else:
            super().do_DELETE()

    def _proxy_request(self, method):
        """Proxy API requests to the Plane backend using http.client
        which preserves header case and avoids Cloudflare bot detection."""
        global plane_base_url

        # Capture X-Plane-Base-Url from the request
        x_plane_url = self.headers.get('X-Plane-Base-Url')
        if x_plane_url:
            plane_base_url = x_plane_url.rstrip('/')
            print(f'[PROXY] Captured Plane base URL: {plane_base_url}', flush=True)

        if not plane_base_url:
            self.send_response(502)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({
                'error': 'No Plane server configured yet. '
                         'Enter your server URL and API token, then click Test Connection first.'
            }).encode())
            return

        # Parse the target URL
        target_url = f"{plane_base_url.rstrip('/')}{self.path}"
        from urllib.parse import urlparse
        parsed = urlparse(target_url)

        # Read request body if present
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length) if content_length > 0 else None

        # Build headers - forward auth and content headers with proper casing
        forward_headers = {
            'X-Api-Key': self.headers.get('X-Api-Key', ''),
            'Content-Type': self.headers.get('Content-Type', 'application/json'),
            'Accept': 'application/json',
            'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
            'Origin': plane_base_url,
            'Referer': f'{plane_base_url}/',
        }

        try:
            ctx = ssl.create_default_context()
            if parsed.scheme == 'https':
                conn = http.client.HTTPSConnection(
                    parsed.hostname,
                    parsed.port or 443,
                    timeout=30,
                    context=ctx,
                )
            else:
                conn = http.client.HTTPSConnection(
                    parsed.hostname,
                    parsed.port or 80,
                    timeout=30,
                )

            # Build the path with query string
            path = parsed.path
            if parsed.query:
                path += f'?{parsed.query}'

            conn.request(method, path, body=body, headers=forward_headers)
            resp = conn.getresponse()
            resp_body = resp.read()

            self.send_response(resp.status)
            # Forward relevant response headers
            for key, val in resp.getheaders():
                lower = key.lower()
                if lower in ('content-type', 'content-length', 'content-encoding'):
                    self.send_header(key, val)
            self.end_headers()
            self.wfile.write(resp_body)
            conn.close()

        except Exception as e:
            print(f'[PROXY] Error: {e}', flush=True)
            self.send_response(502)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'error': str(e), 'detail': 'Proxy failed to reach Plane backend'}).encode())

    def end_headers(self):
        # Add CORS headers to ALL responses (static files + proxied)
        for k, v in CORS_HEADERS.items():
            self.send_header(k, v)
        super().end_headers()

    def translate_path(self, path):
        """Serve static files from the build/web directory."""
        if path.startswith(API_PATH_PREFIX):
            return super().translate_path(path)
        # Strip query string and serve from BUILD_DIR
        path = path.split('?', 1)[0]
        path = path.split('#', 1)[0]
        rel_path = os.path.normpath(path).lstrip('/')
        return os.path.join(BUILD_DIR, rel_path)


if __name__ == '__main__':
    port = 8080
    os.chdir(BUILD_DIR)
    server = http.server.HTTPServer(('0.0.0.0', port), ProxyHandler)
    print(f'Server running on port {port}', flush=True)
    print(f'Serving static files from: {BUILD_DIR}', flush=True)
    print(f'Proxying /api/* requests to configured Plane backend', flush=True)
    server.serve_forever()