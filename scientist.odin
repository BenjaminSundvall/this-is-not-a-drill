package main

import rl "vendor:raylib"
import b2 "vendor:box2d"
import "core:fmt"

PATH_FOLLOW_THRESHOLD :: 0.5

Scientist :: struct {
    id: b2.BodyId,
    texture: rl.Texture2D,
    speed: f32,
    path_progress: int,
    path: [dynamic]([2]f32),
}

follow_path :: proc(scientist: ^Scientist) {
    if scientist.path_progress < len(scientist.path) {
        cur_pos: [2]f32 = b2.Body_GetPosition(scientist.id)
        tgt_pos: [2]f32 = scientist.path[scientist.path_progress]

        if b2.Distance(tgt_pos, cur_pos) < PATH_FOLLOW_THRESHOLD {
            if scientist.path_progress + 1 < len(scientist.path) {
                scientist.path_progress += 1
            }
        } else {
            b2.Body_ApplyForceToCenter(scientist.id, b2.Normalize(tgt_pos - cur_pos) * 200.0, true)
        }
    }
}

import "core:math"

get_tile_type :: proc(pos: [2]int) -> Tile {
    return gs.level.grid[pos.x][pos.y - 1]
}

is_walkable :: proc(pos: [2]int) -> bool {
    grid_width := len(gs.level.grid)
    grid_height := len(gs.level.grid[0])
    if pos.x < 0 || pos.x >= grid_width || pos.y <= 0 || pos.y >= grid_height {
        return false
    }

    tile_type := get_tile_type(pos)
    return tile_type == .FLOOR
}

snap :: proc(pos: [2]f32) -> [2]int {
    return {int(pos.x), int(pos.y)}
}

Node :: struct {
    pos:  [2]int,
    g:    int,        // cost from start
    h:    int,        // heuristic
    f:    int,        // g + h
    parent: ^Node,
}

get_neighbors :: proc(pos: [2]int) -> [4][2]int {
    neighbors: [4][2]int = {
        pos + {1, 0},
        pos - {1, 0},
        pos + {0, 1},
        pos - {0, 1},
    }
    fmt.println(">>>Neighbors of", pos, "are:", neighbors)
    return neighbors
}

manhattan :: proc(a, b: [2]int) -> int {
    dx := math.abs(a.x - b.x)
    dy := math.abs(a.y - b.y)
    return dx + dy
}

reconstruct_path :: proc(node: ^Node) -> [dynamic][2]f32 {
    path: [dynamic][2]f32

    for n := node; n != nil; n = n.parent {
        tile_center_pos: [2]f32 = {f32(n.pos.x), f32(n.pos.y)} + {0.5, 0.5}
        fmt.println("Storing", tile_center_pos, "(walkable)" if is_walkable(snap(tile_center_pos)) else "(not walkable)")
        append(&path, tile_center_pos)
    }

    fmt.println("Reversing")
    // reverse
    for i := 0; i < len(path)/2; i += 1 {
        path[i], path[len(path)-1-i] =
            path[len(path)-1-i], path[i]
    }

    return path
}

path_to :: proc(scientist: ^Scientist, tgt_pos: [2]f32) {

    start_tile: [2]int = snap(b2.Body_GetPosition(scientist.id))
    tgt_tile: [2]int = snap(tgt_pos)

    fmt.println("Start:", start_tile)
    fmt.println("Target:", tgt_tile)
    fmt.println("Heuristic:", manhattan(start_tile, tgt_tile))

    // Early exit
    if !is_walkable(tgt_tile) do return

    open: [dynamic]^Node
    closed: map[[2]int]bool

    start_node: ^Node = new(Node)
    start_node.pos = start_tile
    start_node.g = 0
    start_node.h = manhattan(start_tile, tgt_tile)
    start_node.f = manhattan(start_tile, tgt_tile)
    start_node.parent = nil


    append(&open, start_node)

    for len(open) > 0 {
        // Find node with lowest f
        best_i := 0
        for i in 1..<len(open) {
            if open[i].f < open[best_i].f {
                best_i = i
            }
        }

        current := open[best_i]
        open[best_i] = open[len(open)-1]
        pop(&open)

        fmt.println("Entering", current.pos)


        if current.pos == tgt_tile {
            delete(scientist.path)
            scientist.path = reconstruct_path(current)
            scientist.path_progress = 0
            fmt.println("Path constructed!")
            return
        }

        closed[current.pos] = true

        neighbors := get_neighbors(current.pos)
        fmt.println("Neighbors of", current.pos, "are:", neighbors)
        for n_pos in neighbors {
            fmt.println("Checking", n_pos, "( parent", current.pos, ")")

            if closed[n_pos] do continue

            if !is_walkable(n_pos) do continue


            node: ^Node = new(Node)
            node.pos = n_pos
            node.g = current.g + 1
            node.h = manhattan(n_pos, tgt_tile)
            node.f = current.g + 1 + manhattan(n_pos, tgt_tile)
            node.parent = current

            fmt.println("Added neighbor", n_pos, "with parent", current.pos)


            append(&open, node)
        }
    }

    fmt.println("No path found :(")
    scientist.path = nil
}
