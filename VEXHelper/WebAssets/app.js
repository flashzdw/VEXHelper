let socket;
let reconnectTimer;
let audioContext;
let audioBuffers = {};
const sounds = ['Start', 'Stop', 'Over', 'Change'];

// Localization
const i18n = {
    'en': {
        'title': 'VEXHelper Remote',
        'subtitle': 'Click anywhere to connect and enable audio',
        'ready': 'Ready',
        'disconnected': 'Disconnected'
    },
    'zh-Hans': {
        'title': 'VEXHelper 远程投屏',
        'subtitle': '点击任意处连接并启用音频',
        'ready': '就绪',
        'disconnected': '未连接'
    }
};
let currentLang = 'en';
let isMuted = false;

function updateLanguage(lang) {
    if (!i18n[lang]) return;
    currentLang = lang;
    
    // Update DOM text
    document.querySelector('h1').innerText = i18n[lang]['title'];
    document.querySelector('.message p').innerText = i18n[lang]['subtitle'];
    
    // Update status text based on current state
    const statusEl = document.getElementById('status');
    if (socket && socket.readyState === WebSocket.OPEN) {
        statusEl.innerText = i18n[lang]['ready'];
    } else {
        statusEl.innerText = i18n[lang]['disconnected'];
    }
}

// Initialize Audio Context on user interaction
async function initAudio() {
    if (!audioContext) {
        audioContext = new (window.AudioContext || window.webkitAudioContext)();
    }
    if (audioContext.state === 'suspended') {
        await audioContext.resume();
    }
    await loadSounds();
}

async function loadSounds() {
    for (const sound of sounds) {
        try {
            const response = await fetch(`/audio/${sound}.MP3`);
            if (!response.ok) throw new Error(`HTTP ${response.status}`);
            const arrayBuffer = await response.arrayBuffer();
            const audioBuffer = await audioContext.decodeAudioData(arrayBuffer);
            audioBuffers[sound] = audioBuffer;
            console.log(`Loaded ${sound}`);
        } catch (e) {
            console.error(`Failed to load ${sound}`, e);
        }
    }
}
 
function playSound(name) {
    if (isMuted) return; // Muted check
    if (!audioContext || !audioBuffers[name]) return;
    try {
        const source = audioContext.createBufferSource();
        source.buffer = audioBuffers[name];
        source.connect(audioContext.destination);
        source.start(0);
    } catch (e) {
        console.error("Play error", e);
    }
}

function connect() {
    if (socket && (socket.readyState === WebSocket.OPEN || socket.readyState === WebSocket.CONNECTING)) return;

    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const host = window.location.host;
    // const host = "192.168.1.5:8080"; // Debug
    
    console.log(`Connecting to ${protocol}//${host}`);
    socket = new WebSocket(`${protocol}//${host}`);
    
    socket.onopen = () => {
        console.log("Connected");
        document.getElementById('status').innerText = i18n[currentLang]['ready'];
        document.getElementById('status').style.color = "#30D158"; // Green
        if (reconnectTimer) {
            clearTimeout(reconnectTimer);
            reconnectTimer = null;
        }
    };
    
    socket.onclose = () => {
        console.log("Disconnected");
        document.getElementById('status').innerText = i18n[currentLang]['disconnected'];
        document.getElementById('status').style.color = "#FF453A"; // Red
        
        // Retry
        if (!reconnectTimer) {
            reconnectTimer = setTimeout(connect, 3000);
        }
    };
    
    socket.onerror = (e) => {
        console.error("Socket error", e);
    };
    
    socket.onmessage = (event) => {
        try {
            const msg = JSON.parse(event.data);
            handleMessage(msg);
        } catch (e) {
            console.error("Parse error", e);
        }
    };
}

function handleMessage(msg) {
    if (msg.type === 'update') {
        // Update Time
        document.getElementById('timer').innerText = msg.timeString;
        
        // Update Progress Ring
        const progress = Math.max(0, Math.min(1, msg.progress));
        updateProgressRing(progress);
        
        // Update Status Style
        const panel = document.querySelector('.glass-panel');
        // Remove old status classes
        panel.classList.remove('running', 'paused', 'stopped', 'idle');
        panel.classList.add(msg.status); // e.g., 'running'
        
    } else if (msg.type === 'playSound') {
        playSound(msg.file);
    } else if (msg.type === 'language') {
        updateLanguage(msg.lang);
    } else if (msg.type === 'toggleMute') {
        isMuted = msg.muted;
        // Optionally show a mute indicator on UI
        console.log("Muted:", isMuted);
    }
}

// Entry point
document.getElementById('overlay').addEventListener('click', async () => {
    const overlay = document.getElementById('overlay');
    overlay.style.opacity = '0';
    setTimeout(() => { overlay.style.display = 'none'; }, 500);
    
    await initAudio();
    connect();
});

// SVG Progress Ring Logic
const circle = document.getElementById('indicator');
const track = document.getElementById('track');
let perimeter = 0;

function updatePerimeter() {
    // Dynamically calculate Path 'd' to start from Top Center and go Clockwise
    // Window size
    const W = window.innerWidth;
    const H = window.innerHeight;
    
    // Stroke width allowance (half of stroke width to keep it inside)
    // Max stroke is 25, so margin 12.5 is minimum. Let's use 20px padding as in style.css logic.
    // In style.css, we didn't set padding, just box-sizing.
    // We want the path to be centered.
    // Let's assume a margin of 20px from edge.
    const M = 20; 
    const R = 45; // Corner radius
    
    // Ensure dimensions are valid
    if (W < 2*M || H < 2*M) return;
    
    // Path coordinates
    // Start at Top Center: (W/2, M)
    // Top Right Line End: (W-M-R, M)
    // Top Right Arc End: (W-M, M+R)
    // Bottom Right Line End: (W-M, H-M-R)
    // Bottom Right Arc End: (W-M-R, H-M)
    // Bottom Left Line End: (M+R, H-M)
    // Bottom Left Arc End: (M, H-M-R)
    // Top Left Line End: (M, M+R)
    // Top Left Arc End: (M+R, M)
    // Close to Top Center: (W/2, M)
    
    const d = `
        M ${W/2} ${M}
        L ${W-M-R} ${M}
        A ${R} ${R} 0 0 1 ${W-M} ${M+R}
        L ${W-M} ${H-M-R}
        A ${R} ${R} 0 0 1 ${W-M-R} ${H-M}
        L ${M+R} ${H-M}
        A ${R} ${R} 0 0 1 ${M} ${H-M-R}
        L ${M} ${M+R}
        A ${R} ${R} 0 0 1 ${M+R} ${M}
        L ${W/2} ${M}
        Z
    `;
    
    if (circle) {
        circle.setAttribute('d', d);
        perimeter = circle.getTotalLength();
        circle.style.strokeDasharray = perimeter;
        circle.style.strokeDashoffset = 0; // Initial full
    }
    
    if (track) {
        track.setAttribute('d', d);
    }
}

function updateProgressRing(progress) {
    if (perimeter === 0) updatePerimeter();
    
    // progress is 1.0 (full) to 0.0 (empty)
    // We want the border to disappear as time reduces.
    // strokeDashoffset: 0 means full visible
    // strokeDashoffset: perimeter means hidden
    
    // Logic: As time reduces (progress 1 -> 0), we want the line to shrink.
    // So offset should go from 0 to perimeter.
    const offset = perimeter * (1 - progress);
    circle.style.strokeDashoffset = offset;
}

// Recalculate on resize
window.addEventListener('resize', updatePerimeter);
// Initial calculation
updatePerimeter();
