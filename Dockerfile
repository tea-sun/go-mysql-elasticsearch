ARG GO_VERSION=1.21
ARG MYSQL_VERSION=8.0.35

FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine as base

# 配置go代理
ENV GOPROXY=https://goproxy.cn

WORKDIR /src

COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download -x

FROM base AS build

ARG TARGETOS
ARG TARGETARCH

COPY . .

# 编译go程序
RUN --mount=type=cache,target=/go/pkg/mod \
#    --mount=type=bind,target=. \
    GOOS=$TARGETOS GOARCH=$TARGETARCH go build -v -o /bin/go-mysql-elasticsearch ./cmd/go-mysql-elasticsearch

FROM scratch as binary
COPY --from=build /bin/go-mysql-elasticsearch .


FROM --platform=$TARGETPLATFORM  mysql:${MYSQL_VERSION} as prod

WORKDIR /app

# 挂载配置目录
VOLUME /app/

# 从build阶段拷贝go程序
COPY --from=build /bin/go-mysql-elasticsearch /bin
# 从build阶段拷贝配置
COPY --from=build /src/etc/river.toml ./etc/

ENTRYPOINT ["/bin/go-mysql-elasticsearch"]
