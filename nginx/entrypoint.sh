set -e

envsubst '${BACKEND_HOST} ${BACKEND_PORT} ${LOG_FORMAT}' < /etc/nginx/conf.d/default.tpl > /etc/nginx/conf.d/default.conf
service nginx start
echo 'Nginx started!'
