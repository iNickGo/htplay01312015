package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sync"

	"code.google.com/p/go-uuid/uuid"
	remotews "code.google.com/p/go.net/websocket"
	"github.com/gorilla/websocket"
)

const (
	IMG_TYPE_STREAMING = 0
	IMG_TYPE_SNAPSHOT  = 1
)

type Login struct {
	Cmd  string `json:"cmd"`
	Name string `json:"name"`
}

type UploadImg struct {
	Cmd  string `json:"cmd"`
	Data string `json:"data"` // base 64 encoded image data
}

type RequestImg struct {
	Cmd string `json:"cmd"`
}

type UploadImgToRemote struct {
	Cmd     string `json:"cmd"`
	ImgData string `json:"imgData"`
	Name    string `json:"camID"`
}

type DeviceServer struct {
	Devices map[string]*websocket.Conn
	M       sync.Mutex

	RemoteConn *remotews.Conn
}

func LaunghDeviceServer(port int) {
	gDeviceServer.Devices = make(map[string]*websocket.Conn)

	addr := fmt.Sprintf(":%d", port)

	http.HandleFunc("/device", deviceEntry)
	err := http.ListenAndServe(addr, nil)
	if err != nil {
		fmt.Printf("server started fail %v\n", err)
	}
}

func deviceEntry(resp http.ResponseWriter, req *http.Request) {
	log.Println("device connected")
	var err error
	var clientConn *websocket.Conn
	clientConn, err = upgrader.Upgrade(resp, req, nil)
	if err != nil {
		showErr(err)
		return
	}

	log.Printf("client connected: %v\n", clientConn.RemoteAddr().String())
	name := uuid.New()

	for {
		_, tmp, err := clientConn.ReadMessage()
		if err != nil {
			log.Println("client closed")
			gDeviceServer.clearDevice(clientConn)
			break
		}

		//log.Printf("read from client, msg: %v\n", string(tmp))

		gDeviceServer.HandleCmd(name, clientConn, tmp)
	}
}
func (this *DeviceServer) requestCameasImg() {
	this.M.Lock()
	defer this.M.Unlock()

	req := RequestImg{Cmd: "requestImg"}
	data, _ := json.Marshal(req)
	for _, v := range gDeviceServer.Devices {
		if v != nil {
			v.WriteMessage(websocket.TextMessage, data)
		}
	}
}
func (this *DeviceServer) clearDevice(conn *websocket.Conn) {
	gDeviceServer.M.Lock()
	defer gDeviceServer.M.Unlock()

	for k, v := range gDeviceServer.Devices {
		if v == conn {
			delete(gDeviceServer.Devices, k)
			break
		}
	}
}

func (this *DeviceServer) HandleCmd(name string, conn *websocket.Conn, tmp []byte) {
	req := make(map[string]interface{})
	json.Unmarshal(tmp, &req)

	cmd, ok := req["cmd"].(string)

	if !ok {
		log.Printf("cmd not found: %v\n", cmd)
		return
	}

	fmt.Printf("read cmd: %v\n", cmd)

	switch cmd {
	case "login":
		this.Login(name, conn, tmp)
	case "uploadImg":
		this.uploadImg(name, conn, tmp, IMG_TYPE_STREAMING)
	}
}

func (this *DeviceServer) requestStreaming(conn *websocket.Conn) {
	req := &RequestImg{Cmd: "requestImg"}
	data, _ := json.Marshal(req)
	conn.WriteMessage(websocket.TextMessage, data)
}
func (this *DeviceServer) Login(name string, conn *websocket.Conn, data []byte) {
	gDeviceServer.M.Lock()
	defer gDeviceServer.M.Unlock()

	req := &Login{}
	json.Unmarshal(data, req)

	//server assign a random name to client
	req.Name = name
	gDeviceServer.Devices[req.Name] = conn
}

func (this *DeviceServer) uploadImg(name string, conn *websocket.Conn, data []byte, imgType int) {
	var err error
	if this.RemoteConn == nil {
		log.Printf("remote server not connected")
		return
	}

	req := &UploadImg{}
	err = json.Unmarshal(data, req)

	if err != nil {
		return
	}

	//send cmd to remote server
	var msg *UploadImgToRemote
	if imgType == IMG_TYPE_STREAMING {
		msg = &UploadImgToRemote{Cmd: "Img", ImgData: req.Data, Name: name}
	}

	remoteData, _ := json.Marshal(msg)

	_, err = this.RemoteConn.Write(remoteData)
	if err != nil {
		log.Printf("send to remote server error: %v\n", err)
	}
}

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin:     func(r *http.Request) bool { return true },
}
