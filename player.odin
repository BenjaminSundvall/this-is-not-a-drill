package main

import rl "vendor:raylib"
import b2 "vendor:box2d"

Player :: struct {
    id: b2.BodyId,
    texture: rl.Texture2D,
    speed: f32,
}
