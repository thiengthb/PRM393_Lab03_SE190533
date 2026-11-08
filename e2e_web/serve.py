"""Server tĩnh có SPA fallback cho các bản web dựng sẵn (thư mục e2e-builds).

Dùng: python3 serve.py <thư mục e2e-builds>
Cổng: giảng viên 5001, sinh viên 5002, admin 5003, giáo vụ 5004.
"""
import functools
import http.server
import os
import sys
import threading

PORTS = {'lecturer': 5001, 'student': 5002, 'admin': 5003, 'giaovu': 5004}


class SpaHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def send_head(self):
        path = self.translate_path(self.path)
        if not os.path.exists(path) or (os.path.isdir(path) and not os.path.exists(os.path.join(path, 'index.html'))):
            self.path = '/index.html'
        return super().send_head()


def main(root):
    servers = []
    for name, port in PORTS.items():
        handler = functools.partial(SpaHandler, directory=os.path.join(root, name))
        srv = http.server.ThreadingHTTPServer(('127.0.0.1', port), handler)
        threading.Thread(target=srv.serve_forever, daemon=True).start()
        servers.append(srv)
        print(f'{name}: http://localhost:{port}', flush=True)
    threading.Event().wait()


if __name__ == '__main__':
    main(sys.argv[1])
