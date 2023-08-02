upstream backend {
  server ${BACKEND_HOST}:${BACKEND_PORT} fail_timeout=0;
  keepalive 32;
}

limit_req_zone $binary_remote_addr zone=home:10m rate=100r/s;
limit_req_zone $binary_remote_addr zone=uploaded_images:10m rate=20r/s;
limit_req_zone $binary_remote_addr zone=search:10m rate=20r/s;

server {
    include /etc/nginx/includes/errors/json-errors.conf;
    include /etc/nginx/includes/web_performance/compression.conf;
    include /etc/nginx/includes/web_performance/cache-file-descriptors.conf;
    include /etc/nginx/includes/web_performance/no-transform.conf;

    listen                  80;
    server_name             localhost;
    client_max_body_size    4G;
    keepalive_timeout       10;

    # extra headers
    proxy_pass_header                       Server;
    add_header Server                       Apache/2.4.1;

    # ip tweaks
    real_ip_header      X-Forwarded-For;
    real_ip_recursive   on;

    # Logging
    charset     utf-8;
    access_log  /dev/stdout     ${LOG_FORMAT};
    error_log   /dev/stderr     notice;

    error_page 422 429 500 502 503 504 /500.html;

    location = /500.html {
            root /etc/nginx/errors;
            internal;
    }

    error_page 404 /404.html;
    location = /404.html {
            root /etc/nginx/errors;
            internal;
    }

    location @backend {
        proxy_set_header    Connection "Keep-Alive";
        proxy_set_header    Proxy-Connection "Keep-Alive";
        proxy_set_header    X-Real-IP $remote_addr;
        proxy_set_header    X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header    X-Forwarded-Proto $scheme;
        proxy_set_header    X-Forwarded-Host $http_host;
        proxy_set_header    X-Forwarded-Ssl on;
        proxy_set_header    Host $http_host;

        proxy_http_version    1.1;
        proxy_redirect        off;
        proxy_read_timeout  1200s;

        proxy_pass  http://backend;
    }

    location ~ ^/(assets|images|javascripts|stylesheets|swfs|system)/   {
        try_files $uri @backend;
        access_log off;
        gzip_static on;

        expires 7d;
        add_header Cache-Control public;

        add_header Last-Modified "";
        add_header ETag "";
        # break;
    }

    location  ~ ^/uploaded_images {
        try_files $uri @backend;
    }

    location ~ ^/searches {
        try_files $uri @backend;
    }

    # App proxy pass
    location / {
        try_files $uri @backend;
    }

    location /metrics {
        try_files $uri @backend;
    }
}