# ---------------------------------------------------------------------------
# Production Postgres image with pgBackRest built in.
#
# archive_command on the Postgres side needs the pgbackrest binary locally to
# push WALs to the S3 repo, and scheduled backups/restores run `pgbackrest`
# inside this same container (it needs direct filesystem access to PGDATA).
# ---------------------------------------------------------------------------

FROM postgres:16-alpine

RUN apk add --no-cache pgbackrest \
    && mkdir -p /etc/pgbackrest /var/log/pgbackrest \
                /var/lib/pgbackrest/lock /var/lib/pgbackrest/spool \
    && chown -R postgres:postgres /etc/pgbackrest /var/log/pgbackrest /var/lib/pgbackrest

COPY pgbackrest.conf /etc/pgbackrest/pgbackrest.conf.template
COPY pg-entrypoint.sh /usr/local/bin/pg-entrypoint.sh
RUN chmod +x /usr/local/bin/pg-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/pg-entrypoint.sh"]
CMD ["postgres"]
