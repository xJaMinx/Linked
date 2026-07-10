function loadChatRoomList() {
                currentRoomId = null;
                fetch("/msg_chatRoomList")
                    .then(res => res.text())
                    .then(html => {
                        document.getElementById("msg_chatting").innerHTML = html;
                    });
            }
            
            function loadLikedChatRoomList(){
                currentRoomId = null;
                fetch("/msg_LikedChatRoomList")
                    .then(res => res.text())
                    .then(html => {
                        document.getElementById("msg_like").innerHTML = html;
                    });
            }

            /* ── 채팅방 열기 ── */
            let loadingMore = false;
            let noMoreLogs = false;

            function openChatRoom(roomId, room_type) {
                currentRoomId = roomId;
                loadingMore = false;
                noMoreLogs = false;

                fetch("/msg_chatRoom/" + roomId + "?room_type=" + room_type)
                    .then(res => res.text())
                    .then(html => {
                        document.getElementById(roomListType).innerHTML = html;
                        var msgBox = document.getElementById('chatMessages');
                        if (msgBox) {
                            requestAnimationFrame(() => {
                                msgBox.scrollTop = msgBox.scrollHeight;
                            });
                            msgBox.addEventListener('scroll', onChatScroll);
                        }
                    });
            }

            function onChatScroll() {
                let msgBox = document.getElementById('chatMessages');
                if (!msgBox || loadingMore || noMoreLogs) return;
                if (msgBox.scrollTop > 50) return;

                let firstMsg = msgBox.querySelector('[data-msg-id]');
                if (!firstMsg) return;

                let lastLogId = firstMsg.getAttribute('data-msg-id');
                loadingMore = true;

                fetch("/msg_chatRoom/" + currentRoomId + "/more?lastLogId=" + lastLogId)
                    .then(res => res.json())
                    .then(logs => {
                        if (logs.length === 0) {
                            noMoreLogs = true;
                            loadingMore = false;
                            return;
                        }

                        let prevHeight = msgBox.scrollHeight;
                        let fragment = document.createDocumentFragment();

                        logs.forEach(msg => {
                            let el;
                            if (msg.sender_sabun === null) {
                                el = document.createElement('div');
                                el.className = 'chat-system-msg';
                                el.setAttribute('data-msg-id', msg.message_id);
                                el.textContent = msg.content;
                            } else {
                                let isMine = msg.sender_sabun === MY_SABUN;
                                el = document.createElement('div');
                                el.className = 'chat-msg ' + (isMine ? 'mine' : 'other');
                                el.setAttribute('data-msg-id', msg.message_id);

                                let html = '<div class="chat-bubble ' + (isMine ? 'mine' : 'other') + '">';
                                if (!isMine) {
                                    html += '<div class="msg-sender">' + escapeHtml(msg.saname) + '</div>';
                                }
                                html += '<div class="msg-text">' + escapeHtml(msg.content) + '</div></div>';
                                html += '<div class="chat-msg-sent_at">' + (msg.sent_time || '') + '</div>';
                                el.innerHTML = html;
                            }
                            fragment.appendChild(el);
                        });

                        msgBox.insertBefore(fragment, msgBox.firstChild);
                        msgBox.scrollTop = msgBox.scrollHeight - prevHeight;
                        loadingMore = false;
                    });
            }

            /* ── 메시지를 채팅 화면에 추가 ── */
            function appendMessage(data) {
                let msgBox = document.getElementById('chatMessages');
                if (!msgBox) return;

                let div = document.createElement('div');
                div.className = 'chat-msg ' + (data.senderSabun === MY_SABUN ? 'mine' : 'other');

                let html = '<div class="chat-bubble '+ (data.senderSabun === MY_SABUN ? 'mine' : 'other')+'">';
                if (data.senderSabun !== MY_SABUN) {
                    html += '<div class="msg-sender">' + escapeHtml(data.senderName) + '</div>';
                }

                html += '<div class="msg-text">' + escapeHtml(data.content) + '</div></div>';
                html += '<div class="chat-msg-sent_at">' + escapeHtml(data.sentTime) + '</div>';
                
                div.innerHTML = html;

                msgBox.appendChild(div);
                msgBox.scrollTop = msgBox.scrollHeight;
            }

            /* ── 채팅방 목록에서 마지막 메시지 미리보기 업데이트 ── */
            function updateChatRoomPreview(data) {
                let roomEl = document.querySelector('.chat-room[data-room-id="' + data.roomId + '"]');
                if (!roomEl) return;
                let lastMsg = roomEl.querySelector('.chat-last-msg');
                if (lastMsg) {
                    lastMsg.textContent = data.content;
                }
            }

            /* ── 시스템 메시지 표시 ── */
            function appendSystemMessage(text) {
                let msgBox = document.getElementById('chatMessages');
                if (!msgBox) return;

                let div = document.createElement('div');
                div.className = 'chat-system-msg';
                div.textContent = text;
                msgBox.appendChild(div);
                msgBox.scrollTop = msgBox.scrollHeight;
            }

            /* ── HTML 이스케이프 ── */
            function escapeHtml(text) {
                let div = document.createElement('div');
                div.textContent = text;
                return div.innerHTML;
            }

            /* ── 대화상대 목록 패널 ── */
            function showDrawerMembers() {
                document.getElementById('drawerMembersPanel').classList.add('open');
                // TODO: 여기서 멤버 목록을 가져와서 drawerMembersList에 렌더링
                fetch("/msg_chatRoom/members/list/"+ currentRoomId)
                    .then(res => res.json())
                    .then(data => {
                        let html = '';
                        data.forEach( e => {
                            html += '<div class="drawer-member-item">'
                            html +=    '<div class="profile-circle">'+ e.saname.substring(0, 1) +'</div><div>'
                            html +=        '<div class="drawer-member-name">'+ e.saname +'</div>'
                            html +=        '<div class="drawer-member-dept">'+ e.dname +'</div></div>'
                            if(e.sabun == MY_SABUN){
                                html += '<span class="drawer-member-me">나</span>'
                            }
                            html += '</div>'
                        });
                        
                        document.getElementById('drawerMembersList').innerHTML = html;
                    })
            }

            function leaveChatRoom() {
                closeLeaveConfirm();
                toggleChatMorePanel();
                
                fetch("/msg_chatRoom/leave/"+currentRoomId+"?sabun="+MY_SABUN)
                    .then(res => res.json())
                    .then(data => {
                        if (data && ws && ws.readyState === WebSocket.OPEN) {
                            ws.send(JSON.stringify({
                                type: 'system',
                                roomId: currentRoomId,
                                content: MY_NAME + '님이 나가셨습니다.'
                            }));

                            msgSwitchTab(1);
                        }
                    });

            }

            /* 채팅방 즐겨찾기 */
            async function chat_like(event,roomId,index){
                event.stopPropagation();

                await fetch("/msg_chatRoomList/liked?roomId="+roomId+"&sabun="+MY_SABUN)
                    .then(res => res.text())
                    .then(html => {
                        document.querySelectorAll('.chat-liked-'+index).forEach((b, i) => {
                            b.innerText = html;
                        });
                    });
            }