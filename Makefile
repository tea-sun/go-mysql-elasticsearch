all: build

build: build-linux build-mac

build-linux:
	GO111MODULE=on GOOS=linux GOARCH=amd64 go build -o bin/river-linux ./cmd/go-mysql-elasticsearch

build-mac:
	GO111MODULE=on GOOS=darwin GOARCH=amd64 go build -o bin/river-macos ./cmd/go-mysql-elasticsearch

test:
	GO111MODULE=on go test -timeout 1m --race ./...

clean:
	GO111MODULE=on go clean -i ./...
	@rm -rf bin