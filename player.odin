package main

import rl "vendor:raylib"

Player :: struct {
    pos: [2]f32,
    texture: rl.Texture2D,
    speed: f32,
}