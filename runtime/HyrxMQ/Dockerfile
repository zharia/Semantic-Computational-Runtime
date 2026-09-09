FROM scratch

# Self-contained HyrxMQ runtime. No distro libs are used: the binary's full
# dynamic-link closure (loader + glibc + libstdc++/libgcc + Mojo/KGEN runtime
# .so's) is bundled under /app/lib (+ /lib64 loader), so the image runs
# identically on any Docker host regardless of its glibc.

COPY dist/rootfs/ /

ENV LD_LIBRARY_PATH=/app/lib
ENV HYRXMQ_HOST=0.0.0.0
ENV HYRXMQ_PORT=5672
EXPOSE 5672

# run as unprivileged uid (no /etc/passwd in scratch; numeric is fine)
USER 65534
ENTRYPOINT ["/app/hyrxmq-listen"]
