export class Avatar {
    constructor(
        scene: Phaser.Scene,
        public actorId,
        public readonly posIndex: number,
        private data: AvatarData,
        public animationId = CharacterAnimation.IDLE,
        public skillName = SkillName.NONE,
        public effectName = Effect.NONE,
        public hidden = false,
        public showFrames = false
    ) {
    }
}
