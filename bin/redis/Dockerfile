FROM redis:latest

# Copy the Redis configuration file to the container
COPY redis.conf /usr/local/etc/redis/redis.conf

ARG REDIS_PASSWORD

# Replace the default Redis password with an environment variable
RUN sed -i "s|requirepass password|requirepass ${REDIS_PASSWORD}|" /usr/local/etc/redis/redis.conf

CMD ["redis-server", "/usr/local/etc/redis/redis.conf"]

