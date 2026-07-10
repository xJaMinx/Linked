<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>


<!DOCTYPE html>
<html>

    <head>
        <meta charset="UTF-8">
        <title>[Linked : 근태 관리]</title>

        <script>
            function checkIn() {
                
                fetch("checkin.do", {
                    method: "POST"
                })
                .then(res => res.json())
                .then(data => {
                    
                    if (data.result === "yes") {
                        alert("출근 처리되었습니다.");
                        location.reload();
                        
                    } else if (data.result === "already") {
                        alert("이미 출근 처리되었습니다.");
                        
                    } else if (data.result === "login") {
                        alert("로그인이 필요합니다.");
                        location.href = "login";
                        
                    } else {
                        alert("출근 처리 실패");
                    }
                    
                });
            }
            
            function checkOut() {
                
                fetch("checkout.do", {
                    method: "POST"
                })
                .then(res => res.json())
                .then(data => {
                    
                    if (data.result === "yes") {
                        alert("퇴근 처리되었습니다.");
                        location.reload();
                        
                    } else if (data.result === "not_checkin") {
                        alert("출근 기록이 없습니다.");
                        
                    } else if (data.result === "already") {
                        alert("이미 퇴근 처리되었습니다.");
                        
                    } else if (data.result === "login") {
                        alert("로그인이 필요합니다.");  
                        location.href = "login";
                        
                    } else {
                        alert("퇴근 처리 실패");
                    }
                    
                });
            }

            function changeRecordMonth() {
                const month = document.getElementById("recordMonth").value;

                fetch("ta_main.do?month=" + encodeURIComponent(month))
                .then(res => res.text())
                .then(html => {
                    const doc = new DOMParser().parseFromString(html, "text/html");
                    const newBody = doc.getElementById("recordTableBody");

                    if (newBody) {
                        document.getElementById("recordTableBody").innerHTML = newBody.innerHTML;
                    }
                });
            }
        </script>

        <link rel="stylesheet" href="${pageContext.request.contextPath}/css/sidebar.css">
        <link rel="stylesheet" href="${pageContext.request.contextPath}/css/dashboard.css">
        <link rel="stylesheet" href="${pageContext.request.contextPath}/css/ta/ta_main.css">

    </head>

    <body>
        <div class="layout">
            <jsp:include page="/WEB-INF/views/common/sidebar.jsp" />
            <div class="main-content">
                <jsp:include page="/WEB-INF/views/common/header.jsp" />

                <div class="container">

                    <h2 class="ta-title">근태 관리</h2>

                    <div class="tabs">
                        <button class="tab-btn active" onclick="switchTab(0)"> 메인 </button>
                        <button class="tab-btn" onclick="switchTab(1)"> 근태현황 </button>
                    </div>

                    <div class="panel active" id="panel-0">
                        <div class="ta-card">
                            <div class="card-title"><span class="dot"></span>금일 근태 관리</div>
                            <div class="card-content">
                                <c:choose>
                                    <c:when test="${empty today}">
                                        <button type="button" class="ta-card_btn" onclick="checkIn()">출근</button>
                                    </c:when>

                                    <c:when test="${empty today.checkout}">
                                        <p> - 출근 시간 : ${today.checkin}</p>
                                        <button type="button" class="ta-card_btn" onclick="checkOut()">퇴근</button>
                                    </c:when>

                                    <c:otherwise>
                                        <p>오늘 근무 완료</p>
                                        <p> - 출근 시간 : ${today.checkin}</p>
                                        <p> - 퇴근 시간 : ${today.checkout}</p>
                                    </c:otherwise>
                                </c:choose>
                            </div>
                        </div>

                        <div class="ta-card">
                            <div class="card-title"><span class="dot"></span>근태 기록</div>
                            <div class="record-filter">
                                <select id="recordMonth" onchange="changeRecordMonth()">
                                    <c:forEach var="month" items="${monthList}">
                                        <option value="${month}" ${month == selectedMonth ? 'selected' : ''}>
                                            ${month}
                                        </option>
                                    </c:forEach>
                                </select>
                            </div>
                            <table class="ta-table">
                                <thead>
                                    <tr>
                                        <th>날짜</th>
                                        <th>출근</th>
                                        <th>퇴근</th>
                                    </tr>
                                </thead>
                                <tbody id="recordTableBody">
                                    <c:forEach var="vo" items="${list}">
                                        <tr>
                                            <td>${vo.day}</td>
                                            <td>${vo.checkin}</td>
                                            <td>${vo.checkout}</td>
                                        </tr>
                                    </c:forEach>
                                </tbody>
                            </table>
                        </div>
                    </div> <!-- panel 0 -->

                    <div class="panel" id="panel-1">
                        <div class="ta-card">
                            <div class="card-title"><span class="dot"></span>이번 달 근태 요약</div>
                            <div class="attend-grid">
                                <div class="attend-stat"><span class="n green">${yearlyTA[0]['normalCount']}</span><span class="lbl">정상 출근</span></div>
                                <div class="attend-stat"><span class="n yellow">${yearlyTA[0]['lateCount']}</span><span class="lbl">지각</span></div>
                                <div class="attend-stat"><span class="n red">${yearlyTA[0]['absentCount']}</span><span class="lbl">결근</span></div>
                            </div>
                        </div>
                        <div class="ta-card">
                            <div class="card-title"><span class="dot"></span>월간 근태 캘린더</div>

                            <%-- 네비게이션 --%>
                            <div class="cal-header">
                                <div class="cal-title" id="calTitle"></div>
                                <div class="cal-nav">
                                    <button onclick="calPrev()">‹</button>
                                    <button onclick="calNext()">›</button>
                                </div>
                            </div>

                            <%-- TUI Calendar 컨테이너 --%>
                            <div id="tuiCal" style="height:580px;"></div>

                            <%-- 범례 --%>
                            <div class="legend">
                                <div class="legend-item"><div class="legend-dot" style="background:rgba(34,197,94,0.5)"></div>정상출근</div>
                                <div class="legend-item"><div class="legend-dot" style="background:rgba(245,158,11,0.5)"></div>지각</div>
                                <div class="legend-item"><div class="legend-dot" style="background:rgba(239,68,68,0.4)"></div>결근</div>
                                <div class="legend-item"><div class="legend-dot" style="background:rgba(99,102,241,0.5)"></div>휴가</div>
                                <div class="legend-item"><div class="legend-dot" style="background:rgba(165,180,252,0.5)"></div>반차</div>
                            </div>
                        </div>
                        <div class="ta-card">
                            <div class="card-title"><span class="dot"></span>월간 근태 현황</div>
                            <table class="ta-table">
                                <thead>
                                    <tr>
                                        <th>월</th>
                                        <th class="green">정상</th>
                                        <th class="yellow">지각</th>
                                        <th class="red">결근</th>
                                        <th>총 근무(h)</th>
                                    </tr>

                                </thead>
                                <tbody>
                                    <c:forEach var="monthTA" items="${yearlyTA}" >
                                        <tr>
                                            <td class="label">${monthTA.month}월</td>
                                            <td class="green">${monthTA.normalCount}</td>
                                            <td class="yellow">${monthTA.lateCount}</td>
                                            <td class="red">${monthTA.absentCount}</td>
                                            <td>${monthTA.totalWorkTime}</td>
                                        </tr>
                                    </c:forEach>
                                </tbody>
                            </table>
                        </div>
                    </div> <!-- panel 1 -->
                </div> <!-- container -->
            </div> <!-- main content -->
        </div>
        <jsp:include page="/WEB-INF/views/common/msg.jsp" />
        <script>
            
            // ── 탭 전환 ──
            function switchTab(idx) {
                document.querySelectorAll('.tab-btn').forEach((b, i) => {
                    b.classList.toggle('active', i === idx);
                });
                document.querySelectorAll('.panel').forEach((p, i) => {
                    p.classList.toggle('active', i === idx);
                });
            }
            
            const taData = JSON.parse('${taJson}');
            
            const styleMap = {
                normal : { label: '정상출근', bg: 'rgba(34,197,94,0.15)',  border: '#16a34a', text: '#15803d' },
                late   : { label: '지각',    bg: 'rgba(245,158,11,0.15)', border: '#d97706', text: '#b45309' },
                absent : { label: '결근',    bg: 'rgba(239,68,68,0.12)',  border: '#dc2626', text: '#b91c1c' },
                leave  : { label: '휴가',    bg: 'rgba(99,102,241,0.15)', border: '#6366f1', text: '#4338ca' },
                half   : { label: '반차',    bg: 'rgba(99,102,241,0.10)', border: '#a5b4fc', text: '#6366f1' }
            };
            
            const taMap = {};
            taData.forEach(function(item) { taMap[item.date] = item.status; });
            
            const now          = new Date();
            let currentYear  = now.getFullYear();
            let currentMonth = now.getMonth();
            
            function pad(n) { return String(n).padStart(2, '0'); }
            
            function renderCal() {
                document.getElementById('calTitle').textContent =
                currentYear + '년 ' + (currentMonth + 1) + '월';
                
                const container = document.getElementById('tuiCal');
                container.innerHTML = '';
                
                const table = document.createElement('table');
                table.style.cssText = 'width:100%; border-collapse:collapse; table-layout:fixed;';
                
                // 요일 헤더
                const thead = document.createElement('thead');
                const headRow = document.createElement('tr');
                ['일','월','화','수','목','금','토'].forEach(function(d, i) {
                    const th = document.createElement('th');
                    th.textContent = d;
                    var color = (i === 0) ? '#dc2626' : (i === 6) ? '#6366f1' : '#6b7280';
                    th.style.cssText =
                    'padding:10px 0;' +
                    'font-size:12px;' +
                    'font-weight:600;' +
                    'color:' + color + ';' +
                    'text-align:center;' +
                    'border-bottom:2px solid #e5e7eb;';
                    headRow.appendChild(th);
                });
                thead.appendChild(headRow);
                table.appendChild(thead);
                
                const firstDay = new Date(currentYear, currentMonth, 1).getDay();
                const lastDate = new Date(currentYear, currentMonth + 1, 0).getDate();
                
                const tbody = document.createElement('tbody');
                let day = 1;
                let row = document.createElement('tr');
                
                for (let i = 0; i < firstDay; i++) {
                    row.appendChild(makeEmptyCell());
                }
                    
                    while (day <= lastDate) {
                        if (row.children.length === 7) {
                            tbody.appendChild(row);
                            row = document.createElement('tr');
                        }
                        
                        const dateStr = currentYear + '-' + pad(currentMonth + 1) + '-' + pad(day);
                        const status  = taMap[dateStr];
                        const s       = status ? styleMap[status] : null;
                        const dow     = (firstDay + day - 1) % 7;
                        const isToday = now.getDate() === day && currentMonth === now.getMonth();
                        
                        const td = document.createElement('td');
                        td.style.cssText =
                        'height:76px;' +
                        'vertical-align:top;' +
                        'padding:6px;' +
                        'border:1px solid #f0f0f0;' +
                        'background:' + (s ? s.bg : 'transparent') + ';' +
                        (s ? 'border-left:3px solid ' + s.border + ';' : '');
                        
                        // 날짜 숫자
                        const dateNum = document.createElement('div');
                        dateNum.textContent = day;
                        var numColor;
                        if (isToday)       numColor = '#fff';
                        else if (dow === 0) numColor = '#dc2626';
                        else if (dow === 6) numColor = '#6366f1';
                        else if (s)         numColor = s.text;
                        else                numColor = '#374151';
                        
                        dateNum.style.cssText =
                        'font-size:13px;' +
                        'font-weight:' + (isToday ? '800' : '500') + ';' +
                        'color:' + numColor + ';' +
                        'width:24px;height:24px;' +
                        'line-height:24px;' +
                        'text-align:center;' +
                        'border-radius:50%;' +
                        'background:' + (isToday ? '#2563eb' : 'transparent') + ';' +
                        'margin-bottom:5px;';
                        td.appendChild(dateNum);
                        
                        // 상태 배지
                        if (s) {
                            const badge = document.createElement('div');
                            badge.textContent = s.label;
                            badge.style.cssText =
                            'font-size:11px;' +
                            'font-weight:600;' +
                            'color:' + s.text + ';' +
                            'background:white;' +
                            'border:1px solid ' + s.border + ';' +
                            'border-radius:4px;' +
                            'padding:2px 5px;' +
                            'display:inline-block;' +
                            'white-space:nowrap;';
                            td.appendChild(badge);
                        }
                        
                        row.appendChild(td);
                        day++;
                        
                        //근태 확인버튼 이동용
                        const params = new URLSearchParams(location.search);
                        const tab = params.get("tab");
                        
                        if(tab !== null){
                            switchTab(Number(tab));
                        }
                    }
                    
                    while (row.children.length < 7) {
                        row.appendChild(makeEmptyCell());
                    }
                    tbody.appendChild(row);
                    table.appendChild(tbody);
                    container.appendChild(table);
                }
            
                
            function makeEmptyCell() {
                const td = document.createElement('td');
                td.style.cssText = 'height:76px;border:1px solid #f0f0f0;background:#fafafa;';
                return td;
            }
                
            function updateTitle() {
                const d = calendar.getDate();
                document.getElementById('calTitle').textContent =
                d.getFullYear() + '년 ' + (d.getMonth() + 1) + '월';
            }
                
            function calPrev() {
                currentMonth--;
                if (currentMonth < 0) {
                    currentMonth = 11;
                }
                fetchAndRender();
            }
                
            function calNext() {
                currentMonth++;
                if (currentMonth > 11) {
                    currentMonth = 0;
                }
                fetchAndRender();
            }
                
            function fetchAndRender() {
                // month는 서버에 1-indexed로 전달
                fetch("ta_calendar.do?month="+ (currentMonth+1))
                .then(res => res.json())
                .then(data => {
                    // taMap 갱신
                    Object.keys(taMap).forEach(k => delete taMap[k]);
                    data.forEach(item => { taMap[item.date] = item.status; });
                    renderCal();
                });
            }
                
            renderCal();
        </script>
    </body>
</html>