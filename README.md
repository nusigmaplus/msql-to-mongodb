# cdc-sql-server-mongo

This project uses Quarkus, the Supersonic Subatomic Java Framework.

If you want to learn more about Quarkus, please visit its website: <https://quarkus.io/>.

## Running the application in dev mode

You can run your application in dev mode that enables live coding using:

```shell script
./mvnw quarkus:dev
```

> **_NOTE:_**  Quarkus now ships with a Dev UI, which is available in dev mode only at <http://localhost:8080/q/dev/>.

## Packaging and running the application

The application can be packaged using:

```shell script
./mvnw package
```

It produces the `quarkus-run.jar` file in the `target/quarkus-app/` directory.
Be aware that it’s not an _über-jar_ as the dependencies are copied into the `target/quarkus-app/lib/` directory.

The application is now runnable using `java -jar target/quarkus-app/quarkus-run.jar`.

If you want to build an _über-jar_, execute the following command:

```shell script
./mvnw package -Dquarkus.package.jar.type=uber-jar
```

The application, packaged as an _über-jar_, is now runnable using `java -jar target/*-runner.jar`.

## Creating a native executable

You can create a native executable using:

```shell script
./mvnw package -Dnative
```

Or, if you don't have GraalVM installed, you can run the native executable build in a container using:

```shell script
./mvnw package -Dnative -Dquarkus.native.container-build=true
```

You can then execute your native executable with: `./target/cdc-sql-server-mongo-1.0.0-SNAPSHOT-runner`

If you want to learn more about building native executables, please consult <https://quarkus.io/guides/maven-tooling>.

## Related Guides

- MongoDB client ([guide](https://quarkus.io/guides/mongodb)): Connect to MongoDB in either imperative or reactive style
- Camel Core ([guide](https://docs.redhat.com/en/documentation/red_hat_build_of_apache_camel/4.10/html-single/red_hat_build_of_apache_camel_for_quarkus_reference/camel-quarkus-extensions-reference#extensions-core)): Camel core functionality and basic Camel languages: Constant, ExchangeProperty, Header, Ref, Simple and Tokenize
- Camel Kafka ([guide](https://docs.redhat.com/en/documentation/red_hat_build_of_apache_camel/4.10/html-single/red_hat_build_of_apache_camel_for_quarkus_reference/camel-quarkus-extensions-reference#extensions-kafka)): Sent and receive messages to/from an Apache Kafka broker
- Camel YAML DSL ([guide](https://docs.redhat.com/en/documentation/red_hat_build_of_apache_camel/4.10/html-single/red_hat_build_of_apache_camel_for_quarkus_reference/camel-quarkus-extensions-reference#extensions-yaml-dsl)): An YAML stack for parsing YAML route definitions
- Camel MongoDB ([guide](https://docs.redhat.com/en/documentation/red_hat_build_of_apache_camel/4.10/html-single/red_hat_build_of_apache_camel_for_quarkus_reference/camel-quarkus-extensions-reference#extensions-mongodb)): Perform operations on MongoDB documents and collections
- Camel Jackson ([guide](https://docs.redhat.com/en/documentation/red_hat_build_of_apache_camel/4.10/html-single/red_hat_build_of_apache_camel_for_quarkus_reference/camel-quarkus-extensions-reference#extensions-jackson)): Marshal POJOs to JSON and back using Jackson
