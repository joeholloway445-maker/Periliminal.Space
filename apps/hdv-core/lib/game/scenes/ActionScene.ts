import Phaser from 'phaser'
import type { FactionId } from '@/types/character'
import { RACES } from '@/lib/game/data/races'
import { FACTIONS } from '@/lib/game/data/factions'

const FACTION_IDS: FactionId[] = ['veiled_current', 'sovereign_crown', 'wildlands_ascendants']
const FACTION_TEX = ['enemy_tri', 'enemy_diamond', 'enemy_square']

interface Enemy {
  sprite: Phaser.Physics.Arcade.Sprite
  hp: number
  maxHp: number
  hpBar: Phaser.GameObjects.Graphics
  attackCooldown: number
  speed: number
  dead: boolean
}

export class ActionScene extends Phaser.Scene {
  // Player
  private player!: Phaser.Physics.Arcade.Sprite
  private playerMaxHp = 120
  private playerHp = 120
  private playerTintHex = 0xa855f7

  // Abilities
  private dashCooldown = 0
  private strikeCooldown = 0
  private jumpCooldown = 0
  private isDashing = false
  private dashTimer = 0
  private isInvincible = false
  private invincibleTimer = 0

  // Enemies
  private enemies: Enemy[] = []
  private enemyGroup!: Phaser.Physics.Arcade.Group

  // Wave
  private wave = 0
  private kills = 0
  private over = false

  // HUD
  private integrityFill!: Phaser.GameObjects.Graphics
  private integrityLabel!: Phaser.GameObjects.Text
  private waveLabel!: Phaser.GameObjects.Text
  private killLabel!: Phaser.GameObjects.Text
  private hudBarX = 0
  private hudBarY = 0
  private hudBarW = 0
  private hudBarH = 16
  private strikeBtn!: Phaser.GameObjects.Text
  private dashBtn!: Phaser.GameObjects.Text
  private jumpBtn!: Phaser.GameObjects.Text

  // Input
  private cursors!: Phaser.Types.Input.Keyboard.CursorKeys
  private wKey!: Phaser.Input.Keyboard.Key
  private aKey!: Phaser.Input.Keyboard.Key
  private sKey!: Phaser.Input.Keyboard.Key
  private dKey!: Phaser.Input.Keyboard.Key

  constructor() {
    super({ key: 'ActionScene' })
  }

  init() {
    this.wave = 0
    this.kills = 0
    this.over = false
    this.playerHp = this.playerMaxHp
    this.enemies = []
    this.isDashing = false
    this.dashTimer = 0
    this.isInvincible = false
    this.invincibleTimer = 0
    this.dashCooldown = 0
    this.strikeCooldown = 0
    this.jumpCooldown = 0
  }

  create() {
    const { width, height } = this.cameras.main

    this.generateTextures()

    this.drawArena(width, height)

    this.enemyGroup = this.physics.add.group()

    this.player = this.physics.add.sprite(width / 2, height / 2, 'action_player')
    this.player.setTint(this.playerTintHex)
    this.player.setCollideWorldBounds(true)
    ;(this.player.body as Phaser.Physics.Arcade.Body).setCircle(14, 2, 2)

    this.cursors = this.input.keyboard!.createCursorKeys()
    this.wKey = this.input.keyboard!.addKey(Phaser.Input.Keyboard.KeyCodes.W)
    this.aKey = this.input.keyboard!.addKey(Phaser.Input.Keyboard.KeyCodes.A)
    this.sKey = this.input.keyboard!.addKey(Phaser.Input.Keyboard.KeyCodes.S)
    this.dKey = this.input.keyboard!.addKey(Phaser.Input.Keyboard.KeyCodes.D)

    this.buildHud(width, height)
    this.buildButtons(width, height)

    this.add
      .text(44, 38, '← MODES', {
        fontFamily: 'monospace',
        fontSize: '13px',
        color: '#ef4444',
      })
      .setDepth(10)
      .setInteractive({ useHandCursor: true })
      .on('pointerdown', () => {
        this.enemies.forEach((e) => { if (!e.dead) e.dead = true })
        this.scene.start('ModeSelectorScene')
      })

    fetch('/api/character/current')
      .then((r) => (r.ok ? r.json() : null))
      .then((char) => {
        if (!char || this.over) return
        const race = RACES.find((r) => r.id === char.race)
        if (race) {
          this.playerTintHex = race.texture.tintHex
          this.player.setTint(race.texture.tintHex)
        }
      })
      .catch(() => {})

    this.time.delayedCall(900, () => this.startNextWave())
  }

  private generateTextures() {
    const make = (key: string, fn: (g: Phaser.GameObjects.Graphics) => void, w: number, h: number) => {
      if (this.textures.exists(key)) return
      const g = this.add.graphics()
      fn(g)
      g.generateTexture(key, w, h)
      g.destroy()
    }

    make('action_player', (g) => {
      g.fillStyle(0xffffff)
      g.fillCircle(16, 16, 14)
    }, 32, 32)

    make('enemy_tri', (g) => {
      g.fillStyle(0xffffff)
      g.fillTriangle(16, 1, 1, 30, 31, 30)
    }, 32, 32)

    make('enemy_diamond', (g) => {
      g.fillStyle(0xffffff)
      g.fillTriangle(16, 1, 1, 16, 16, 31)
      g.fillTriangle(16, 1, 31, 16, 16, 31)
    }, 32, 32)

    make('enemy_square', (g) => {
      g.fillStyle(0xffffff)
      g.fillRect(3, 3, 26, 26)
    }, 32, 32)

    make('strike_ring', (g) => {
      g.lineStyle(4, 0xffffff, 1)
      g.strokeCircle(48, 48, 44)
    }, 96, 96)
  }

  private drawArena(width: number, height: number) {
    this.add.rectangle(width / 2, height / 2, width, height, 0x0a0a14)

    const cx = width / 2
    const cy = height / 2
    const r = Math.min(width, height) * 0.44

    const g = this.add.graphics()

    // Floor disc
    g.fillStyle(0x160828, 1)
    g.fillCircle(cx, cy, r)

    // Outer warning ring
    g.lineStyle(4, 0xef4444, 0.45)
    g.strokeCircle(cx, cy, r)

    // Inner glow rings
    const rings = [0.82, 0.62, 0.4]
    rings.forEach((ratio, i) => {
      g.lineStyle(i === 0 ? 2 : 1, 0x7c3aed, i === 0 ? 0.6 : 0.25)
      g.strokeCircle(cx, cy, r * ratio)
    })

    // Cardinal cross
    g.lineStyle(1, 0x7c3aed, 0.12)
    g.lineBetween(cx - r, cy, cx + r, cy)
    g.lineBetween(cx, cy - r, cx, cy + r)

    // Center mark
    g.fillStyle(0xa855f7, 0.25)
    g.fillCircle(cx, cy, 5)

    // 4 pillar nodes
    const angles = [Math.PI * 0.25, Math.PI * 0.75, Math.PI * 1.25, Math.PI * 1.75]
    angles.forEach((a) => {
      const px = cx + Math.cos(a) * r * 0.66
      const py = cy + Math.sin(a) * r * 0.66
      g.fillStyle(0x2a1040, 1)
      g.fillCircle(px, py, 11)
      g.lineStyle(2, 0xa855f7, 0.85)
      g.strokeCircle(px, py, 11)

      const pulse = this.add.graphics()
      pulse.lineStyle(2, 0xa855f7, 0.35)
      pulse.strokeCircle(px, py, 19)
      this.tweens.add({ targets: pulse, alpha: 0, duration: 1100 + Math.random() * 400, yoyo: true, repeat: -1 })
    })
  }

  private buildHud(width: number, height: number) {
    const barW = Math.min(width * 0.46, 280)
    const barH = this.hudBarH
    const barX = width / 2 - barW / 2
    const barY = 16

    this.hudBarX = barX
    this.hudBarY = barY
    this.hudBarW = barW

    const bgGfx = this.add.graphics().setDepth(10)
    bgGfx.fillStyle(0x0a0a14)
    bgGfx.fillRect(barX, barY, barW, barH)
    bgGfx.lineStyle(1, 0xef4444, 0.5)
    bgGfx.strokeRect(barX, barY, barW, barH)

    this.integrityFill = this.add.graphics().setDepth(11)

    this.add.text(barX + 2, barY - 13, 'INTEGRITY', {
      fontFamily: 'monospace',
      fontSize: '10px',
      color: '#ef4444',
      letterSpacing: 2,
    }).setDepth(10)

    this.integrityLabel = this.add
      .text(width / 2, barY + barH / 2, '', { fontFamily: 'monospace', fontSize: '10px', color: '#e2e8f0' })
      .setOrigin(0.5, 0.5)
      .setDepth(12)

    this.waveLabel = this.add
      .text(14, 14, 'WAVE 1', { fontFamily: 'monospace', fontSize: '13px', color: '#a855f7' })
      .setDepth(10)

    this.killLabel = this.add
      .text(width - 14, 14, 'KILLS: 0', { fontFamily: 'monospace', fontSize: '13px', color: '#ef4444' })
      .setOrigin(1, 0)
      .setDepth(10)

    this.redrawIntegrityBar()
  }

  private redrawIntegrityBar() {
    const ratio = Phaser.Math.Clamp(this.playerHp / this.playerMaxHp, 0, 1)
    const color = ratio > 0.5 ? 0x22c55e : ratio > 0.25 ? 0xf59e0b : 0xef4444

    this.integrityFill.clear()
    this.integrityFill.fillStyle(color, 1)
    this.integrityFill.fillRect(this.hudBarX + 1, this.hudBarY + 1, (this.hudBarW - 2) * ratio, this.hudBarH - 2)

    this.integrityLabel.setText(`${Math.max(0, this.playerHp)} / ${this.playerMaxHp}`)
    this.waveLabel.setText(`WAVE ${Math.max(1, this.wave)}`)
    this.killLabel.setText(`KILLS: ${this.kills}`)
  }

  private buildButtons(width: number, height: number) {
    const btnY = height - 34
    const gap = Math.min(width * 0.28, 160)

    const mkBtn = (label: string, x: number, bg: string, cb: () => void) => {
      const btn = this.add
        .text(x, btnY, `[ ${label} ]`, {
          fontFamily: 'monospace',
          fontSize: '13px',
          color: '#e2e8f0',
          backgroundColor: bg,
          padding: { x: 14, y: 7 },
        })
        .setOrigin(0.5)
        .setDepth(10)
        .setInteractive({ useHandCursor: true })
      btn.on('pointerover', () => btn.setAlpha(0.8))
      btn.on('pointerout', () => btn.setAlpha(1))
      btn.on('pointerdown', cb)
      return btn
    }

    this.strikeBtn = mkBtn('STRIKE', width / 2 - gap, '#7c2020', () => this.doStrike())
    this.dashBtn   = mkBtn('DASH',   width / 2,       '#1e3a5f', () => this.doDash())
    this.jumpBtn   = mkBtn('JUMP',   width / 2 + gap, '#3b1f5e', () => this.doJump())
  }

  private startNextWave() {
    if (this.over) return
    this.wave++
    this.enemies = []
    this.enemyGroup.clear(true, true)
    this.redrawIntegrityBar()

    const { width, height } = this.cameras.main
    const ann = this.add
      .text(width / 2, height / 2, `WAVE  ${this.wave}`, {
        fontFamily: 'monospace',
        fontSize: '42px',
        color: '#ef4444',
        stroke: '#000000',
        strokeThickness: 4,
      })
      .setOrigin(0.5)
      .setDepth(20)

    this.tweens.add({
      targets: ann,
      alpha: 0,
      y: height / 2 - 70,
      duration: 1100,
      ease: 'Power2',
      onComplete: () => ann.destroy(),
    })

    const count = Math.min(3 + this.wave * 2, 22)
    this.spawnEnemies(count)
  }

  private spawnEnemies(count: number) {
    const { width, height } = this.cameras.main
    const cx = width / 2
    const cy = height / 2
    const arenaR = Math.min(width, height) * 0.41

    for (let i = 0; i < count; i++) {
      const angle = (Math.PI * 2 * i) / count + (Math.random() - 0.5) * 0.4
      const dist = arenaR * (0.68 + Math.random() * 0.22)
      const ex = cx + Math.cos(angle) * dist
      const ey = cy + Math.sin(angle) * dist

      const fi = Math.floor(Math.random() * 3)
      const factionColor = FACTIONS[FACTION_IDS[fi]].colorScheme.glowHex

      const sprite = this.physics.add.sprite(ex, ey, FACTION_TEX[fi])
      sprite.setTint(factionColor)
      ;(sprite.body as Phaser.Physics.Arcade.Body).setCircle(12, 4, 4)

      this.enemyGroup.add(sprite)

      const hpBar = this.add.graphics().setDepth(6)
      const maxHp = 18 + this.wave * 6
      const speed = 55 + this.wave * 9 + Math.random() * 25

      this.enemies.push({ sprite, hp: maxHp, maxHp, hpBar, attackCooldown: 800 + Math.random() * 800, speed, dead: false })
    }
  }

  private doStrike() {
    if (this.strikeCooldown > 0 || this.over) return
    this.strikeCooldown = 1400

    const ring = this.add.sprite(this.player.x, this.player.y, 'strike_ring')
    ring.setAlpha(0.85).setTint(0xef4444).setDepth(7)
    this.tweens.add({
      targets: ring,
      scaleX: 2.2,
      scaleY: 2.2,
      alpha: 0,
      duration: 380,
      ease: 'Power2',
      onComplete: () => ring.destroy(),
    })

    const strikeR = 80
    this.enemies.forEach((e) => {
      if (e.dead || !e.sprite.active) return
      if (Phaser.Math.Distance.Between(this.player.x, this.player.y, e.sprite.x, e.sprite.y) <= strikeR) {
        this.damageEnemy(e, 12 + Math.floor(Math.random() * 12))
      }
    })

    this.setCooldownVisual(this.strikeBtn, 1400)
  }

  private doDash() {
    if (this.dashCooldown > 0 || this.over) return
    this.dashCooldown = 2000
    this.isDashing = true
    this.dashTimer = 220
    this.isInvincible = true
    this.invincibleTimer = 240

    const body = this.player.body as Phaser.Physics.Arcade.Body
    const vx = body.velocity.x || 1
    const vy = body.velocity.y
    const len = Math.sqrt(vx * vx + vy * vy) || 1
    body.setVelocity((vx / len) * 520, (vy / len) * 520)

    this.player.setAlpha(0.45)
    this.setCooldownVisual(this.dashBtn, 2000)
  }

  private doJump() {
    if (this.jumpCooldown > 0 || this.over) return
    this.jumpCooldown = 900
    this.isInvincible = true
    this.invincibleTimer = 450

    this.tweens.add({
      targets: this.player,
      scaleX: 1.35,
      scaleY: 1.35,
      duration: 140,
      yoyo: true,
      ease: 'Power2',
    })

    this.setCooldownVisual(this.jumpBtn, 900)
  }

  private setCooldownVisual(btn: Phaser.GameObjects.Text, ms: number) {
    btn.setAlpha(0.35)
    this.time.delayedCall(ms, () => { if (btn.active) btn.setAlpha(1) })
  }

  private damageEnemy(e: Enemy, dmg: number) {
    if (e.dead) return
    e.hp = Math.max(0, e.hp - dmg)

    this.tweens.add({ targets: e.sprite, alpha: 0.15, duration: 55, yoyo: true })

    if (e.hp <= 0) {
      e.dead = true
      this.kills++

      const px = e.sprite.x
      const py = e.sprite.y
      e.hpBar.destroy()
      e.sprite.destroy()

      const burst = this.add.graphics()
      burst.fillStyle(0xef4444, 0.7)
      burst.fillCircle(px, py, 7)
      this.tweens.add({ targets: burst, alpha: 0, scaleX: 3, scaleY: 3, duration: 380, onComplete: () => burst.destroy() })

      this.redrawIntegrityBar()

      const alive = this.enemies.filter((en) => !en.dead)
      if (alive.length === 0) {
        this.time.delayedCall(1400, () => this.startNextWave())
      }
    }
  }

  private hurtPlayer(dmg: number) {
    if (this.isInvincible || this.over) return
    this.playerHp = Math.max(0, this.playerHp - dmg)
    this.redrawIntegrityBar()

    this.cameras.main.shake(80, 0.006)
    this.player.setTint(0xff2222)
    this.time.delayedCall(110, () => {
      if (!this.over) this.player.setTint(this.playerTintHex)
    })

    if (this.playerHp <= 0) this.endGame()
  }

  update(_time: number, delta: number) {
    if (this.over) return

    this.dashCooldown   = Math.max(0, this.dashCooldown - delta)
    this.strikeCooldown = Math.max(0, this.strikeCooldown - delta)
    this.jumpCooldown   = Math.max(0, this.jumpCooldown - delta)

    if (this.isDashing) {
      this.dashTimer -= delta
      if (this.dashTimer <= 0) {
        this.isDashing = false
        this.player.setAlpha(1)
      }
    }

    if (this.isInvincible) {
      this.invincibleTimer -= delta
      if (this.invincibleTimer <= 0) this.isInvincible = false
    }

    if (!this.isDashing) {
      const speed = 200
      let vx = 0
      let vy = 0

      if (this.cursors.left.isDown  || this.aKey.isDown) vx -= speed
      if (this.cursors.right.isDown || this.dKey.isDown) vx += speed
      if (this.cursors.up.isDown    || this.wKey.isDown) vy -= speed
      if (this.cursors.down.isDown  || this.sKey.isDown) vy += speed

      if (vx !== 0 && vy !== 0) { vx *= 0.707; vy *= 0.707 }
      ;(this.player.body as Phaser.Physics.Arcade.Body).setVelocity(vx, vy)
    }

    this.enemies.forEach((e) => {
      if (e.dead || !e.sprite.active) {
        e.hpBar.clear()
        return
      }

      const body = e.sprite.body as Phaser.Physics.Arcade.Body
      const angle = Phaser.Math.Angle.Between(e.sprite.x, e.sprite.y, this.player.x, this.player.y)
      body.setVelocity(Math.cos(angle) * e.speed, Math.sin(angle) * e.speed)

      e.attackCooldown -= delta
      const dist = Phaser.Math.Distance.Between(e.sprite.x, e.sprite.y, this.player.x, this.player.y)

      if (e.attackCooldown <= 0 && dist < 28) {
        e.attackCooldown = 1000 + Math.random() * 500
        this.hurtPlayer(4 + Math.floor(Math.random() * 6))
      }

      // HP bar above sprite
      const bw = 26
      const bh = 4
      const bx = e.sprite.x - bw / 2
      const by = e.sprite.y - 22
      e.hpBar.clear()
      e.hpBar.fillStyle(0x1a1a2e)
      e.hpBar.fillRect(bx, by, bw, bh)
      e.hpBar.fillStyle(e.hp / e.maxHp > 0.5 ? 0x22c55e : 0xef4444)
      e.hpBar.fillRect(bx, by, bw * (e.hp / e.maxHp), bh)
    })
  }

  private endGame() {
    this.over = true
    ;(this.player.body as Phaser.Physics.Arcade.Body).setVelocity(0, 0)

    const { width, height } = this.cameras.main

    this.add.rectangle(width / 2, height / 2, width, height, 0x000000, 0.72).setDepth(30)

    this.add
      .text(width / 2, height * 0.36, 'INTEGRITY LOST', {
        fontFamily: 'monospace',
        fontSize: '30px',
        color: '#ef4444',
        letterSpacing: 5,
      })
      .setOrigin(0.5)
      .setDepth(31)

    this.add
      .text(width / 2, height * 0.48, `Wave ${this.wave}  ·  ${this.kills} Kills`, {
        fontFamily: 'monospace',
        fontSize: '15px',
        color: '#94a3b8',
      })
      .setOrigin(0.5)
      .setDepth(31)

    this.add
      .text(width / 2, height * 0.6, '[ TRY AGAIN ]', {
        fontFamily: 'monospace',
        fontSize: '16px',
        color: '#e2e8f0',
        backgroundColor: '#7c2020',
        padding: { x: 20, y: 10 },
      })
      .setOrigin(0.5)
      .setDepth(31)
      .setInteractive({ useHandCursor: true })
      .on('pointerdown', () => this.scene.restart())

    this.add
      .text(width / 2, height * 0.72, '[ MODES ]', {
        fontFamily: 'monospace',
        fontSize: '14px',
        color: '#6366f1',
        backgroundColor: '#1a1a2e',
        padding: { x: 16, y: 8 },
      })
      .setOrigin(0.5)
      .setDepth(31)
      .setInteractive({ useHandCursor: true })
      .on('pointerdown', () => this.scene.start('ModeSelectorScene'))
  }
}
