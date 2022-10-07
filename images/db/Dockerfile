FROM mariadb:10.5.2

ENV MYSQL_DATABASE=simple-website \
    MYSQL_ROOT_PASSWORD=1234

ADD database.sql /docker-entrypoint-initdb.d

EXPOSE 3306
