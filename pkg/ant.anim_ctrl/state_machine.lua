local ecs = ...
local world = ecs.world
local w = world.w

local playback = ecs.require "ant.animation|playback"

local iani = {}

local function get_first_playing_animation(e)
	for name, status in pairs(e.animation.status) do
		if status.weight > 0 then
			return name
		end
	end
end

function iani.play(eid, anim_state)
	local e <close> = world:entity(eid, "animation:in animation_changed?out")
	if not anim_state.weight then
		-- exclusive play
		for _, status in pairs(e.animation.status) do
			status.weight = 0
			status.play = false
			e.animation_changed = true
		end
	end
	local name = anim_state.name
	playback.set_play(e, name, true)
	if anim_state.forwards then
		playback.set_speed(e, name, -1 * (anim_state.speed or 1.0))
	else
		playback.set_speed(e, name, anim_state.speed or 1.0)
	end
	playback.set_loop(e, name, anim_state.loop)
end

function iani.set_time(eid, time, anim_name)
	local e <close> = world:entity(eid, "animation:in")
	local status = e.animation.status[anim_name or get_first_playing_animation(e)]
	local duration = status.handle:duration()
	local ratio = time / duration
	if status.ratio ~= ratio then
		w:extend(e, "animation_changed?out")
		status.ratio = ratio
		e.animation_changed = true
	end
end

function iani.get_time(eid, anim_name)
	local e <close> = world:entity(eid, "animation:in")
	local status = e.animation.status[anim_name or get_first_playing_animation(e)]
	local duration = status.handle:duration()
	return status.ratio * duration
end

function iani.set_speed(eid, speed, anim_name)
	local e <close> = world:entity(eid, "animation:in")
	local name = anim_name or get_first_playing_animation(e)
	if name then
		playback.set_speed(e, name, speed)
	end
end

function iani.set_loop(eid, loop, anim_name)
	local e <close> = world:entity(eid, "animation:in")
	local name = anim_name or get_first_playing_animation(e)
	if name then
		playback.set_loop(e, name, loop)
	end
end

function iani.pause(eid, pause, anim_name)
	local e <close> = world:entity(eid, "animation:in")
	local name = anim_name or get_first_playing_animation(e)
	if name then
		playback.set_play(e, name, not pause)
	end
end

function iani.is_playing(eid, anim_name)
	local e <close> = world:entity(eid, "animation:in")
	local status = e.animation.status[anim_name]
	if status then
		return status.play
	end
end

return iani
