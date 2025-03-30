const text = scene.add.text(
    x + (facingRight ? -1 : 1)*30,
    this.y + 16,
    String(i),
    { fontSize: "10pt", fontFace: "Serif", fontWSize: 18, fontFamily: 'KOMIKAX', }
).setDepth(Depth.COMBAT_UI)

