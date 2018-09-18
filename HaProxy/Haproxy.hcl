global
        log /dev/log    local0
        log /dev/log    local1 notice
        chroot /var/lib/haproxy

# keeping the two below unindented makes it easier to automate 
# commenting and uncommenting the lines

# used for standard installs
#stats socket /run/haproxy/admin.sock mode 660 level admin

# used for newer reload mechanism
stats socket /run/haproxy/admin.sock mode 777 level admin expose-fd listeners

        stats timeout 30s
        user haproxy
        group haproxy
        daemon
        maxconn 2000
        tune.ssl.default-dh-param   2048
        ssl-default-bind-ciphers    ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:RSA+AESGCM:RSA+AES:!aNULL:!MD5:!DSS
        ssl-default-bind-options    no-sslv3 no-tlsv10

        # Default SSL material locations
        ca-base /etc/ssl/certs
        crt-base /etc/ssl/private


defaults
        log     global
        mode    http
        retries 3
        option http-keep-alive
        option  httplog
        option  dontlognull
        option forwardfor
        option http-server-close
        timeout connect 5000
        timeout client  50000
        timeout server  50000
        errorfile 400 /etc/haproxy/errors/400.http
        errorfile 403 /etc/haproxy/errors/403.http
        errorfile 408 /etc/haproxy/errors/408.http
        errorfile 500 /etc/haproxy/errors/500.http
        errorfile 502 /etc/haproxy/errors/502.http
        errorfile 503 /etc/haproxy/errors/503.http
        errorfile 504 /etc/haproxy/errors/504.http
        log-format %ci:%cp\ [%t]\ %ft\ %b/%s\ %Tq/%Tw/%Tc/%Tr/%Tt\ %ST\ %B\ %CC\ %CS\ %tsc\ %ac/%fc/%bc/%sc/%rc\ %sq/%bq\ %hr\ %hs\ %{+Q}r

#------------------
# internal statistics
#------------------
listen stats
    bind 0.0.0.0:8998
    mode http
    stats auth Admin:password
    stats enable
    stats realm Haproxy\ Statistics
    stats refresh 20s
    stats uri /admin?stats

#------------------
# frontend instances
#------------------
frontend unsecured
    bind        *:80
    reqadd      X-Forwarded-Proto:\ https
    redirect    scheme https code 301 if !{ ssl_fc }
    default_backend www-backend

frontend www-https
    bind        *:443 ssl crt /etc/pki/tls/certs/REPLACEME.pem
    # passing on that browser is using https
    reqadd X-Forwarded-Proto:\ https
    # for Clickjacking
    rspadd X-Frame-Options:\ SAMEORIGIN
    # prevent browser from using non-secure
    rspadd Strict-Transport-Security:\ max-age=15768000
    default_backend www-backend


#------------------
# backend instances
#------------------
backend www-backend
    balance roundrobin
    #cookie WWWID insert indirect nocache
    #redirect scheme https if !{ ssl_fc }
    server mypool1 127.0.0.1:9000
    server mypool2 127.0.0.1:9001
    server mypool3 127.0.0.1:9002
    #server mypool3 127.0.0.1:8080 cookie www3 check inter 3000
