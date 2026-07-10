package com.kh.project.common;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import com.kh.project.dao.ChatDAO;
import com.kh.project.service.ChatService;

import lombok.RequiredArgsConstructor;
import tools.jackson.databind.ObjectMapper;
@Component
@RequiredArgsConstructor
public class ChatWebSocketHandler extends TextWebSocketHandler {

    private final ChatService chatService;
    private final ChatDAO chatDAO;
    private final ObjectMapper objectMapper = new ObjectMapper();

    // sabun → WebSocketSession (유저당 1개 연결)
    private final Map<Integer, WebSocketSession> userSessions = new ConcurrentHashMap<>();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        int sabun = getSabun(session);
        String name = getName(session);

        // 기존 연결이 있으면 닫기
        WebSocketSession oldSession = userSessions.get(sabun);
        if (oldSession != null && oldSession.isOpen()) {
            try {
                oldSession.close();
            } catch (Exception e) {
                System.out.println("기존 세션 종료 실패: " + e);
            }
        }

        userSessions.put(sabun, session);
        System.out.println("WebSocket 연결: " + name + " (sabun=" + sabun + ")");
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        int sabun = getSabun(session);
        String name = getName(session);

        // 현재 세션과 동일한 경우에만 제거 (새 연결이 이미 대체했을 수 있음)
        WebSocketSession current = userSessions.get(sabun);
        if (current != null && current.getId().equals(session.getId())) {
            userSessions.remove(sabun);
        }

        System.out.println("WebSocket 종료: " + name + " (sabun=" + sabun + ")");
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        int senderSabun = getSabun(session);
        String senderName = getName(session);

        // 클라이언트에서 보낸 JSON 파싱: { "type": "chat", "roomId": 1, "content": "안녕" }
        @SuppressWarnings("unchecked")
        Map<String, Object> incoming = objectMapper.readValue(message.getPayload(), Map.class);
        String type = incoming.getOrDefault("type", "chat").toString();

        if ("chat".equals(type)) {
            int roomId = ((Number) incoming.get("roomId")).intValue();
            String content = (String) incoming.get("content");

            // DB에 메시지 저장
            chatService.saveMessage(roomId, senderSabun, senderName, content);

            // 응답 JSON 생성
            String sentTime = LocalDateTime.now().format(DateTimeFormatter.ofPattern("HH:mm"));

            Map<String, Object> outgoing = new HashMap<>();
            outgoing.put("type", "chat");
            outgoing.put("roomId", roomId);
            outgoing.put("senderSabun", senderSabun);
            outgoing.put("senderName", senderName);
            outgoing.put("content", content);
            outgoing.put("sentTime", sentTime);

            String outJson = objectMapper.writeValueAsString(outgoing);

            // 해당 방의 모든 멤버에게 전송
            sendToRoom(roomId, outJson);
        } else if ("system".equals(type)) {
            int roomId = ((Number) incoming.get("roomId")).intValue();
            String content = (String) incoming.get("content");

            chatService.saveSystemMessage(roomId, content);

            Map<String, Object> outgoing = new HashMap<>();
            outgoing.put("type", "system");
            outgoing.put("roomId", roomId);
            outgoing.put("content", content);

            sendToRoom(roomId, objectMapper.writeValueAsString(outgoing));
        }
    }

    private void sendToRoom(int roomId, String json) throws Exception {
        List<Integer> memberSabuns = chatDAO.selectRoomMemberSabuns(roomId);
        for (int memberSabun : memberSabuns) {
            WebSocketSession memberSession = userSessions.get(memberSabun);
            if (memberSession != null && memberSession.isOpen()) {
                memberSession.sendMessage(new TextMessage(json));
            }
        }
    }

    private int getSabun(WebSocketSession session) {
        return (int) session.getAttributes().get("sabun");
    }

    private String getName(WebSocketSession session) {
        return (String) session.getAttributes().get("userName");
    }
}
