// htplay201501 project htplay201501.go
package main

import (
	"flag"
	"fmt"
	"io"
	"log"
	"runtime"
	"time"

	"github.com/tarm/goserial"

	"code.google.com/p/go.net/websocket"
)

var sio io.ReadWriteCloser
var serialConnected bool
var gDeviceServer DeviceServer
var gPirNotification chan bool

var debug bool = true

const (
	RECONN_TIMEOUT = 10
)

func main() {
	runtime.GOMAXPROCS(runtime.NumCPU())
	defer unexpectedError()

	var err error
	var remoteIP string
	var remotePort int
	var comPort string
	var localServerPort int

	gPirNotification = make(chan bool)

	flag.StringVar(&remoteIP, "ip", "127.0.0.1", "remote server ip")
	flag.IntVar(&remotePort, "port", 8080, "remote server port")
	flag.StringVar(&comPort, "com", "", "serial port name")
	flag.IntVar(&localServerPort, "lport", 8000, "local server port")
	flag.Parse()

	if comPort != "" {
		c := &serial.Config{Name: comPort, Baud: 9600}
		sio, err = serial.OpenPort(c)
	}

	if err != nil {
		log.Printf("serial port open error %v\n", err)
		if !debug {
			return
		}
	} else {
		serialConnected = true
	}

	go LaunghDeviceServer(localServerPort)
	go readFromArduino()

	origin := fmt.Sprintf("http://%v:%v/", remoteIP, remotePort)
	endpoint := fmt.Sprintf("ws://%v:%v/", remoteIP, remotePort)

	for {
		log.Println("connecting to server...")
		conn, err := websocket.Dial(endpoint, "", origin)
		log.Println("connected...")
		if err != nil {
			log.Printf("server connection fail:%v\n", err)
			time.Sleep(time.Second * RECONN_TIMEOUT)
			continue
		}

		gDeviceServer.RemoteConn = conn
		waitingForNotification()
		gDeviceServer.RemoteConn = nil

		time.Sleep(time.Second * RECONN_TIMEOUT)
	}
}

func readFromArduino() {
	if !serialConnected || sio == nil {
		return
	}

	tmp := make([]byte, 1024)
	for {
		n, err := sio.Read(tmp)
		if err != nil {
			fmt.Printf("err: %v\n", err)
			break
		}
		cmd := string(tmp[:n])
		fmt.Printf("read from arduino %v %v\n", n, cmd)

		//notification anyway
		if cmd == "PIR" {
			gPirNotification <- true
		}
	}
}

func waitingForNotification() {
	for {
		select {
		case <-gPirNotification:
			gDeviceServer.requestCameasImg()
		case <-time.After(time.Second * 3):

		}
	}
}

func unexpectedError() {
	if r := recover(); r != nil {
		fmt.Printf("err:%v\n", r)
	}
}

func showErr(err error) bool {
	if err != nil {
		log.Printf("err:%v\n", err)
		return true
	}
	return false
}
