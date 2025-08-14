package main

import (
  "bytes"
  "context"
  "encoding/json"
  "fmt"
  "io"
  "log"
  "net/http"
  "os"
  "time"

  "github.com/pion/webrtc/v3"
)

type Offer struct { SDP string `json:"sdp"`}
type Answer struct { SDP string `json:"sdp"`}

type ClientMsg struct {
  Op string `json:"op"`
  Model string `json:"model,omitempty"`
  Prompt string `json:"prompt,omitempty"`
  Stream bool `json:"stream,omitempty"`
}
type ServerMsg struct {
  Op string `json:"op"`
  Content string `json:"content,omitempty"`
  Error string `json:"error,omitempty"`
}

func main() {
  mux := http.NewServeMux()
  mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request){ fmt.Fprintln(w, "ok") })
  mux.HandleFunc("/signaling/offer", handleOffer)
  addr := ":8443"
  log.Printf("listening on %s", addr)
  log.Fatal(http.ListenAndServe(addr, cors(mux)))
}

func cors(h http.Handler) http.Handler {
  return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request){
    w.Header().Set("Access-Control-Allow-Origin", "*")
    w.Header().Set("Access-Control-Allow-Headers", "content-type")
    if r.Method == http.MethodOptions { w.WriteHeader(204); return }
    h.ServeHTTP(w, r)
  })
}

func handleOffer(w http.ResponseWriter, r *http.Request) {
  var off Offer
  if err := json.NewDecoder(r.Body).Decode(&off); err != nil { http.Error(w, err.Error(), 400); return }

  api := webrtc.NewAPI()
  pc, err := api.NewPeerConnection(webrtc.Configuration{
    ICEServers: []webrtc.ICEServer{
      {URLs: []string{"stun:stun.l.google.com:19302"}},
      {URLs: envURLs("TURN_URLS"), Username: os.Getenv("TURN_USER"), Credential: os.Getenv("TURN_PASS")},
    },
  })
  if err != nil { http.Error(w, err.Error(), 500); return }
  defer pc.Close()

  dc, err := pc.CreateDataChannel("llm", nil)
  if err != nil { http.Error(w, err.Error(), 500); return }
  dc.OnMessage(func(msg webrtc.DataChannelMessage){
    var cm ClientMsg
    if err := json.Unmarshal(msg.Data, &cm); err != nil {
      _ = dc.SendText(mustJSON(ServerMsg{Op:"error", Error:"bad json"})); return
    }
    switch cm.Op {
    case "ping":
      _ = dc.SendText(mustJSON(ServerMsg{Op:"pong"}))
    case "chat":
      model := cm.Model; if model=="" { model = env("OLLAMA_MODEL", "llama3.1:8b-instruct-q4_K_M") }
      go proxyOllamaStream(dc, model, cm.Prompt, true)
    default:
      _ = dc.SendText(mustJSON(ServerMsg{Op:"error", Error:"unknown op"}))
    }
  })

  offer := webrtc.SessionDescription{Type: webrtc.SDPTypeOffer, SDP: off.SDP}
  if err := pc.SetRemoteDescription(offer); err != nil { http.Error(w, err.Error(), 500); return }
  answer, err := pc.CreateAnswer(nil); if err != nil { http.Error(w, err.Error(), 500); return }
  done := webrtc.GatheringCompletePromise(pc)
  if err := pc.SetLocalDescription(answer); err != nil { http.Error(w, err.Error(), 500); return }
  <-done
  _ = json.NewEncoder(w).Encode(Answer{SDP: pc.LocalDescription().SDP})
}

func proxyOllamaStream(dc *webrtc.DataChannel, model, prompt string, stream bool) {
  payload := map[string]any{
    "model": model,
    "stream": true,
    "messages": []map[string]string{{"role":"user","content":prompt}},
    "num_ctx": 4096, "num_predict": 512, "temperature": 0.6,
  }
  b, _ := json.Marshal(payload)
  ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute); defer cancel()
  req, _ := http.NewRequestWithContext(ctx, "POST", env("OLLAMA_URL", "http://127.0.0.1:11434")+"/api/chat", bytes.NewReader(b))
  req.Header.Set("Content-Type", "application/json")
  resp, err := http.DefaultClient.Do(req)
  if err != nil { _ = dc.SendText(mustJSON(ServerMsg{Op:"error", Error:"ollama connect failed"})); return }
  defer resp.Body.Close()
  dec := json.NewDecoder(resp.Body)
  var ln struct{
    Model string `json:"model"`
    Message struct{ Role, Content string } `json:"message"`
    Done bool `json:"done"`
  }
  for {
    if err := dec.Decode(&ln); err != nil {
      if err == io.EOF { break }
      _ = dc.SendText(mustJSON(ServerMsg{Op:"error", Error:"decode error"})); return
    }
    if ln.Message.Content != "" { _ = dc.SendText(mustJSON(ServerMsg{Op:"delta", Content: ln.Message.Content})) }
    if ln.Done { break }
  }
  _ = dc.SendText(mustJSON(ServerMsg{Op:"done"}))
}

func env(k, def string) string { if v:=os.Getenv(k); v!=""; { return v }; return def }
func envURLs(k string) []string { if v:=os.Getenv(k); v!=""; { return []string{v} }; return nil }
func mustJSON(v any) string { b,_ := json.Marshal(v); return string(b) }
