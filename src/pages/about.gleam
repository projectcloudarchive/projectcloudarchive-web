import lustre/attribute as a
import lustre/element.{text}
import lustre/element/html

pub fn view() {
  html.div([a.class("bg-[#212121] h-screen w-full")], [])
}
