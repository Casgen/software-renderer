package renderer

import "core:math/linalg"
import "core:math"
import "../constants"
import "core:fmt"

@private default_up_vec :: linalg.Vector3f32{0, 1, 0}

Camera_States :: enum {
    Move_Fwd = 0,
    Move_Backwards = 1,
    Move_Left = 2,
    Move_Right = 3,
    Move_Up = 4,
    Move_Down = 5,
}

Camera :: struct {
    model_matrix: linalg.Matrix4x4f32,
    proj_matrix: linalg.Matrix4x4f32,
    view_matrix: linalg.Matrix4x4f32,
    eye_pos, fwd_vec, up_vec, side_vec: linalg.Vector3f32,
    states: bit_set[Camera_States],
    move_speed: f32,
    pan_sensitivity: f32,
    // Azimuth = horizontal, yaw | Zenith = vertical, pitch
    azimuth, zenith: f32,
}

// TODO: The default up vector can make bugs, when the forward and up vector
// have the same direction.

camera_create :: proc (
    pos, look_at: linalg.Vector3f32,
    width, height: u32
) -> Camera {
    camera: Camera
    camera.proj_matrix = linalg.matrix4_perspective_f32(45.0,
        f32(width) / f32(height), 0.0001, 100.0)

    camera.view_matrix = linalg.matrix4_look_at_f32(pos, look_at, default_up_vec)
    camera.model_matrix = linalg.MATRIX4F32_IDENTITY

    camera.eye_pos = pos
    camera.fwd_vec = linalg.normalize(look_at - pos)
    camera.up_vec = default_up_vec
    camera.side_vec = linalg.cross(default_up_vec, camera.fwd_vec)

    camera.states = {}
    camera.move_speed = 0.25
    camera.pan_sensitivity = 0.01

    camera.zenith = math.asin(camera.fwd_vec.y)
    camera.azimuth = math.atan2(camera.fwd_vec.x, camera.fwd_vec.z)

    return camera
}


// TODO: Check in the Compiler explorer if the odin compiler pre-computes
// the sines and cosines or not.
@(private)
recalculate_view_matrix :: proc(camera: ^Camera) {
    camera.fwd_vec = linalg.Vector3f32{
        math.sin(camera.azimuth) * math.cos(camera.zenith),
        math.sin(camera.zenith),
        math.cos(camera.azimuth) * math.cos(camera.zenith),
    }

    // TODO: Could this be more optimized? Try to create a perpendicular up
    // vector to the forward vector by defining a plane wth forward vector
    // and default_up_vec and based on that calculate the real up vector.
    // Try if it's even going to be even faster though.
    camera.up_vec = linalg.Vector3f32{ 
        math.sin(camera.azimuth) * math.cos(camera.zenith + constants.HALF_PI),
        math.sin(camera.zenith + constants.HALF_PI),
        math.cos(camera.azimuth) * math.cos(camera.zenith + constants.HALF_PI),
    }

    camera.side_vec = linalg.cross(camera.up_vec, camera.fwd_vec)
    camera.view_matrix = linalg.matrix4_look_at_f32(camera.eye_pos,
        camera.eye_pos + camera.fwd_vec, camera.up_vec) 
}

camera_yaw :: #force_inline proc(camera: ^Camera, step: f32) {
    camera.azimuth = math.mod(camera.azimuth + step * camera.pan_sensitivity,
        2 * math.PI)

    recalculate_view_matrix(camera)
}

// FIXME: the `camera.zenith - step` fix is probably a bad hack. Investigate
// the root cause of why the pitch is inverted.
camera_pitch :: #force_inline proc(camera: ^Camera, step: f32) {
    camera.zenith = math.clamp(camera.zenith - step * camera.pan_sensitivity,
        -constants.HALF_PI, constants.HALF_PI)

    recalculate_view_matrix(camera)
}

camera_set_move_forward :: #force_inline proc(camera: ^Camera, state: bool) {
    if state {
        camera.states += {Camera_States.Move_Fwd}
    } else {
        camera.states -= {Camera_States.Move_Fwd}
    }
}

camera_set_move_backwards :: #force_inline proc(camera: ^Camera, state: bool) {
    if state {
        camera.states += {Camera_States.Move_Backwards}
    } else {
        camera.states -= {Camera_States.Move_Backwards}
    }
}

camera_set_move_left :: #force_inline proc(camera: ^Camera, state: bool) {
    if state {
        camera.states += {Camera_States.Move_Left}
    } else {
        camera.states -= {Camera_States.Move_Left}
    }
}

camera_set_move_right :: #force_inline proc(camera: ^Camera, state: bool) {
    if state {
        camera.states += {Camera_States.Move_Right}
    } else {
        camera.states -= {Camera_States.Move_Right}
    }
}

camera_update :: proc(camera: ^Camera, delta_time: f32) {
    // Camera has no states set -> not moving. Just return early
    if card(camera.states) == 0 do return

    move_direction :=
        f32(u32(Camera_States.Move_Fwd in camera.states)) * camera.fwd_vec
    move_direction +=
        f32(u32(Camera_States.Move_Backwards in camera.states)) * -camera.fwd_vec

    move_direction +=
        f32(u32(Camera_States.Move_Left in camera.states)) * camera.side_vec
    move_direction +=
        f32(u32(Camera_States.Move_Right in camera.states)) * -camera.side_vec

    move_direction = linalg.normalize(move_direction)
    step := delta_time * camera.move_speed
    move_direction *= step

    fmt.println(move_direction)

    set_position(camera, move_direction + camera.eye_pos)
}

camera_set_resolution :: proc(camera: ^Camera, width, height: u32) {
    camera.proj_matrix = linalg.matrix4_perspective_f32(45.0,
        f32(width) / f32(height), 0.0001, 100.0)
}

@private
camera_get_side_vec :: #force_inline proc(camera: ^Camera) -> linalg.Vector3f32 {
    return linalg.Vector3f32{
        camera.view_matrix[0][0],
        camera.view_matrix[0][1],
        camera.view_matrix[0][2],
    }
}

@private
set_position :: proc(camera: ^Camera, new_pos: linalg.Vector3f32) {
    // TODO: make the calculation better. We are wasting creating and calculating
    // a new matrix when we could potentially just reuse the current view matrix
    // and set the translation in there
    camera.eye_pos = new_pos
    look_at := new_pos + camera.fwd_vec
    camera.view_matrix =
        linalg.matrix4_look_at_f32(new_pos, look_at, camera.up_vec)
}

