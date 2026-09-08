docker run -d \
  --name node-rabbitmq \
  --hostname rabbit-node \
  -p 5672:5672 \
  -p 15672:15672 \
  -e RABBITMQ_DEFAULT_USER=admin \
  -e RABBITMQ_DEFAULT_PASS=password \
  -v rabbitmq_data:/var/lib/rabbitmq \
  rabbitmq:4-management
