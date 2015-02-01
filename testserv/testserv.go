// piserver project piserver.go
package main

import (
	"log"
	"net/http"

	"github.com/gorilla/websocket"
)

const (
	TIMEOUT = 3
)

func main() {

	http.HandleFunc("/device", device)
	http.ListenAndServe(":8080", nil)
}

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin:     func(r *http.Request) bool { return true },
}

func showErr(err error) {
	if err != nil {
		log.Printf("err:%v\n", err)
	}
}

func device(resp http.ResponseWriter, req *http.Request) {
	var err error
	var clientConn *websocket.Conn
	clientConn, err = upgrader.Upgrade(resp, req, nil)
	if err != nil {
		showErr(err)
		return
	}

	log.Printf("client connected: %v\n", clientConn.RemoteAddr().String())

	clientConn.WriteMessage(websocket.TextMessage, []byte("test"))
	for {

		_, tmp, err := clientConn.ReadMessage()
		if err != nil {
			log.Println("client closed")
			break
		}
		log.Printf("read from client, msg: %v\n", string(tmp))
	}
}
