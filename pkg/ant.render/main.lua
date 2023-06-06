require "render_system.bind_bgfx_math_adapter"	--for bind bgfx api to math adapter

return {
	viewidmgr   = require "viewid_mgr",
	fbmgr       = require "framebuffer_mgr",
    declmgr     = require "vertexdecl_mgr",
    sampler     = require "sampler",
    queuemgr    = require "queue_mgr",
}
