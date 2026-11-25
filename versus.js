(() => {
  'use strict';

  const ROOM_SESSION_KEY = 'ascent-versus-room-v1';
  const ROOM_CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  const ROUND_LENGTH_SECONDS = 25;
  const POLL_PLAYING_MS = 650;
  const POLL_IDLE_MS = 1200;

  const CATEGORIES = Object.freeze({
    facial_expressions: {
      title: 'FACIAL EXPRESSIONS',
      hint: 'Angry, happy, surprised … name an emotion or expression.',
      answers: ['angry','happy','sad','surprised','scared','afraid','confused','disgusted','worried','bored','excited','nervous','embarrassed','proud','relieved','shocked','sleepy','curious','frustrated','calm','annoyed','delighted','grumpy','puzzled','ashamed','amused','serious','smug','jealous','lonely','hopeful'],
      aliases: {mad:'angry', frightened:'scared', terrified:'scared', thrilled:'excited', joyful:'happy', glad:'happy', upset:'sad'}
    },
    animals: {
      title: 'ANIMALS',
      hint: 'Name a living animal.',
      answers: ['dog','cat','horse','cow','sheep','pig','lion','tiger','elephant','giraffe','zebra','monkey','gorilla','bear','wolf','fox','rabbit','mouse','rat','deer','camel','hippopotamus','panda','koala','kangaroo','penguin','eagle','owl','parrot','shark','whale','dolphin','octopus','turtle','snake','crocodile','frog','butterfly','bee'],
      aliases: {puppy:'dog', kitten:'cat', hippo:'hippopotamus'}
    },
    fruits: {
      title: 'FRUITS',
      hint: 'Name an edible fruit.',
      answers: ['apple','banana','orange','pear','peach','plum','grape','strawberry','blueberry','raspberry','blackberry','cherry','lemon','lime','mango','pineapple','watermelon','melon','kiwi','papaya','coconut','pomegranate','apricot','fig','date','avocado','grapefruit','guava','lychee','passion fruit'],
      aliases: {berries:'blueberry', clementine:'orange', satsuma:'orange'}
    },
    sports: {
      title: 'SPORTS',
      hint: 'Name an organised sport.',
      answers: ['football','basketball','baseball','tennis','volleyball','golf','cricket','rugby','hockey','ice hockey','badminton','table tennis','boxing','wrestling','swimming','cycling','running','athletics','gymnastics','skiing','snowboarding','surfing','skateboarding','karate','judo','fencing','handball','water polo','rowing','sailing','archery','climbing','padel','pickleball'],
      aliases: {soccer:'football', pingpong:'table tennis', 'ping pong':'table tennis', biking:'cycling'}
    },
    countries: {
      title: 'COUNTRIES',
      hint: 'Name an internationally recognised country or territory.',
      answers: ['netherlands','belgium','france','germany','spain','portugal','italy','switzerland','austria','sweden','norway','denmark','finland','ireland','poland','greece','turkey','ukraine','united kingdom','united states','canada','mexico','brazil','argentina','chile','colombia','peru','japan','china','india','south korea','thailand','vietnam','indonesia','australia','new zealand','egypt','morocco','south africa','nigeria','kenya','saudi arabia','united arab emirates'],
      aliases: {uk:'united kingdom', britain:'united kingdom', england:'united kingdom', usa:'united states', us:'united states', america:'united states', korea:'south korea', uae:'united arab emirates'}
    },
    instruments: {
      title: 'MUSICAL INSTRUMENTS',
      hint: 'Name a standard musical instrument.',
      answers: ['guitar','piano','violin','cello','viola','double bass','drums','flute','trumpet','trombone','tuba','saxophone','clarinet','oboe','bassoon','harp','ukulele','banjo','mandolin','accordion','harmonica','recorder','keyboard','organ','xylophone','tambourine','triangle','cymbals','maracas','conga','gong','sitar','bagpipes'],
      aliases: {drum:'drums', sax:'saxophone', 'bass guitar':'guitar', 'electric guitar':'guitar', 'acoustic guitar':'guitar'}
    },
    kitchen_items: {
      title: 'KITCHEN ITEMS',
      hint: 'Name something normally found in a kitchen.',
      answers: ['spoon','fork','knife','plate','bowl','cup','glass','mug','pan','pot','kettle','toaster','oven','stove','fridge','freezer','microwave','blender','mixer','whisk','grater','colander','cutting board','spatula','ladle','peeler','can opener','bottle opener','tongs','rolling pin','measuring cup','napkin'],
      aliases: {refrigerator:'fridge', cooker:'stove', saucepan:'pan', fryingpan:'pan', 'frying pan':'pan'}
    }
  });

  const config = Object.freeze({
    url: String(window.ASCENT_MULTIPLAYER?.url || '').replace(/\/$/, ''),
    anonKey: String(window.ASCENT_MULTIPLAYER?.anonKey || '')
  });
  const $ = id => document.getElementById(id);
  const screens = ['config','entry','lobby','round','results'];
  let session = readSession();
  let roomState = null;
  let syncTimer = null;
  let clockTimer = null;
  let syncInFlight = false;
  let realtimeSocket = null;
  let realtimeReconnectTimer = null;
  let realtimeTopic = '';
  let realtimeJoinRef = '';
  let realtimeRef = 0;
  let realtimeConnected = false;
  let serverClockOffsetMs = 0;
  let lastRoundNumber = null;
  let localAnswerKeys = new Set();

  const answerMaps = Object.freeze(Object.fromEntries(Object.entries(CATEGORIES).map(([key, category]) => {
    const map = new Map(category.answers.map(answer => [normaliseWord(answer), answer]));
    Object.entries(category.aliases || {}).forEach(([alias, answer]) => map.set(normaliseWord(alias), answer));
    return [key, map];
  })));

  function normaliseWord(value) {
    return String(value || '')
      .toLowerCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/[^a-z0-9 ]/g, ' ')
      .replace(/\s+/g, ' ')
      .trim();
  }

  function resolveWord(categoryKey, value) {
    return answerMaps[categoryKey]?.get(normaliseWord(value)) || null;
  }

  function configIsReady() {
    return /^https:\/\/[a-z0-9-]+\.supabase\.co$/i.test(config.url) && config.anonKey.length >= 20;
  }

  function randomBytes(length) {
    const bytes = new Uint8Array(length);
    if (window.crypto?.getRandomValues) return window.crypto.getRandomValues(bytes);
    for (let index = 0; index < bytes.length; index++) bytes[index] = Math.floor(Math.random() * 256);
    return bytes;
  }

  function makeRoomCode() {
    const bytes = randomBytes(6);
    return Array.from(bytes, byte => ROOM_CODE_ALPHABET[byte % ROOM_CODE_ALPHABET.length]).join('');
  }

  function makePlayerSecret() {
    const bytes = randomBytes(32);
    let binary = '';
    bytes.forEach(byte => { binary += String.fromCharCode(byte); });
    return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');
  }

  function cleanName(value) {
    return String(value || '').replace(/\s+/g, ' ').trim().slice(0, 18);
  }

  function cleanRoomCode(value) {
    return String(value || '').toUpperCase().replace(/[^A-Z2-9]/g, '').slice(0, 6);
  }

  function readSession() {
    try {
      const value = JSON.parse(sessionStorage.getItem(ROOM_SESSION_KEY) || 'null');
      return value && typeof value.roomCode === 'string' && typeof value.playerSecret === 'string' ? value : null;
    } catch (error) {
      return null;
    }
  }

  function storeSession(nextSession) {
    session = nextSession;
    try {
      if (session) sessionStorage.setItem(ROOM_SESSION_KEY, JSON.stringify(session));
      else sessionStorage.removeItem(ROOM_SESSION_KEY);
    } catch (error) {}
  }

  function showScreen(name) {
    screens.forEach(screen => $(`${screen}Screen`)?.classList.toggle('is-hidden', screen !== name));
    document.body.dataset.screen = name;
  }

  function setStatus(message = '', tone = '') {
    ['versusStatus','lobbyStatus','roundStatus','resultStatus'].forEach(id => {
      const status = $(id);
      if (!status) return;
      status.textContent = message;
      status.dataset.tone = tone;
      status.classList.toggle('is-empty', !message);
    });
  }

  function friendlyError(error) {
    const message = String(error?.message || error || 'Room service unavailable.');
    return message.replace(/^Error:\s*/i, '').replace(/\s+/g, ' ').trim();
  }

  async function rpc(functionName, argumentsObject) {
    if (!configIsReady()) throw new Error('The room service has not been configured yet.');
    const response = await fetch(`${config.url}/rest/v1/rpc/${functionName}`, {
      method: 'POST',
      headers: {
        apikey: config.anonKey,
        Authorization: `Bearer ${config.anonKey}`,
        'Content-Type': 'application/json',
        Accept: 'application/json',
        'X-Client-Info': 'ascent-versus/1.0'
      },
      body: JSON.stringify(argumentsObject)
    });
    const text = await response.text();
    let payload = null;
    try { payload = text ? JSON.parse(text) : null; } catch (error) { payload = null; }
    if (!response.ok) throw new Error(payload?.message || payload?.hint || text || 'The room service rejected that request.');
    return payload;
  }

  function realtimeEndpoint() {
    const endpoint = new URL(config.url);
    endpoint.protocol = endpoint.protocol === 'https:' ? 'wss:' : 'ws:';
    endpoint.pathname = '/realtime/v1/websocket';
    endpoint.search = '';
    endpoint.searchParams.set('apikey', config.anonKey);
    endpoint.searchParams.set('vsn', '1.0.0');
    return endpoint.toString();
  }

  function realtimeMessage(event, payload) {
    if (!realtimeSocket || realtimeSocket.readyState !== WebSocket.OPEN || !realtimeTopic) return;
    realtimeRef += 1;
    realtimeSocket.send(JSON.stringify([realtimeJoinRef, String(realtimeRef), realtimeTopic, event, payload]));
  }

  function stopRealtime() {
    clearTimeout(realtimeReconnectTimer);
    realtimeReconnectTimer = null;
    realtimeConnected = false;
    realtimeTopic = '';
    realtimeJoinRef = '';
    const socket = realtimeSocket;
    realtimeSocket = null;
    if (socket && (socket.readyState === WebSocket.OPEN || socket.readyState === WebSocket.CONNECTING)) {
      try { socket.close(1000, 'room session finished'); } catch (error) {}
    }
  }

  function scheduleRealtimeReconnect() {
    clearTimeout(realtimeReconnectTimer);
    if (!session || !configIsReady()) return;
    realtimeReconnectTimer = setTimeout(startRealtime, 3500);
  }

  function startRealtime() {
    if (!session || !configIsReady() || !('WebSocket' in window)) return;
    const topic = `realtime:ascent-${session.roomCode}`;
    if (realtimeSocket && realtimeTopic === topic && (realtimeSocket.readyState === WebSocket.OPEN || realtimeSocket.readyState === WebSocket.CONNECTING)) return;
    stopRealtime();
    realtimeTopic = topic;
    try {
      const socket = new WebSocket(realtimeEndpoint());
      realtimeSocket = socket;
      socket.addEventListener('open', () => {
        if (socket !== realtimeSocket) return;
        realtimeJoinRef = `join-${Date.now()}`;
        realtimeRef = 1;
        socket.send(JSON.stringify([realtimeJoinRef, String(realtimeRef), realtimeTopic, 'phx_join', {
          config: {broadcast: {ack: false, self: false}, presence: {key: ''}, postgres_changes: []},
          access_token: config.anonKey
        }]));
      });
      socket.addEventListener('message', event => {
        if (socket !== realtimeSocket) return;
        let message;
        try { message = JSON.parse(event.data); } catch (error) { return; }
        const [, , topicName, eventName, payload] = message;
        if (topicName !== realtimeTopic) return;
        if (eventName === 'phx_reply' && payload?.status === 'ok') {
          realtimeConnected = true;
          return;
        }
        if (eventName === 'broadcast' && payload?.event === 'ascent-state') void syncRoom();
      });
      socket.addEventListener('close', () => {
        if (socket !== realtimeSocket) return;
        realtimeSocket = null;
        realtimeConnected = false;
        scheduleRealtimeReconnect();
      });
      socket.addEventListener('error', () => {
        // Polling continues even when a project has Broadcast disabled or a network blocks WebSockets.
      });
    } catch (error) {
      realtimeSocket = null;
      scheduleRealtimeReconnect();
    }
  }

  function pokeRealtime() {
    if (!realtimeConnected) return;
    realtimeMessage('broadcast', {type: 'broadcast', event: 'ascent-state', payload: {}});
  }

  function playerFor(id) {
    return roomState?.players?.find(player => player.id === id) || null;
  }

  function ownPlayer() {
    return playerFor(roomState?.you?.id);
  }

  function opponent() {
    return roomState?.players?.find(player => player.id !== roomState?.you?.id) || null;
  }

  function labelForAnswer(answer) {
    return String(answer || '').replace(/\b\w/g, character => character.toUpperCase());
  }

  function renderChips(target, answers) {
    target.replaceChildren();
    (answers || []).forEach(answer => {
      const chip = document.createElement('li');
      chip.textContent = labelForAnswer(answer);
      target.appendChild(chip);
    });
  }

  function renderPlayerSlots() {
    const slots = $('lobbyPlayers');
    slots.replaceChildren();
    const players = roomState?.players || [];
    for (let index = 0; index < 2; index++) {
      const player = players[index];
      const item = document.createElement('li');
      item.className = player ? `player-slot connected${player.is_connected === false ? ' reconnecting' : ''}` : 'player-slot';
      const marker = document.createElement('span');
      marker.className = 'player-marker';
      marker.textContent = player ? String(index + 1).padStart(2, '0') : '…';
      const copy = document.createElement('div');
      const name = document.createElement('strong');
      const note = document.createElement('small');
      name.textContent = player ? player.name.toUpperCase() : 'WAITING FOR PLAYER';
      note.textContent = player ? (player.is_connected === false ? 'SIGNAL LOST / RECONNECTING' : player.is_host ? 'HOST / FLIGHT CONTROL' : 'CONNECTED / READY') : 'SHARE THE SIX-CHARACTER ROOM CODE';
      copy.append(name, note);
      item.append(marker, copy);
      slots.appendChild(item);
    }
  }

  function renderLobby() {
    $('roomCode').textContent = roomState.room_code;
    $('roomCodeCopy').dataset.code = roomState.room_code;
    renderPlayerSlots();
    const twoPlayers = roomState.players.length === 2;
    const twoConnected = twoPlayers && roomState.players.every(player => player.is_connected !== false);
    const host = Boolean(roomState.you?.is_host);
    $('startSprintButton').classList.toggle('is-hidden', !host);
    $('lobbyGuestNote').classList.toggle('is-hidden', host);
    $('startSprintButton').disabled = !twoConnected;
    $('startSprintButton').querySelector('span').textContent = twoConnected ? 'START 25 SEC SPRINT' : twoPlayers ? 'OPPONENT RECONNECTING' : 'WAITING FOR OPPONENT';
    $('lobbyGuestNote').textContent = twoConnected ? 'HOST IS ARMING THE FIRST SPRINT.' : twoPlayers ? 'HOST IS WAITING FOR YOUR SIGNAL TO RETURN.' : 'WAITING FOR THE HOST TO SHARE THIS ROOM.';
    showScreen('lobby');
  }

  function renderRound() {
    const category = CATEGORIES[roomState.category_key];
    const self = ownPlayer();
    const other = opponent();
    if (lastRoundNumber !== roomState.round_number) {
      lastRoundNumber = roomState.round_number;
      localAnswerKeys = new Set();
      $('sprintAnswer').value = '';
      renderChips($('liveAnswers'), []);
    }
    $('roundNumber').textContent = `ROUND ${String(roomState.round_number).padStart(2, '0')}`;
    $('roundCategory').textContent = category?.title || roomState.category_title || 'CATEGORY SIGNAL';
    $('roundHint').textContent = category?.hint || roomState.category_hint || 'Name as many accepted words as you can.';
    $('yourName').textContent = self?.name?.toUpperCase() || 'YOU';
    $('opponentName').textContent = other?.name?.toUpperCase() || 'OPPONENT';
    $('yourScore').textContent = String(self?.round_score || 0).padStart(2, '0');
    $('opponentScore').textContent = String(other?.round_score || 0).padStart(2, '0');
    renderChips($('liveAnswers'), [...localAnswerKeys]);
    showScreen('round');
    updateRoundClock();
  }

  function renderResults() {
    const self = ownPlayer();
    const other = opponent();
    const ownRound = Number(self?.round_score || 0);
    const otherRound = Number(other?.round_score || 0);
    const headline = ownRound === otherRound ? 'DEAD<br><em>EVEN.</em>' : ownRound > otherRound ? 'YOU TOOK<br><em>THE ROUND.</em>' : 'THEY TOOK<br><em>THE ROUND.</em>';
    $('resultHeadline').innerHTML = headline;
    $('resultRound').textContent = `ROUND ${String(roomState.round_number).padStart(2, '0')} · ${CATEGORIES[roomState.category_key]?.title || roomState.category_title || 'CATEGORY'}`;
    $('resultYouName').textContent = self?.name?.toUpperCase() || 'YOU';
    $('resultOpponentName').textContent = other?.name?.toUpperCase() || 'OPPONENT';
    $('resultYouScore').textContent = String(ownRound).padStart(2, '0');
    $('resultOpponentScore').textContent = String(otherRound).padStart(2, '0');
    $('resultTotal').textContent = `TOTAL · ${String(self?.score || 0).padStart(2, '0')} — ${String(other?.score || 0).padStart(2, '0')}`;
    const answerMap = roomState.answers || {};
    renderChips($('resultYourAnswers'), answerMap[self?.id] || []);
    renderChips($('resultOpponentAnswers'), answerMap[other?.id] || []);
    const host = Boolean(roomState.you?.is_host);
    $('nextSprintButton').classList.toggle('is-hidden', !host);
    $('resultGuestNote').classList.toggle('is-hidden', host);
    showScreen('results');
  }

  function updateServerClock(nextState) {
    const serverNow = Date.parse(nextState?.server_now || '');
    if (Number.isFinite(serverNow)) serverClockOffsetMs = serverNow - Date.now();
  }

  function roomNow() {
    return Date.now() + serverClockOffsetMs;
  }

  function renderState(nextState) {
    updateServerClock(nextState);
    roomState = nextState;
    if (!roomState || roomState.phase === 'closed') {
      resetToEntry('This room is closed.');
      return;
    }
    if (roomState.phase === 'lobby') renderLobby();
    else if (roomState.phase === 'playing') renderRound();
    else if (roomState.phase === 'results') renderResults();
    else resetToEntry('This room is no longer available.');
    scheduleSync(roomState.phase === 'playing' ? POLL_PLAYING_MS : POLL_IDLE_MS);
  }

  function updateRoundClock() {
    if (!roomState || roomState.phase !== 'playing') return;
    const startsAt = Date.parse(roomState.round_starts_at || '');
    const endsAt = Date.parse(roomState.round_ends_at || '');
    const now = roomNow();
    const beforeStart = Number.isFinite(startsAt) && now < startsAt;
    const remaining = Number.isFinite(endsAt) ? Math.max(0, Math.ceil((endsAt - now) / 1000)) : ROUND_LENGTH_SECONDS;
    const input = $('sprintAnswer');
    const submit = $('answerSubmit');
    if (beforeStart) {
      $('roundTimer').textContent = String(Math.max(0, Math.ceil((startsAt - now) / 1000))).padStart(2, '0');
      $('roundTimerLabel').textContent = 'GET READY';
      $('roundStateText').textContent = 'SAME CATEGORY. SAME CLOCK. GO ON ZERO.';
      input.disabled = true;
      submit.disabled = true;
      return;
    }
    $('roundTimer').textContent = String(remaining).padStart(2, '0');
    $('roundTimerLabel').textContent = remaining ? 'SECONDS' : 'LOCKING';
    $('roundStateText').textContent = remaining ? 'TYPE A WORD · PRESS ENTER · KEEP MOVING' : 'TIME. LOCKING BOTH SCOREBOARDS.';
    input.disabled = remaining === 0;
    submit.disabled = remaining === 0;
    if (remaining === 0) void syncRoom();
  }

  function scheduleClock() {
    clearInterval(clockTimer);
    clockTimer = setInterval(updateRoundClock, 120);
  }

  function scheduleSync(delay = POLL_IDLE_MS) {
    clearTimeout(syncTimer);
    if (!session || !configIsReady()) return;
    syncTimer = setTimeout(syncRoom, delay);
  }

  async function syncRoom() {
    if (!session || syncInFlight || !configIsReady()) return;
    syncInFlight = true;
    try {
      const next = await rpc('ascent_room_state', {p_room_code: session.roomCode, p_player_secret: session.playerSecret});
      renderState(next);
      setStatus('');
    } catch (error) {
      const message = friendlyError(error);
      if (/not found|expired|participant|closed/i.test(message)) resetToEntry(message);
      else {
        setStatus(message, 'error');
        scheduleSync(POLL_IDLE_MS * 2);
      }
    } finally {
      syncInFlight = false;
    }
  }

  function resetToEntry(message = '') {
    clearTimeout(syncTimer);
    clearInterval(clockTimer);
    stopRealtime();
    roomState = null;
    serverClockOffsetMs = 0;
    lastRoundNumber = null;
    localAnswerKeys = new Set();
    storeSession(null);
    showScreen('entry');
    setStatus(message, message ? 'error' : '');
  }

  async function createRoom(event) {
    event.preventDefault();
    const name = cleanName($('createName').value);
    if (name.length < 2) {
      setStatus('ENTER A NAME WITH AT LEAST TWO CHARACTERS.', 'error');
      return;
    }
    const button = $('createRoomButton');
    button.disabled = true;
    setStatus('OPENING A ROOM…');
    try {
      const playerSecret = makePlayerSecret();
      let next = null;
      let lastError = null;
      for (let attempt = 0; attempt < 6 && !next; attempt++) {
        const roomCode = makeRoomCode();
        try {
          next = await rpc('ascent_create_room', {p_room_code: roomCode, p_player_name: name, p_player_secret: playerSecret});
        } catch (error) {
          lastError = error;
          if (!/duplicate|unique/i.test(friendlyError(error))) throw error;
        }
      }
      if (!next) throw lastError || new Error('Could not reserve a room code.');
      storeSession({roomCode: next.room_code, playerSecret, playerName: name});
      startRealtime();
      renderState(next);
      pokeRealtime();
      setStatus('ROOM CREATED. SHARE THE CODE.', 'success');
    } catch (error) {
      setStatus(friendlyError(error), 'error');
    } finally {
      button.disabled = false;
    }
  }

  async function joinRoom(event) {
    event.preventDefault();
    const name = cleanName($('joinName').value);
    const roomCode = cleanRoomCode($('joinCode').value);
    if (name.length < 2 || roomCode.length !== 6) {
      setStatus('ENTER YOUR NAME AND ALL SIX ROOM-CODE CHARACTERS.', 'error');
      return;
    }
    const button = $('joinRoomButton');
    button.disabled = true;
    setStatus('JOINING ROOM…');
    try {
      const playerSecret = makePlayerSecret();
      const next = await rpc('ascent_join_room', {p_room_code: roomCode, p_player_name: name, p_player_secret: playerSecret});
      storeSession({roomCode: next.room_code, playerSecret, playerName: name});
      startRealtime();
      renderState(next);
      pokeRealtime();
      setStatus('CONNECTED. WAIT FOR THE HOST.', 'success');
    } catch (error) {
      setStatus(friendlyError(error), 'error');
    } finally {
      button.disabled = false;
    }
  }

  async function startSprint() {
    if (!session || !roomState?.you?.is_host) return;
    const button = $('startSprintButton');
    button.disabled = true;
    setStatus('SYNCING THE CATEGORY…');
    try {
      const next = await rpc('ascent_start_round', {
        p_room_code: session.roomCode,
        p_player_secret: session.playerSecret
      });
      renderState(next);
      pokeRealtime();
      setStatus('');
    } catch (error) {
      setStatus(friendlyError(error), 'error');
      button.disabled = false;
    }
  }

  async function submitAnswer(event) {
    event.preventDefault();
    if (!session || roomState?.phase !== 'playing') return;
    const input = $('sprintAnswer');
    const answerKey = resolveWord(roomState.category_key, input.value);
    if (!answerKey) {
      setStatus('NOT IN THIS CATEGORY. TRY ANOTHER WORD.', 'error');
      input.select();
      return;
    }
    if (localAnswerKeys.has(answerKey)) {
      setStatus('YOU ALREADY USED THAT WORD THIS ROUND.', 'error');
      input.select();
      return;
    }
    const startsAt = Date.parse(roomState.round_starts_at || '');
    const endsAt = Date.parse(roomState.round_ends_at || '');
    if ((Number.isFinite(startsAt) && roomNow() < startsAt) || (Number.isFinite(endsAt) && roomNow() > endsAt)) {
      setStatus('THE ANSWER WINDOW IS CLOSED.', 'error');
      return;
    }
    const button = $('answerSubmit');
    button.disabled = true;
    try {
      const result = await rpc('ascent_submit_answer', {
        p_room_code: session.roomCode,
        p_player_secret: session.playerSecret,
        p_round_number: roomState.round_number,
        p_answer_key: answerKey
      });
      if (!result?.accepted) {
        setStatus(result?.reason || 'THAT WORD WAS ALREADY COUNTED.', 'error');
        return;
      }
      localAnswerKeys.add(answerKey);
      input.value = '';
      renderChips($('liveAnswers'), [...localAnswerKeys]);
      setStatus('+1 LOCKED IN.', 'success');
      pokeRealtime();
      void syncRoom();
    } catch (error) {
      setStatus(friendlyError(error), 'error');
    } finally {
      button.disabled = false;
      input.focus({preventScroll: true});
    }
  }

  async function copyRoomCode() {
    const code = $('roomCodeCopy').dataset.code || roomState?.room_code || '';
    if (!code) return;
    try {
      await navigator.clipboard.writeText(code);
      setStatus('ROOM CODE COPIED.', 'success');
    } catch (error) {
      setStatus(`ROOM CODE: ${code}`, 'success');
    }
  }

  async function leaveRoom() {
    const oldSession = session;
    clearTimeout(syncTimer);
    clearInterval(clockTimer);
    if (oldSession) {
      try {
        await rpc('ascent_leave_room', {p_room_code: oldSession.roomCode, p_player_secret: oldSession.playerSecret});
        pokeRealtime();
      } catch (error) {}
    }
    resetToEntry('YOU LEFT THE ROOM.');
  }

  function wireEvents() {
    $('createForm').addEventListener('submit', createRoom);
    $('joinForm').addEventListener('submit', joinRoom);
    $('joinCode').addEventListener('input', event => { event.target.value = cleanRoomCode(event.target.value); });
    $('startSprintButton').addEventListener('click', startSprint);
    $('nextSprintButton').addEventListener('click', startSprint);
    $('answerForm').addEventListener('submit', submitAnswer);
    $('roomCodeCopy').addEventListener('click', copyRoomCode);
    $('leaveRoomButton').addEventListener('click', leaveRoom);
    $('leaveResultRoomButton').addEventListener('click', leaveRoom);
    window.addEventListener('visibilitychange', () => { if (!document.hidden) void syncRoom(); });
  }

  function init() {
    wireEvents();
    scheduleClock();
    if (!configIsReady()) {
      showScreen('config');
      setStatus('ONLINE ROOM SERVICE IS BEING CONNECTED.');
      return;
    }
    if (session) {
      setStatus('RECONNECTING TO YOUR ROOM…');
      startRealtime();
      void syncRoom();
    } else {
      showScreen('entry');
    }
  }

  window.ASCENT_VERSUS_DEBUG = Object.freeze({
    CATEGORIES,
    normaliseWord,
    resolveWord,
    makeRoomCode,
    makePlayerSecret,
    cleanRoomCode,
    configIsReady
  });

  init();
})();
