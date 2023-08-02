FROM nginx:1.23.2

# nginx conf
RUN mkdir -p /etc/nginx/includes
COPY entrypoint.sh /etc/nginx/entrypoint.sh
COPY conf.d/* /etc/nginx/conf.d/
COPY includes /etc/nginx/includes
COPY errors /etc/nginx/errors

# run
WORKDIR /etc/nginx/
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
RUN chmod +x ./entrypoint.sh
CMD ./entrypoint.sh
