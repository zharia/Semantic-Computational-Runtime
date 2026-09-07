# Migration from RabbitMQ

HyrxMQ should provide a migration path based on application semantics rather than RabbitMQ implementation details.

## Migration process

1. inventory RabbitMQ features actually used
2. map them to the HyrxMQ compatibility matrix
3. identify RabbitMQ extensions in use
4. test topology declarations
5. test publish/consume behavior
6. test acknowledgement/recovery behavior
7. test TLS/authentication
8. benchmark under representative workloads
9. run failure/recovery tests
10. switch production traffic only after acceptance criteria pass

## Important

Do not assume that because two systems speak AMQP 0-9-1 they have identical operational behavior.

The compatibility matrix is authoritative.
