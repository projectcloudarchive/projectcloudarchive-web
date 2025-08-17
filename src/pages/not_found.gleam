import lustre/attribute as a
import lustre/element.{type Element}
import lustre/element/html

pub fn view_not_found() -> Element(msg) {
  html.div(
    [
      a.class(
        "bg-[#212121] h-screen w-full flex flex-col justify-center items-center text-white",
      ),
    ],
    [
      html.h2([a.class("text-2xl font-semibold")], [html.text("Page Not Found")]),
      html.p([a.class("font-md")], [
        html.text(
          "Something went wrong! The page that you are looking for is not accessible!",
        ),
      ]),
    ],
  )
}
