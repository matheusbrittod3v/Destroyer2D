<template>
   

    <div class="relative w-full h-screen bg-black text-white overflow-hidden">
      <!-- Canvas do jogo -->
      <canvas id="gameCanvas" class="w-full h-full"></canvas>
  
      <!-- HUD -->
      <div class="absolute top-0 left-0 w-full text-center z-10 p-4 bg-gradient-to-b from-black/70 to-transparent">
        <br>
  <br><br>
        <h1 class="text-4xl font-bold mb-2">🚀 Destroyer 2D</h1>
        <div class="text-lg">
          <span class="mr-6">Score: {{ stats.score }}</span>
          <span class="mr-6">Level: {{ stats.level }}</span>
          <span>Health: {{ stats.health }}%</span>
          
        </div>
      </div>
    </div>
  </template>
  
  <script setup>
  import { onMounted, reactive } from 'vue'
  
  // Estado reativo para armazenar as informações do jogo
  const stats = reactive({
    level: 1,
    phase: 'basic', // basic | medium | boss
    score: 0,
    health: 500,
    bossDefeated: false,
    phaseStartTime: Date.now(),
  })
  
  let burstCount = 0
let burstTimer = 0
let burstCooldown = 0
  let canvas, ctx
  let spaceship
  let bullets = []
  let enemies = []
  let enemyBullets = []
  let keys = {}
  let lastEnemySpawn = 0
  
  const COOLDOWN = 800
  const DAMAGE_PLAYER = 15
  const playerDamage = reactive({ value: 20 })

  
  // Inicialização principal do jogo
  onMounted(() => {
   

    setupCanvas()
    setupSpaceship()
    setupControls()
    setupTouchControls()
    
    gameLoop()
  })

  
  
  // Configuração do canvas
  function setupCanvas() {
    canvas = document.getElementById('gameCanvas')
    ctx = canvas.getContext('2d')
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
  }
  
  // Configuração da nave
  function setupSpaceship() {
    spaceship = {
      x: canvas.width / 2 - 15,
      y: canvas.height - 60,
      width: 30,
      height: 30,
      speed: 10,
    }
  }

  function setupTouchControls() {
  let isTouching = false

  // Offset vertical para manter a nave 80px acima do toque
  const verticalOffset = 120 // 80px acima do toque

  canvas.addEventListener('touchstart', (e) => {
    isTouching = true
    e.preventDefault()
  }, { passive: false })

  canvas.addEventListener('touchmove', (e) => {
    if (!isTouching) return
    const touch = e.touches[0]

    // Convertendo posição do toque em relação ao canvas
    const rect = canvas.getBoundingClientRect()
    const touchX = touch.clientX - rect.left
    const touchY = touch.clientY - rect.top - verticalOffset // Aplique o deslocamento de 80px

    // Move a nave em direção ao dedo
    const dx = touchX - (spaceship.x + spaceship.width / 2)
    const dy = touchY - (spaceship.y + spaceship.height / 2)

    const distance = Math.sqrt(dx * dx + dy * dy)

    // Defina uma velocidade proporcional à distância
    const moveSpeed = Math.min(distance, spaceship.speed)

    // Normalize o vetor direção
    const directionX = dx / distance
    const directionY = dy / distance

    if (!isNaN(directionX) && !isNaN(directionY)) {
      spaceship.x += directionX * moveSpeed
      spaceship.y += directionY * moveSpeed
    }

    // Impede que a nave saia da tela
    spaceship.x = Math.max(0, Math.min(canvas.width - spaceship.width, spaceship.x))
    spaceship.y = Math.max(0, Math.min(canvas.height - spaceship.height, spaceship.y))

    e.preventDefault()
  }, { passive: false })

  canvas.addEventListener('touchend', () => {
    isTouching = false
  })
}

function updatePlayerDamage() {
  playerDamage.value = 20 + (stats.level - 1) * 5
}


  
  // Controle do teclado
  function setupControls() {
    window.addEventListener('keydown', e => keys[e.key] = true)
    window.addEventListener('keyup', e => {
      keys[e.key] = false
    })
  }
  
  // Loop principal de atualização e renderização
  function gameLoop() {
    ctx.clearRect(0, 0, canvas.width, canvas.height)
  
    update()
    draw()
  
    requestAnimationFrame(gameLoop)
  }
  
  // Atualização dos elementos do jogo
  function update() {
    movePlayer()
    moveBullets()
    moveEnemyBullets()
    moveEnemies()
    handleCollisions()
    createEnemies()
    
  }
  
  // Desenhos na tela
  function draw() {
    drawSpaceship()
    drawBullets()
    drawEnemies()
    drawEnemyBullets()
  }
  
  // Movimento da nave
  function movePlayer() {
    if (keys['ArrowLeft'] && spaceship.x > 0) spaceship.x -= spaceship.speed
    if (keys['ArrowRight'] && spaceship.x < canvas.width - spaceship.width) spaceship.x += spaceship.speed
    if (keys['ArrowUp'] && spaceship.y > 0) spaceship.y -= spaceship.speed
    if (keys['ArrowDown'] && spaceship.y < canvas.height - spaceship.height) spaceship.y += spaceship.speed
    shoot() // Atira constantemente
  }
  
  // Controle de rajadas


// Função de disparo com rajadas
function shoot() {
  // Aguarda cooldown entre rajadas
  if (burstCooldown > 0) {
    burstCooldown--
    return
  }

  // Aguarda intervalo entre tiros de uma mesma rajada
  if (burstTimer > 0) {
    burstTimer--
    return
  }

  // Disparo individual da rajada
bullets.push({
  x: spaceship.x + spaceship.width / 2 - 2,
  y: spaceship.y,
  width: 5,
  height: 30,
  speed: stats.level > 1 ? 10 + stats.level * 0.2 : 10
})


  burstCount++
  burstTimer = 5 // Frames entre tiros dentro da mesma rajada

  // Após 4 tiros, inicia cooldown da próxima rajada
  if (burstCount >= 10) {
    burstCount = 0
    burstCooldown = stats.level > 1 ? 15 - stats.level * 0.2 : 15 // Frames de pausa entre rajadas
  }
}

  
  // Movimento dos tiros
  function moveBullets() {
    bullets = bullets.filter(b => b.y > 0)
    bullets.forEach(b => b.y -= b.speed)
  }
  
  // Movimento dos tiros inimigos
  function moveEnemyBullets() {
    enemyBullets = enemyBullets.filter(b => b.y < canvas.height)
    enemyBullets.forEach(b => b.y += b.speed)
  }
  
  // Movimento dos inimigos
  function moveEnemies() {
    enemies = enemies.filter(e => e.y < canvas.height)
    const level = stats.level
  
    enemies.forEach(enemy => {
      enemy.y += enemy.speed
  
      // Inimigos médios se movem para os lados
      if (enemy.type === 'medium') {
        enemy.x += Math.sin(enemy.y / 100) * 2
        enemy.x = Math.max(0, Math.min(canvas.width - enemy.width, enemy.x))
      }
  
      // Inimigos do tipo boss
      if (enemy.type === 'boss' && level >= 1) {
        handleBossMovement(enemy, level)
      }
  
      // Chance de disparo para inimigos
      const shootChance = 0.025 + level * 0.0050
      if ((enemy.type === 'medium' || enemy.type === 'basic') && Math.random() < shootChance) {
        enemyBullets.push({
          x: enemy.x + enemy.width / 2 - 2,
          y: enemy.y + enemy.height,
          width: 7,
          height: 10,
          speed: 5 + level * 0.5,
        })
      }
    })
  }
  
  function handleBossMovement(enemy, level) {
  // Detecta se é dispositivo móvel (exemplo simples com largura da tela)
  const isMobile = window.innerWidth <= 768;

  // Define tamanho original do boss (suponha que já esteja definido na criação)
  const originalWidth = enemy.originalWidth || enemy.width;
  const originalHeight = enemy.originalHeight || enemy.height;

  // Armazena o tamanho original se ainda não armazenado
  if (!enemy.originalWidth) enemy.originalWidth = enemy.width;
  if (!enemy.originalHeight) enemy.originalHeight = enemy.height;

  // Se for mobile, redimensiona para metade do tamanho original
  if (isMobile) {
    enemy.width = originalWidth / 2;
    enemy.height = originalHeight / 2;
  } else {
    // Caso contrário, mantém o tamanho original
    enemy.width = originalWidth;
    enemy.height = originalHeight;
  }

  // Atualiza canvas para caber na tela do dispositivo
  const maxWidth = window.innerWidth;
  const maxHeight = window.innerHeight;
  canvas.width = Math.min(canvas.width, maxWidth);
  canvas.height = Math.min(canvas.height, maxHeight);

  const canvasRight = canvas.width;
  const canvasBottom = canvas.height;

  // Corrige posição do boss para não sair da tela horizontalmente
  if (enemy.x <= 0) {
    enemy.x = 0;
    enemy.speed = Math.abs(enemy.speed); // força movimento para direita
  }
  else if (enemy.x + enemy.width >= canvasRight) {
    enemy.x = canvasRight - enemy.width;
    enemy.speed = -Math.abs(enemy.speed); // força movimento para esquerda
  }

  // Corrige posição vertical do boss
  if (enemy.y + enemy.height >= canvasBottom) {
    enemy.y = canvasBottom - enemy.height;
  }
  if (enemy.y < 0) {
    enemy.y = 0;
  }

  // Atualiza posição horizontal com velocidade
  enemy.x += enemy.speed;

  // Caso o boss esteja acima do topo (exemplo anterior), faz descida suave
  if (enemy.y < 0 && enemy.y + enemy.height > 0) {
    enemy.y += 2;
  }

  // Chance de disparar baseada no nível atual
  const shootChance = 0.02 + level * 0.001;
  if (Math.random() < shootChance) {
    shootMultiDirection(enemy);
  }
}


  
  // Disparo múltiplo realista de canhões posicionados nas laterais e cantos do boss
function shootMultiDirection(enemy) {
  // Define as "armas" (canhões) com posição e direção específicas
  const cannons = [
    // Cantos
    { offsetX: 0, offsetY: 0, dx: -1, dy: -1 },                                 // topo-esquerda
    { offsetX: enemy.width, offsetY: 0, dx: 1, dy: -1 },                        // topo-direita
    { offsetX: 0, offsetY: enemy.height, dx: -1, dy: 1 },                       // baixo-esquerda
    { offsetX: enemy.width, offsetY: enemy.height, dx: 1, dy: 1 },             // baixo-direita

    // Laterais
    { offsetX: enemy.width / 2, offsetY: 0, dx: 0, dy: -1 },                    // topo-centro
    { offsetX: 0, offsetY: enemy.height / 2, dx: -1, dy: 0 },                   // meio-esquerda
    { offsetX: enemy.width, offsetY: enemy.height / 2, dx: 1, dy: 0 },          // meio-direita
    { offsetX: enemy.width / 2, offsetY: enemy.height, dx: 0, dy: 1 },          // baixo-centro
  ];

  cannons.forEach(cannon => {
    enemyBullets.push({
      x: enemy.x + cannon.offsetX - 2,
      y: enemy.y + cannon.offsetY - 5,
      width: 4,
      height: 10,
      speed: 2 + stats.level * 0.2,
      dx: cannon.dx,
      dy: cannon.dy,
    });
  });
}

  
  // Criação de inimigos com base no nível
  function createEnemies() {
    const now = Date.now()
    if (now - lastEnemySpawn < COOLDOWN || enemies.length >= 10) return
  
    const level = stats.level
    const elapsed = (now - stats.phaseStartTime) / 1000
  
    const baseHealth = 30 + level * 15
    const baseSpeed = 1.5 + level * 0.5
    const baseDamage = 10 + level * 5
  
    if (elapsed >= 30 && stats.phase !== 'boss') {
      stats.phase = stats.phase === 'basic' ? 'medium' : 'boss'
      stats.phaseStartTime = now
    }
  
    if (stats.phase === 'basic') {
      spawnEnemy('basic', 50, 20, baseSpeed, baseHealth, baseDamage)
    } else if (stats.phase === 'medium') {
      spawnEnemy('medium', 80, 25, baseSpeed * 1.2, baseHealth * 1.5, baseDamage * 1.2)
    } else if (stats.phase === 'boss' && !stats.bossDefeated && !enemies.find(e => e.type === 'boss')) {
      spawnEnemy('boss', 500, 100, 0.6 + level * 0.1, baseHealth * 10, baseDamage * 3, canvas.width / 2 - 100)
    }
  
    lastEnemySpawn = now
  }
  
  // Função de criação genérica de inimigos
  function spawnEnemy(type, width, height, speed, health, damage, x = Math.random() * (canvas.width - width)) {
    enemies.push({
      x, y: 0, width, height, speed,
      health, maxHealth: health,
      damage, type
    })
  }
  
  // Função de colisão
  function handleCollisions() {
    // Colisão de tiros com inimigos
    for (let i = bullets.length - 1; i >= 0; i--) {
      const bullet = bullets[i]
      for (let j = enemies.length - 1; j >= 0; j--) {
        const enemy = enemies[j]
        if (checkCollision(bullet, enemy)) {
            enemy.health -= playerDamage.value


          bullets.splice(i, 1)
          if (enemy.health <= 0) {
            enemies.splice(j, 1)
            stats.score += enemy.type === 'boss' ? 100 : 10
            if (enemy.type === 'boss') {
              stats.bossDefeated = true
              nextLevel()
            }
          }
          break
        }
      }
    }
  
    // Colisão de tiros inimigos com jogador
for (let i = enemyBullets.length - 1; i >= 0; i--) {
  const bullet = enemyBullets[i]
  if (checkCollision(bullet, spaceship)) {
    enemyBullets.splice(i, 1)
    stats.health -= DAMAGE_PLAYER

    if (stats.health <= 0) {
      Swal.fire({
        icon: 'error',
        title: '💀 Game Over!',
        text: `Seu score: ${stats.score}`,
        confirmButtonText: 'Recomeçar',
        allowOutsideClick: false,
        allowEscapeKey: false
      }).then(() => {
        location.reload()
      })
    }
  }
}

  
    // Colisão de inimigos com jogador (Game Over)
    for (let e = enemies.length - 1; e >= 0; e--) {
      
    }
  }
  
  // Função para verificar colisão entre dois objetos
  function checkCollision(a, b) {
    return a.x < b.x + b.width &&
           a.x + a.width > b.x &&
           a.y < b.y + b.height &&
           a.y + a.height > b.y
  }
  
  // Função para avançar de nível
function nextLevel() {
  stats.level++

  // Aumenta 100 de vida mantendo a vida atual
  stats.health += 100

  stats.phase = 'basic'
  stats.bossDefeated = false
  stats.phaseStartTime = Date.now()
  updatePlayerDamage()
}

  
  // Funções para desenhar os elementos
  function drawSpaceship() {
    ctx.fillStyle = 'lime'
    ctx.fillRect(spaceship.x, spaceship.y, spaceship.width, spaceship.height)
  }
  
  function drawBullets() {
    ctx.fillStyle = 'red'
    bullets.forEach(b => ctx.fillRect(b.x, b.y, b.width, b.height))
  }
  
  function drawEnemyBullets() {
    ctx.fillStyle = 'yellow'
    enemyBullets.forEach(b => ctx.fillRect(b.x, b.y, b.width, b.height))
  }
  
  function drawEnemies() {
    enemies.forEach(e => {
      ctx.fillStyle = e.type === 'basic' ? 'red' : e.type === 'medium' ? 'orange' : 'purple'
      ctx.fillRect(e.x, e.y, e.width, e.height)
  
      ctx.fillStyle = 'green'
      ctx.fillRect(e.x, e.y - 8, (e.health / e.maxHealth) * e.width, 5)
    })
  }
  </script>
  