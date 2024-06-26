#pragma once

#include <cstddef>
#include <map>
#include <unordered_map>
#include <string>
#include <vector>

struct ImDrawList;
struct ImRect;
namespace ImSequencer
{
   struct clip_range {
       clip_range(std::string_view nv, int s, int e, const std::vector<bool>& event_flags)
           : name{ nv }
           , start{ s }
           , end{ e }
           , event_flags{ event_flags }
       {}
       std::string name;
       int start;
       int end;
       std::vector<bool> event_flags;
   };
   struct anim_detail {
       float duration{ 0.0f };
       float current_time{ 0.0f };
       bool is_playing{ false };
       float speed{ 1.0f };
       std::vector<bool> event_flags;
       bool expand{ false };
   };
   extern bool new_anim;
   extern std::unordered_map<std::string, anim_detail> anim_info;

   void Sequencer(bool& pause, int& current_frame, int& selected_entry, int& move_type, int& range_index, int& move_delta);

}
