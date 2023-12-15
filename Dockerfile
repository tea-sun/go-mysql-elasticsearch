FROM golang:1.21-alpine as builder

# 配置go代理
ENV GOPROXY=https://goproxy.cn

WORKDIR /opt/go-mysql-elasticsearch

# pre-copy/cache go.mod for pre-downloading dependencies and only redownloading them in subsequent builds if they change
COPY go.mod go.sum ./
RUN go mod download -x && go mod verify

ADD . .

# 编译go程序
RUN go build -v -ldflags "-s -w" -o bin/go-mysql-elasticsearch ./cmd/go-mysql-elasticsearch

FROM mysql:latest as prod

WORKDIR /root/

# 挂载配置目录
VOLUME /root/etc

# 从builder阶段拷贝go程序
COPY --from=builder /opt/go-mysql-elasticsearch/bin .
# 从builder阶段拷贝配置
COPY --from=builder /opt/go-mysql-elasticsearch/etc ./etc

ENTRYPOINT ["./go-mysql-elasticsearch"]

# 清理none镜像 docker rmi $(docker images -f dangling=true -q)
