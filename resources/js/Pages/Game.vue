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
          <span class="mr-6">Shield: {{ shieldValue }}%</span>
          <span>Health: {{ stats.health }}%</span>
          
        </div>
      </div>
    </div>
  </template>
  
  <script setup>
  import { onMounted, reactive } from 'vue'
  import { ref } from 'vue'
const shieldValue = ref(100)
  
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
  let bonuses = []  // array para armazenar os bônus ativos

  
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



  let basicEnemyImage = new Image();
basicEnemyImage.src = 'navs/basic.png'; // Caminho da imagem para inimigos básicos
basicEnemyImage.onload = () => {
  console.log('Imagem da nave inimiga básica carregada com sucesso!');
};
basicEnemyImage.onerror = () => {
  
};

let mediumEnemyImage = new Image();
mediumEnemyImage.src = 'navs/medium.png'; // Substitua pelo caminho correto da imagem
mediumEnemyImage.onload = () => {
  
};
mediumEnemyImage.onerror = () => {
  
};

let bossEnemyImage = new Image();
bossEnemyImage.src = 'navs/boss.png'; // Substitua pelo caminho correto da imagem
bossEnemyImage.onload = () => {
  
};
bossEnemyImage.onerror = () => {
  
};








  function updateShieldValue() {
  shieldValue.value = Math.round(spaceship.shield)
}
  
  // Configuração do canvas
  function setupCanvas() {
  canvas = document.getElementById('gameCanvas');
  ctx = canvas.getContext('2d');
  const isMobile = window.innerWidth <= 768;
  // Reduz a resolução em dispositivos móveis
  if (isMobile) {
    canvas.width = window.innerWidth * 0.75; // Reduz para 75% da largura
    canvas.height = window.innerHeight * 0.75; // Reduz para 75% da altura
  } else {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
  }
  // Ajusta o estilo para ocupar a tela inteira mesmo com resolução menor
  canvas.style.width = `${window.innerWidth}px`;
  canvas.style.height = `${window.innerHeight}px`;
}
  
  function setupSpaceship() {
  spaceship = {
    x: canvas.width / 2 - 15,
    y: canvas.height - 60,
    width: 30,
    height: 30,
    speed: 10,
    shield: 1000,
    maxShield: 1000,
    image: new Image() // Adiciona a imagem ao objeto da nave
  };
  // Defina o caminho para o arquivo PNG da nave
  spaceship.image.src = '/navs/padraoplayer.png'; // Substitua pelo caminho correto da imagem
  // Certifique-se de que a imagem está carregada antes de iniciar o jogo
  spaceship.image.onload = () => {
    console.log('Imagem da nave carregada com sucesso!');
  };
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
  function gameLoop(timestamp) {
  // Detecta se é dispositivo móvel
  const isMobile = window.innerWidth <= 768;
  // Controla FPS (30 para mobile, 60 para desktop)
  const targetFPS = isMobile ? 30 : 60;
  const frameInterval = 1000 / targetFPS;

  if (!gameLoop.lastTime) gameLoop.lastTime = timestamp;
  const deltaTime = timestamp - gameLoop.lastTime;

  if (deltaTime >= frameInterval) {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    update();
    draw();
    gameLoop.lastTime = timestamp;
  }

  requestAnimationFrame(gameLoop);
}
  
  // Atualização dos elementos do jogo
  function update() {
  movePlayer();
  moveBullets();
  moveEnemyBullets();
  moveEnemies();
  moveBonuses();           // <- adiciona aqui o movimento dos bônus
  updateShieldValue();
  handleCollisions();
  createEnemies();

 // Controle de spawn do bônus, intervalo diminui 0,2s a cada nível, mínimo 2 segundos
 const now = Date.now()
  if (!update.lastBonusSpawn) update.lastBonusSpawn = 0

  const baseInterval = 10000 // 10 segundos em ms
  const decreasePerLevel = 200 // 0.2 segundos em ms
  const minInterval = 2000 // intervalo mínimo de 2 segundos

  const interval = Math.max(minInterval, baseInterval - decreasePerLevel * (stats.level  + 1))

  if (now - update.lastBonusSpawn > interval) {
    spawnBonus()
    update.lastBonusSpawn = now
  }
  
  
}

  
  // Desenhos na tela
  function draw() {
  // Desenha todos os elementos de uma vez, minimizando mudanças de estado
  drawSpaceship();
  drawBullets();
  drawEnemyBullets();
  drawEnemies();
  drawBonuses();
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
  
      if (enemy.type === 'medium') {
  const frequency = enemy.moveFrequency || 0.03
  const amplitude = enemy.moveAmplitude || 20
  const phase = enemy.movePhase || 0

  // Movimento senoidal com variação individual
  enemy.x += Math.sin(enemy.y * frequency + phase) * (amplitude * 0.05)

  // Limita dentro da tela
  enemy.x = Math.max(0, Math.min(canvas.width - enemy.width, enemy.x))
}

  
      // Inimigos do tipo boss
      if (enemy.type === 'boss' && level >= 1) {
        handleBossMovement(enemy, level)
      }
  
      // Chance de disparo para inimigos
      const shootChance = 0.020 + level * 0.02
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
  const shootChance = 0.04 + level * 0.01;
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


function spawnBonus() {
  if (bonuses.length >= 3) return; // Limite máximo de bônus simultâneos

  // Gera posição aleatória dentro da tela (evitando áreas extremas)
  const width = 45;
  const height = 45;
  const x = Math.random() * (canvas.width - width);
  const y = -height;  // começa acima da tela para cair

  // Define tipo do bônus e multiplicador (x1, x2, x3)
  // 50% chance vida, 50% escudo
  const type = Math.random() < 0.5 ? 'health' : 'shield';
  // Multiplicador entre 1, 2 e 3 (probabilidade distribuída)
  const multiplier = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10,][Math.floor(Math.random() * 10)];
  // Valor base (em %)
  const baseValue = 10;

  bonuses.push({
    x, y, width, height,
    speed: 2,
    type,
    multiplier,
    value: baseValue,
    collected: false,
  });
}
function moveBonuses() {
  bonuses = bonuses.filter(bonus => bonus.y < canvas.height && !bonus.collected);

  bonuses.forEach(bonus => {
    bonus.y += bonus.speed;
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
  
  function spawnEnemy(type, width, height, speed, health, damage, x = Math.random() * (canvas.width - width)) {
  let shield = 0;
  let maxShield = 0;
  if (type === 'medium') {
    maxShield = 30 + stats.level * 20;
    shield = maxShield;
  } else if (type === 'boss') {
    maxShield = 150 + stats.level * 50;
    shield = maxShield;
  }

  const enemy = {
    x, y: 0, width, height, speed,
    health, maxHealth: health,
    damage, type,
    shield,
    maxShield
  };

  // Adiciona a imagem correspondente ao tipo de inimigo
  if (type === 'basic') {
    enemy.image = basicEnemyImage;
  } else if (type === 'medium') {
    enemy.image = mediumEnemyImage;
  } else if (type === 'boss') {
    enemy.image = bossEnemyImage;
  }

  enemies.push(enemy);
}
  
function updatePlayerShield() {
  // Define o escudo máximo baseado no level (por exemplo: escala linear ou exponencial)
  spaceship.maxShield = 100 + (stats.level - 1) * 50 // escudo base + 50 por level
  spaceship.shield = Math.min(spaceship.shield + 25, spaceship.maxShield) // recarrega 25 por level up
}




function handleCollisions() {
  // Colisão tiros com inimigos (já existe)

  for (let i = bullets.length - 1; i >= 0; i--) {
    const bullet = bullets[i];

    // Checa colisão com bônus
    for (let k = bonuses.length - 1; k >= 0; k--) {
      const bonus = bonuses[k];
      if (checkCollision(bullet, bonus)) {
        applyBonus(bonus);
        bonuses.splice(k, 1);
        bullets.splice(i, 1);
        break;
      }
    }

    // Checa colisão com inimigos (existente)
    for (let j = enemies.length - 1; j >= 0; j--) {
      const enemy = enemies[j];
      if (checkCollision(bullet, enemy)) {
        let damage = playerDamage.value;

        if (enemy.shield > 0) {
          if (enemy.shield >= damage) {
            enemy.shield -= damage;
            damage = 0;
          } else {
            damage -= enemy.shield;
            enemy.shield = 0;
          }
        }

        if (damage > 0) {
          enemy.health -= damage;
        }

        bullets.splice(i, 1);

        if (enemy.health <= 0) {
          enemies.splice(j, 1);
          stats.score += enemy.type === 'boss' ? 100 : 10;
          if (enemy.type === 'boss') {
            stats.bossDefeated = true;
            nextLevel();
          }
        }
        break;
      }
    }
  }



          
  
  for (let i = enemyBullets.length - 1; i >= 0; i--) {
  const bullet = enemyBullets[i]
  if (checkCollision(bullet, spaceship)) {
    enemyBullets.splice(i, 1)
    let damage = DAMAGE_PLAYER;

    if (spaceship.shield > 0) {
      if (spaceship.shield >= damage) {
        spaceship.shield -= damage
        damage = 0
      } else {
        damage -= spaceship.shield
        spaceship.shield = 0
      }
    }

    if (damage > 0) {
      stats.health -= damage
    }

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
  



  function applyBonus(bonus) {
  const totalValue = bonus.value * bonus.multiplier;

  if (bonus.type === 'health') {
    stats.health = Math.min(stats.health + totalValue, 1000); // limite max de vida (ajuste)
  } else if (bonus.type === 'shield') {
    spaceship.shield = Math.min(spaceship.shield + totalValue, spaceship.maxShield);
    updateShieldValue();
  }
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

function drawSpaceship() {
  if (spaceship.image.complete) {
    ctx.drawImage(spaceship.image, spaceship.x, spaceship.y, spaceship.width, spaceship.height);
  } else {
    ctx.fillStyle = 'lime';
    ctx.fillRect(spaceship.x, spaceship.y, spaceship.width, spaceship.height);
  }
  // Desenha barras de escudo e vida apenas se necessário
  if (spaceship.maxShield > 0) {
    ctx.fillStyle = 'gray';
    ctx.fillRect(spaceship.x, spaceship.y - 12, spaceship.width, 6);
    ctx.fillStyle = 'deepskyblue';
    ctx.fillRect(spaceship.x, spaceship.y - 12, (spaceship.shield / spaceship.maxShield) * spaceship.width, 6);
  }
  const maxHealth = 500;
  if (maxHealth > 0) {
    ctx.fillStyle = 'gray';
    ctx.fillRect(spaceship.x, spaceship.y - 6, spaceship.width, 6);
    ctx.fillStyle = 'green';
    ctx.fillRect(spaceship.x, spaceship.y - 6, (stats.health / maxHealth) * spaceship.width, 6);
  }
}
  
function drawBullets() {
  if (bullets.length === 0) return; // Evita operações se não houver elementos
  ctx.fillStyle = 'red';
  bullets.forEach(b => ctx.fillRect(b.x, b.y, b.width, b.height));
}

function drawEnemyBullets() {
  if (enemyBullets.length === 0) return; // Evita operações se não houver elementos
  ctx.fillStyle = 'yellow';
  enemyBullets.forEach(b => ctx.fillRect(b.x, b.y, b.width, b.height));
}
  

function drawBonuses() {
  if (bonuses.length === 0) return; // Evita operações se não houver bônus
  bonuses.forEach(bonus => {
    ctx.fillStyle = bonus.type === 'health' ? 'green' : 'deepskyblue';
    ctx.fillRect(bonus.x, bonus.y, bonus.width, bonus.height);
    // Desenha texto apenas se necessário
    ctx.fillStyle = 'white';
    ctx.font = '16px Arial';
    ctx.fillText('x' + bonus.multiplier, bonus.x + 5, bonus.y + 18);
  });
}

function drawEnemies() {
  const isMobile = window.innerWidth <= 768;
  enemies.forEach(e => {
    // Ajusta dimensões do boss em mobile para reduzir carga de renderização
    if (isMobile && e.type === 'boss') {
      e.width = e.originalWidth ? e.originalWidth / 2 : e.width / 2;
      e.height = e.originalHeight ? e.originalHeight / 2 : e.height / 2;
    }
    // Desenha a imagem se estiver carregada
    if (e.image && e.image.complete) {
      ctx.drawImage(e.image, e.x, e.y, e.width, e.height);
    } else {
      ctx.fillStyle = e.type === 'basic' ? 'red' : e.type === 'medium' ? 'orange' : 'purple';
      ctx.fillRect(e.x, e.y, e.width, e.height);
    }
    // Desenha barras de escudo e vida apenas se necessário
    if (e.maxShield > 0) {
      ctx.fillStyle = 'gray';
      ctx.fillRect(e.x, e.y - 16, e.width, 5);
      ctx.fillStyle = 'lightblue';
      ctx.fillRect(e.x, e.y - 16, (e.shield / e.maxShield) * e.width, 5);
    }
    ctx.fillStyle = 'green';
    ctx.fillRect(e.x, e.y - 8, (e.health / e.maxHealth) * e.width, 5);
  });
}
  </script>
  