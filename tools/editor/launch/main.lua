package.path = "/engine/?.lua"
require "bootstrap"
import_package "ant.window".start {
    window_size = "720x450",
    feature = {
        "ant.render|render",
        "ant.animation",
        "ant.pipeline",
        "ant.imgui",
        "launch",
    },
}
