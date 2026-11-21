FROM dart:3.13.5 AS build
WORKDIR /src
COPY pubspec.lock .
COPY apps/server/ apps/server/
COPY packages/ packages/
RUN printf 'name: frizeraj_server_workspace\npublish_to: none\nenvironment:\n  sdk: ^3.13.5\nworkspace:\n  - apps/server\n  - packages/domain\n  - packages/use_cases\n  - packages/api_contract\n  - packages/api_mapping\n' > pubspec.yaml \
    && dart pub get \
    && mkdir -p /out \
    && dart compile exe apps/server/bin/server.dart -o /out/server
FROM scratch
COPY --from=build /runtime/ /
WORKDIR /app
COPY --from=build /out/server ./server
COPY --from=build /src/apps/server/sql ./sql
USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["/app/server"]
