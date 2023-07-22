FROM rust:latest as builder

WORKDIR /repo
COPY ./ .

RUN cargo build --release

FROM ubuntu:latest

RUN apt-get update -y && apt-get install -y ca-certificates fuse3 sqlite3
COPY --from=flyio/litefs:0.5 /usr/local/bin/litefs /usr/local/bin/litefs
COPY --from=builder /repo/target/release/litefs-proxy-error /usr/local/bin/litefs-proxy-error 
COPY litefs.yml /etc/litefs.yml
CMD ["litefs", "mount", "--", "litefs-proxy-error"]
