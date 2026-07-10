package com.kh.project.controller;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseBody;

import com.kh.project.dao.ChatDAO;
import com.kh.project.service.ChatService;
import com.kh.project.vo.ChatMessageVO;
import com.kh.project.vo.SawonVO;

import lombok.RequiredArgsConstructor;

@Controller
@RequiredArgsConstructor
public class ChattingController {

    private final ChatService chatService;
    private final ChatDAO chatDAO;

    @GetMapping("/msg_chatRoom/{roomId}")
    public String chatRoom(Model model, String room_type, @PathVariable int roomId){

        List<ChatMessageVO> logs = chatService.getRecentLogs(roomId);
        
        model.addAttribute("room_type", room_type);
        model.addAttribute("roomId", roomId);
        model.addAttribute("logs", logs);

        return "/msg/chatRoom";
    }
    
    //채팅방 즐겨찾기
    @GetMapping("/msg_chatRoomList/liked")
    @ResponseBody
    public String chatRoomLiked(int sabun, int roomId){

        boolean liked = chatDAO.selectRoomLikedCheck(roomId, sabun);

        liked = !liked;

        chatDAO.updateChatRoomLiked(roomId, sabun, liked);
        
        if(liked) return "❤️";
        else return "🤍";

    }

    //채팅방 나가기
    @GetMapping("/msg_chatRoom/leave/{roomId}")
    @ResponseBody
    public boolean chatRoomLeave(@PathVariable int roomId, int sabun){

        // 1:1 채팅방이면 나가는 사람 이름을 room_name에 저장
        chatDAO.updateRoomNameBeforeLeave(roomId, sabun);

        boolean res = chatDAO.deleteUserRoomLeave(roomId, sabun);

        return res;
    }

    // 이전 메시지 더보기
    @GetMapping("/msg_chatRoom/{roomId}/more")
    @ResponseBody
    public List<ChatMessageVO> chatRoomMore(@PathVariable int roomId, Long lastLogId) {
        return chatService.getMoreLogs(roomId, lastLogId);
    }

    // 채팅방 멤버 sabun 목록 조회
    @GetMapping("/msg_chatRoom/members/{roomId}")
    @ResponseBody
    public List<Integer> chatRoomMembers(@PathVariable int roomId) {
        return chatDAO.selectRoomMemberSabuns(roomId);
    }

    // 채팅방 멤버 초대
    @PostMapping("/msg_chatRoom/invite/{roomId}")
    @ResponseBody
    public boolean chatRoomInvite(@PathVariable int roomId, @RequestBody List<Integer> sabuns) {
        for (int sabun : sabuns) {
            chatDAO.insertChatMember(roomId, sabun);
        }
        return true;
    }

    // 채팅방에 속해있는 유저 목록
    @GetMapping("/msg_chatRoom/members/list/{roomId}")
    @ResponseBody
    public List<SawonVO> chatRoomMemberList(@PathVariable int roomId){
        return chatDAO.selectRoomSawonList(roomId);
    }

}
