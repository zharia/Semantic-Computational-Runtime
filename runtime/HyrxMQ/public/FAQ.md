# FAQ

## Is HyrxMQ a RabbitMQ fork?

No. It is a ground-up native Mojo implementation with RabbitMQ/AMQP interoperability as a compatibility goal.

## Does Hyrx require the simulation?

No.

## Can I embed Hyrx without running HyrxMQ?

Yes. That is a primary architectural goal.

## Is AMQP required internally?

No. AMQP is an external protocol adapter.

## Is TCP required?

No for Hyrx Core. TCP is the baseline HyrxMQ/AMQP interoperability transport.

## Will Hyrx support shared memory?

Potentially. It is an optimization candidate that must earn its complexity through benchmarks.

## Will HyrxMQ cluster?

Not initially. Single-node operation is a deliberate first scope.

## Why Linux only?

The project deliberately targets GNU/Linux and systemd so that Linux-native performance and operational facilities can be exploited without maintaining a cross-platform abstraction prematurely.
