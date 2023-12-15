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

FROM alpine:3.19 as prod

WORKDIR /root/

# 安装mysqldump
# mariadb-client中的mysqldump有兼容性问题
# mysqldump: Couldn't execute 'SET SQL_QUOTE_SHOW_CREATE=1/*!40102 ,SQL_MODE=concat(@@sql_mode, _utf8 ',NO_KEY_OPTIONS,NO_TABLE_OPTIONS,NO_FIELD_OPTIONS') */': Variable 'sql_mode' can't be set to the value of 'NO_KEY_OPTIONS' (1231)
# 建议 使用 msyql镜像
RUN apk --no-cache add ca-certificates mariadb-client mariadb-connector-c

# 从builder阶段拷贝go程序
COPY --from=builder /opt/go-mysql-elasticsearch/bin .
# 从builder阶段拷贝配置
COPY --from=builder /opt/go-mysql-elasticsearch/etc ./etc

ENTRYPOINT ["./go-mysql-elasticsearch"]

# 清理none镜像 docker rmi $(docker images -f dangling=true -q)
