ARG GO_VERSION=1.21

FROM golang:${GO_VERSION}-alpine as base

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
    GOOS=$TARGETOS GOARCH=$TARGETARCH go build -v -o /bin/go-mysql-elasticsearch ./cmd/go-mysql-elasticsearch

FROM scratch as binary
COPY --from=build /bin/go-mysql-elasticsearch .

FROM ubuntu:22.04 as prod

# 安装mysql客户端
RUN apt update && \
    apt install -y mysql-client=8.0.* && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 挂载配置目录
VOLUME /app/

# 从build阶段拷贝go程序
COPY --from=build /bin/go-mysql-elasticsearch /bin
# 从build阶段拷贝配置
COPY --from=build /src/etc/river.toml ./etc/

ENTRYPOINT ["/bin/go-mysql-elasticsearch"]
