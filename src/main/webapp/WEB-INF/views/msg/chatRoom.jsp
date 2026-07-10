<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>

<div style="display:flex; flex-direction:column; flex:1; min-height:0;">

    <div class="chat-messages" id="chatMessages" data-room-id="${roomId}">
        <c:forEach var="msg" items="${logs}" varStatus="st">
            <c:choose>
                <c:when test="${msg.sender_sabun == null}">
                    <div class="chat-system-msg" data-msg-id="${msg.message_id}">${fn:escapeXml(msg.content)}</div>
                </c:when>
                <c:otherwise>
                    <div class="chat-msg ${msg.sender_sabun == sessionScope.user ? 'mine' : 'other'}" data-msg-id="${msg.message_id}">
                        <div class="chat-bubble ${msg.sender_sabun == sessionScope.user ? 'mine' : 'other'}">
                            <c:if test="${msg.sender_sabun != sessionScope.user}">
                                <div class="msg-sender">${msg.saname}</div>
                            </c:if>
                            <div class="msg-text">${fn:escapeXml(msg.content)}</div>
                        </div>
                        <div class="chat-msg-sent_at">
                            ${msg.sent_time}
                        </div>
                    </div>
                </c:otherwise>
            </c:choose>
        </c:forEach>
    </div>

    <div class="chat-input-area">
        <div>
            <input type="text" id="chatInput" placeholder="메시지를 입력하세요"
                onkeydown="if(event.key==='Enter') sendChatMessage();" />
        </div>
        <div class="chat-button-area">
            <button type="button" class="chat-more" onclick="toggleChatMorePanel()">+</button>
            <button class="chat-send" onclick="sendChatMessage()">전송</button>
        </div>
    </div>

    <!-- 서랍형 메뉴 -->
    <div class="chat-drawer-overlay" id="chatDrawerOverlay" onclick="toggleChatMorePanel()"></div>
    <div class="chat-drawer" id="chatDrawer">
        <div class="chat-drawer-menu">
            <c:if test="${room_type eq 'GROUP'}">
                <button class="chat-drawer-item" onclick="inviteMember()">
                    <span class="drawer-icon">👥+</span> 대화상대 초대하기
                </button>
            </c:if>

            <button class="chat-drawer-item" onclick="showDrawerMembers()">
                <span class="drawer-icon">👤</span> 대화상대
            </button>
        </div>
        <div class="chat-drawer-divider"></div>
        <button class="chat-drawer-item leave" onclick="showLeaveConfirm()">
            <span class="drawer-icon">🚪</span> 채팅방 나가기
        </button>

        <!-- 대화상대 목록 패널 (서랍 안에서 전환) -->
        <div class="drawer-members-panel" id="drawerMembersPanel">
            <div class="drawer-members-header">
                <button class="drawer-members-back" onclick="hideDrawerMembers()">&larr;</button>
                <span class="drawer-members-title">대화상대</span>
                <span class="drawer-members-count" id="drawerMembersCount"></span>
            </div>
            <div class="drawer-members-list" id="drawerMembersList">
            </div>
        </div>
    </div>

    <!-- 나가기 확인 모달 -->
    <div class="leave-confirm-overlay" id="leaveConfirmOverlay">
        <div class="leave-confirm-box">
            <p>채팅방을 나가시겠습니까?<br>대화 내용이 모두 삭제됩니다.</p>
            <div class="leave-confirm-btns">
                <button class="leave-cancel-btn" onclick="closeLeaveConfirm()">취소</button>
                <button class="leave-ok-btn" onclick="leaveChatRoom()">나가기</button>
            </div>
        </div>
    </div>

    <!-- 초대 모달 -->
    <div class="invite-modal-overlay" id="inviteModalOverlay">
        <div class="invite-modal-card">
            <div class="member-select-header">
                <span>초대할 대화상대 선택</span>
                <button class="member-select-close" onclick="closeInviteModal()">&times;</button>
            </div>
            <div class="member-select-search">
                <input type="text" id="inviteSearch" placeholder="이름으로 검색"
                       oninput="filterInviteList(this.value)" />
            </div>
            <div class="invite-member-list" id="inviteMemberList"></div>
            <div class="member-select-footer">
                <button class="member-select-confirm" id="inviteConfirmBtn"
                        onclick="confirmInviteMembers()" disabled>초대하기</button>
            </div>
        </div>
    </div>

</div>

