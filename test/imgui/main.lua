package.path = "/engine/?.lua"
require "bootstrap"
import_package "ant.window".start {
    feature = {
        "imgui",
        "ant.render",
        "ant.animation",
        "ant.imgui",
        "ant.pipeline",
    },
}
