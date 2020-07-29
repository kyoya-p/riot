#
# sudo docker build -t kyoyap/riot .
# sudo docker run -p 8180:80 kyoyap/nginx
#


FROM kyoyap/riot-img as source

FROM alpine as deploy

RUN apk add --update --no-cache nginx
COPY --from=source /www /www/

# nginx config
RUN echo "\
server { \
       listen 80; \
       root /www ; \
       autoindex on; \
       autoindex_exact_size off; \
       autoindex_localtime on; \
} \
" > /etc/nginx/conf.d/default.conf

CMD /usr/sbin/nginx -g 'pid /tmp/nginx.pid; daemon off;' -c /etc/nginx/nginx.conf

# nginx: http://nginx.org/en/docs/
