local imgui     = require "imgui"
local utils     = require "common.utils"
local math3d    = require "math3d"
local uiproperty    = require "widget.uiproperty"
local BaseView = require "widget.view_class".BaseView
local CameraView = require "widget.view_class".CameraView
local hierarchy = require "hierarchy_edit"
local world
local iom
local camera_mgr

function CameraView:_init()
    BaseView._init(self)
    local property = {}
    property[#property + 1] = uiproperty.Int({label = "Target"}, {
        getter = function() return self:on_get_target() end,
        setter = function(value) self:on_set_target(value) end
    })
    property[#property + 1] = uiproperty.Float({label = "Dist"}, {
        getter = function() return self:on_get_dist() end,
        setter = function(value) self:on_set_dist(value) end
    })
    property[#property + 1] = uiproperty.Float({label = "Fov"}, {
        getter = function() return self:on_get_fov() end,
        setter = function(value) self:on_set_fov(value) end
    })
    property[#property + 1] = uiproperty.Float({label = "Near"}, {
        getter = function() return self:on_get_near() end,
        setter = function(value) self:on_set_near(value) end
    })
    property[#property + 1] = uiproperty.Float({label = "Far"}, {
        getter = function() return self:on_get_far() end,
        setter = function(value) self:on_set_far(value) end
    })
    self.camera_property    = property
    self.addframe           = uiproperty.Button({label = "AddFrame"}, {
        click = function() self:on_add_frame() end
    })
    self.deleteframe        = uiproperty.Button({label = "DeleteFrame"}, {
        click = function() self:on_delete_frame() end
    })
    self.play               = uiproperty.Button({label = "Play"}, {
        click = function() self:on_play() end
    })
    self.current_frame      = 1
    self.duration           = {}
    self.main_camera_ui     = {false}
end

function CameraView:set_model(eid)
    self.frames = camera_mgr.get_recorder_frames(eid)
    if not BaseView.set_model(self, eid) then return false end
    local template = hierarchy:get_template(self.eid)
    if template.template.action and template.template.action.bind_camera and template.template.action.bind_camera.which == "main_queue" then
        self.main_camera_ui[1] = true
    else
        self.main_camera_ui[1] = false
    end
    self.current_frame = 1
    for i, v in ipairs(self.frames) do
        self.duration[i] = {self.frames[i].duration}
    end
    self:update()
    return true
end

function CameraView:on_set_position(...)
    BaseView.on_set_position(self, ...)
    if #self.frames > 0 then
        self.frames[self.current_frame].position = math3d.ref(math3d.vector(...))
    end
    camera_mgr.update_frustrum(self.eid)
end

function CameraView:on_get_position()
    if #self.frames > 0 then
        return math3d.totable(self.frames[self.current_frame].position)
    else 
        return math3d.totable(iom.get_position(self.eid))
    end
end

function CameraView:on_set_rotate(...)
    BaseView.on_set_rotate(self, ...)
    if #self.frames > 0 then
        self.frames[self.current_frame].rotation = math3d.ref(math3d.quaternion(...))
    end
    camera_mgr.update_frustrum(self.eid)
end

function CameraView:on_get_rotate()
    local rad
    if #self.frames > 0 then
        rad = math3d.totable(math3d.quat2euler(self.frames[self.current_frame].rotation))
        return { math.deg(rad[1]), math.deg(rad[2]), math.deg(rad[3]) }
    else
        local r = iom.get_rotation(self.eid)
        rad = math3d.totable(math3d.quat2euler(r))
    end
    return { math.deg(rad[1]), math.deg(rad[2]), math.deg(rad[3]) }
end

function CameraView:on_set_scale()

end

function CameraView:on_get_scale()
    return {1, 1, 1}
end

function CameraView:on_set_target(value)
    camera_mgr.set_target(self.eid, value)
end
function CameraView:on_get_target()
    return camera_mgr.camera_list[self.eid].target
end
function CameraView:on_set_dist(value)
    camera_mgr.set_dist_to_target(self.eid, value)
end
function CameraView:on_get_dist()
    return camera_mgr.camera_list[self.eid].dist_to_target
end

function CameraView:on_set_fov(value)
    if #self.frames > 0 then
        self.frames[self.current_frame].fov = value
    end
    local template = hierarchy:get_template(self.eid)
    template.template.data.frustum.fov = value
    icamera.set_frustum_fov(self.eid, value)
    camera_mgr.update_frustrum(self.eid)
end
function CameraView:on_get_fov()
    if #self.frames > 0 then
        return self.frames[self.current_frame].fov
    else
        local e = icamera.find_camera(self.eid)
        return e.frustum.fov
    end
end
function CameraView:on_set_near(value)
    if #self.frames > 0 then
        self.frames[self.current_frame].n = value
    end
    local template = hierarchy:get_template(self.eid)
    template.template.data.frustum.n = value
    icamera.set_frustum_near(self.eid, value)
    camera_mgr.update_frustrum(self.eid)
end
function CameraView:on_get_near()
    if #self.frames > 0 then
        return self.frames[self.current_frame].n or 1
    else
        local e = icamera.find_camera(self.eid)
        return e.frustum.n or 1
    end
end
function CameraView:on_set_far(value)
    if #self.frames > 0 then
        self.frames[self.current_frame].f = value
    end
    local template = hierarchy:get_template(self.eid)
    template.template.data.frustum.f = value
    icamera.set_frustum_far(self.eid, value)
    camera_mgr.update_frustrum(self.eid)
end
function CameraView:on_get_far()
    if #self.frames > 0 then
        return self.frames[self.current_frame].f or 100
    else
        local e = icamera.find_camera(self.eid)
        return e.frustum.f
    end
end
function CameraView:update()
    BaseView.update(self)
    for _, pro in ipairs(self.camera_property) do
        pro:update() 
    end
end

function CameraView:on_play()
    camera_mgr.play_recorder(self.eid)
end

function CameraView:on_add_frame()
    local new_idx = self.current_frame + 1
    camera_mgr.add_recorder_frame(self.eid, new_idx)
    self.current_frame = new_idx
    local frames = camera_mgr.get_recorder_frames(self.eid)
    self.duration[new_idx] = {frames[new_idx].duration}
    self:update()
end

function CameraView:on_delete_frame()
    camera_mgr.delete_recorder_frame(self.eid, self.current_frame)
    table.remove(self.duration, self.current_frame)
    local frames = camera_mgr.get_recorder_frames(self.eid)
    if self.current_frame > #frames then
        self.current_frame = #frames
        self:update()
    end
end

function CameraView:show()
    BaseView.show(self)
    if imgui.widget.TreeNode("Camera", imgui.flags.TreeNode { "DefaultOpen" }) then
        imgui.widget.PropertyLabel("MainCamera")
        if imgui.widget.Checkbox("##MainCamera", self.main_camera_ui) then
            local template = hierarchy:get_template(self.eid)
            if self.main_camera_ui[1] then
                if not template.template.action then
                    template.template.action = {}
                end
                template.template.action.bind_camera = {which = "main_queue"}
            else
                if template.template.action and template.template.action.bind_camera then
                    template.template.action.bind_camera = nil
                end
            end
        end

        for _, pro in ipairs(self.camera_property) do
            pro:show() 
        end
        --imgui.cursor.Separator()
        -- self.addframe:show()
        -- if #self.frames > 1 then
        --     imgui.cursor.SameLine()
        --     self.deleteframe:show()
        --     imgui.cursor.SameLine()
        --     self.play:show()
        -- end
        
        -- if #self.frames > 0 then
        --     imgui.cursor.Separator()
        --     if imgui.table.Begin("CameraViewtable", 2, imgui.flags.Table {'Resizable', 'ScrollY'}) then
        --         imgui.table.SetupColumn("FrameIndex", imgui.flags.TableColumn {'NoSort', 'WidthFixed', 'NoResize'}, -1, 0)
        --         imgui.table.SetupColumn("Duration", imgui.flags.TableColumn {'NoSort', 'WidthStretch'}, -1, 1)
        --         imgui.table.HeadersRow()
        --         for i, v in ipairs(self.frames) do
        --             --imgui.table.NextRow()
        --             imgui.table.NextColumn()
        --             --imgui.table.SetColumnIndex(0)
        --             if imgui.widget.Selectable(i, self.current_frame == i) then
        --                 self.current_frame = i
        --                 camera_mgr.set_frame(self.eid, i)
        --                 self:update()
        --             end
        --             imgui.table.NextColumn()
        --             --imgui.table.SetColumnIndex(1)
        --             if imgui.widget.DragFloat("##"..i, self.duration[i]) then
        --                 self.frames[i].duration = self.duration[i][1]
        --             end
        --         end
        --         imgui.table.End()
        --     end
        -- end
        
        imgui.widget.TreePop()
    end
end


function CameraView:has_scale()
    return false
end

return function(w)
    world       = w
    icamera     = world:interface "ant.camera|camera"
    iom         = world:interface "ant.objcontroller|obj_motion"
    camera_mgr  = require "camera_manager"(world)
    require "widget.base_view"(world)
    return CameraView
end