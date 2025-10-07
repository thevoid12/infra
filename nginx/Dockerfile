FROM nginx:1.25-alpine

# Use apk (alpine) to keep image small
RUN apk add --no-cache \
    certbot \
    certbot-nginx \
    bash \
    openssl \
    curl \
    jq

# Create directories (will be mounted from host in compose)
RUN mkdir -p /etc/nginx/conf.d /var/www/certbot /etc/letsencrypt /var/log/nginx

# Generate DH params for SSL
RUN openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048

COPY ./conf.d/nginx.conf /etc/nginx/nginx.conf
COPY issue_certs.sh /issue_certs.sh
RUN chmod +x /issue_certs.sh

EXPOSE 80 443

ENTRYPOINT ["/issue_certs.sh"]
CMD ["nginx", "-g", "daemon off;"]
