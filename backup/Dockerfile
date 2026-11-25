FROM restic/restic:0.20.0 AS restic

FROM postgres:18
RUN apt-get update -qq &&     apt-get install --no-install-recommends -y ca-certificates curl &&     rm -rf /var/lib/apt/lists
ADD --chmod=755 --checksum=sha256:cc232108374e8e2b537045f2d5eaa1229f619db314c3ba6a14d38b35dc0aa123     https://github.com/aptible/supercronic/releases/download/v0.2.51/supercronic-linux-amd64 /usr/local/bin/supercronic
COPY --from=restic /usr/bin/restic /usr/local/bin/restic
COPY crontab /etc/backup.crontab
COPY --chmod=755 backup /usr/local/bin/backup
ENTRYPOINT []
CMD ["supercronic", "/etc/backup.crontab"]
